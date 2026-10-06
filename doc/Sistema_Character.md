# Sistema de personajes (Object Events)

Documentación del sistema de entidades caminables del overworld: player, NPC, movimiento en grid, animación, rutas y su relación con la colisión del mapa.

Estilo de referencia: juegos Pokémon de Game Boy Advance (casilla 16×16, un paso por vez, giro antes de caminar, bump al chocar).

---

## 1. Propósito

Representar personajes sobre el mapa con:

- una **posición lógica** en el grid,
- un **aspecto** (sprite OW + sombra),
- **movimiento** discreto por casillas,
- **comportamiento** (input del jugador o IA / rutas),
- integración con **colisión entre entidades** y **colisión/altura del mapa**.

El diseño evita un único script “dios”. Cada pieza tiene un contrato acotado; si falla la animación o la ruta, el movimiento base y el mapa siguen siendo razonables.

---

## 2. Jerarquía de una entidad

Tanto `player.tscn` como `npc.tscn` siguen la misma idea:

```text
Player o Npc                          ← root Node2D (posición lógica, grupo, Y-Sort)
├── Character                         ← visual (sprite OW + sombra)
├── CharacterAnimatedController       ← nombres de animación según dirección
├── CharacterController               ← grid, velocidad, bump, altura visual
├── CharacterState                    ← IDLE / WALK (y RUN reservado)
├── PlayerController | NpcController  ← origen de la dirección o del comportamiento
└── MoveRouteController               ← solo NPC (rutas)
```

### Por qué el root se mueve y no solo el sprite

El contenedor de entidades del mapa (`EventObject`) usa **Y-Sort**. Godot ordena por la posición Y del **Node2D hijo directo** de ese contenedor.

Si solo se interpolara el nodo `Character` y el root se quedara fijo, el orden de dibujo entre player y NPC no cambiaría al cruzarse. Por eso `CharacterController` desplaza `entity_root` (el parent) y deja `Character` en posición local `(0, 0)`, con el offset fino en el propio sprite.

---

## 3. Capa de datos

### CharacterBase

Resource base compartido: identificador, nombre, tipo de OW (`EventObjects.Obj_Event`), tipo de sombra, etc.

### PlayerData

Extiende `CharacterBase`. Campos de velocidad:

| Campo | Unidad habitual | Uso |
|-------|-----------------|-----|
| `walk` | tiles por segundo | Caminar |
| `running` | tiles por segundo | Reservado para carrera |

Conversión al controller: `move_speed_px = walk * 16` (porque `TILE_SIZE = 16`).

### NPCData

Extiende `CharacterBase`:

| Campo | Uso |
|-------|-----|
| `behavior` | Enum: NONE, LOOK_AROUND, WANDER, PATROL, FOLLOW, … |
| `move_route` | Resource `MoveRoute` (lista de comandos + loop) |
| `walk` | Velocidad en tiles/s (mismo criterio que el player) |

Los datos se asignan en el inspector sobre el nodo `Character` (`data: CharacterBase`). El código de comportamiento hace `as PlayerData` / `as NPCData` cuando necesita campos específicos.

---

## 4. Character — representación

Responsabilidad: **solo** aspecto.

1. A partir de `data.ow` carga la textura del sheet (rejilla típica 3 columnas × 4 direcciones).
2. Genera o actualiza los frames de cada animación (`Idle_Down`, `First_Step_Left`, etc.).
3. Alinea el `AnimatedSprite2D` a la casilla lógica de 16×16: el personaje queda centrado en X y apoyado en el borde inferior de la celda, aunque el frame sea 32×32 u otro tamaño.
4. Asigna la textura de sombra según `shadow_type`. La **posición de la sombra es libre** en la escena; el código de alineado del cuerpo no la sobrescribe.

En editor (`@tool` + `_process`), si cambian `ow` o la sombra en el resource, se refresca el visual sin entrar en play mode.

No conoce input, grid ni colisión.

---

## 5. CharacterAnimatedController

Traduce dirección (`Vector2`) a nombre de animación y la reproduce en el sprite del `Character`.

- Paso / idle según lo pida el controller o los states.
- No decide *cuándo* caminar; solo *qué* clip mostrar.

---

## 6. CharacterController — movimiento en grid

Núcleo del overworld para cualquier entidad caminable.

### Constantes relevantes

| Constante | Valor típico | Significado |
|-----------|--------------|-------------|
| `TILE_SIZE` | 16 | Tamaño de casilla |
| `MOVE_SPEED` | 64 | Default px/s (= 4 tiles/s) |
| `HOLD_THRESHOLD` | ~0.12 s | Tiempo mirando una dirección nueva antes del primer paso |
| `BUMP_COOLDOWN` | ~0.25 s | Evita spam de bump |
| `Z_GROUND` / `Z_ELEVATED` | 0 / 3 | Capas de render respecto a tiles “techo” del mapa |

### Estado de movimiento

- `current_position` — casilla lógica ocupada (en movimiento sigue siendo el origen hasta completar el paso).
- `target_position` — destino del paso actual; mientras `moving`, esa casilla queda **reservada** para otras entidades.
- `direction` / `last_direction` — vector cardinal actual y último válido.
- `move_progress` — 0…1 de la interpolación del paso.
- `external_move` — el paso lo pidió un sistema externo (ruta NPC), no el hold de input del player.
- `move_speed` — px/s efectivos (`set_move_speed`).

### Estado de altura (mapa)

- `height_level` — nivel lógico (custom data `nivel_altura` del mapa).
- `elevated` — encima de un puente (`no_block`); afecta colisión de tiles y `z_index`.

La lógica de *qué* casillas son válidas vive en `MapCollisionSystem` / `CollisionFacade`. El controller solo pregunta y aplica el resultado.

### Flujo de un paso

```text
1. Resolver dirección (input, ruta o request_move)
2. Si la dirección cambió respecto a last_direction:
	 - mirar (animación de paso/idle en esa dirección)
	 - esperar HOLD_THRESHOLD
3. start_move:
	 - target = posición + dirección * 16
	 - CollisionFacade.is_blocked? → bump y abortar
	 - preview_render_state (capa visual; ver doc de colisión)
	 - moving = true, interpolar root
4. Al llegar (progress >= 1):
	 - snap al target
	 - apply_cell_state (altura / elevated)
	 - movement_finished
	 - si hay dirección mantenida (player), encadenar otro start_move
```

### Bump

Si el destino está ocupado o el tile lo impide:

1. Se reproduce una animación de “intento de paso” (a veces con `speed_scale` ajustado).
2. En el player, se puede reproducir un SE de choque.
3. `bump_cooldown` evita repetir el efecto cada frame.
4. `CharacterStates` **no** debe forzar idle encima del bump mientras `is_bumping()` sea true (problema real que se corrigió: el idle pisaba el bump y se veía a velocidad incorrecta).

### Señales

- `movement_finished` — paso completado (rutas NPC, posibles triggers futuros).
- `movement_blocked` — intento fallido (rutas pueden reintentar o saltar comando según diseño).

### API útil

| Método | Uso |
|--------|-----|
| `set_direction(v)` | Input del player |
| `request_move(v)` | Un paso pedido por NPC/ruta (`external_move`) |
| `look_direction(v)` | Solo girar sin desplazar |
| `get_character_position()` | Posición mundo del root |
| `set_move_speed(px_s)` | Velocidad efectiva |
| `update_render_layer()` | `z_index` según `elevated` |
| `is_bumping()` | Para que States no pisen la animación |

---

## 7. CharacterStates

Máquina mínima orientada a **animación**, no a física.

Estados: `IDLE`, `WALK`, `RUN` (carrera aún no cableada del todo).

- Si `controller.moving` → WALK.
- Si deja de moverse → IDLE, salvo que haya bump activo.
- No llama a `start_move`; solo reacciona al controller.

Separarlo evita que el script de movimiento mezcle “estoy interpolando un paso” con “qué clip de idle toca”.

---

## 8. Player

### PlayerController

Lee el Input Map (`Up` / `Down` / `Left` / `Right`, y más adelante `Run`) y escribe la dirección en el `CharacterController`. Prioridad típica: una sola dirección cardinal (no diagonales).

### player.gd

Cada frame de física:

1. Actualizar input.
2. Procesar states.
3. Procesar movimiento.

En `_ready` (o al aplicar data): `set_move_speed(data.walk * TILE_SIZE)`.

El player pertenece al grupo `"Player"` y, en runtime, cuelga de `EventObject` del mapa activo (lo hace `MapManager`, no este script).

---

## 9. NPC

### NpcController

Según `NPCData.behavior`:

| Behavior | Idea |
|----------|------|
| NONE | Quieto (salvo ruta explícita) |
| LOOK_AROUND | Gira de vez en cuando |
| WANDER | Pasos aleatorios con pausa |
| PATROL | Usa `move_route` en bucle |
| FOLLOW | Intenta acercarse al player a cierta distancia |

Temporizadores internos evitan spamear `request_move` cada frame.

### MoveRoute y MoveCommand

`MoveRoute`: lista de `MoveCommand` + flag `loop`.

Tipos de comando (entre otros):

- Movimiento: UP/DOWN/LEFT/RIGHT, RANDOM, FORWARD, BACKWARD, TOWARD_PLAYER, AWAY_FROM_PLAYER.
- Giro: TURN_*.
- `WAIT` con `parameter` en segundos.

### MoveRouteController

1. `setup(character_controller)` conecta señales de finished/blocked.
2. `start_route` / `stop_route`.
3. Ejecuta un comando; los movimientos esperan `movement_finished`.
4. Si el movimiento está bloqueado, reintenta o avanza según la política implementada (evitar el fallo clásico de “deslizar” a una casilla lateral y dar por hecho el comando).

Las rutas **no** deben recursar en el mismo stack frame hasta vaciar la lista: conviene `call_deferred` al pasar al siguiente comando cuando haga falta, para no tumbar el frame o el editor.

---

## 10. Colisión entre entidades

`EntityCollisionSystem` (estático):

- Recorre grupos `Player` y `Npc`.
- Una casilla está ocupada si coincide con `current_position` de otro controller **o** con `target_position` mientras ese controller `moving`.

Así dos entidades no pueden reservar el mismo destino en el mismo frame. El mapa (paredes, altura) se consulta aparte vía `CollisionFacade`.

Detalle de implementación: al comprobar ocupación se usa la posición del **controller**, no un `global_position` suelto del sprite, para mantener una sola fuente de verdad.

---

## 11. Relación con el mapa

El sistema de personajes **no** pinta tiles ni conoce el TileSet. Solo:

1. Pregunta a `CollisionFacade.is_blocked(self, target)`.
2. Llama `preview_render_state` / `apply_cell_state` en los momentos del paso.
3. Ajusta `z_index` del root cuando `elevated` cambia (puentes respecto a capas altas del tileset).

La documentación de metatiles, conectores y puentes está en `Sistema_Mapa_y_Colision.md`.

---

## 12. Problemas que aparecieron y cómo se resolvieron

Estos casos quedaron documentados porque vuelven a salir en cualquier clon del enfoque GBA:

### 12.1 Orden de dibujo player/NPC incorrecto

**Síntoma:** el sprite se movía, pero quien estaba “más abajo” en pantalla no quedaba delante.  
**Causa:** se interpolaba el hijo visual; el root no cambiaba de Y.  
**Solución:** mover el root; visual en local cero + offset en el sprite.

### 12.2 Bump “a cámara rápida”

**Síntoma:** al chocar, un frame de walk y vuelta a idle demasiado pronto.  
**Causa:** `CharacterStates.idle()` reaplicaba idle cada frame y pisaba el bump.  
**Solución:** `is_bumping()` y no forzar idle durante el cooldown.

### 12.3 NPC se “deslizaba” al bloquearse

**Síntoma:** ante colisión, la ruta no esperaba: parecía corregir hacia otra casilla.  
**Causa:** política de reintento / siguiente comando demasiado agresiva.  
**Solución:** reintentar el mismo destino o quedarse hasta liberar la casilla; no inventar un paso lateral como éxito del comando.

### 12.4 Destino libre para dos entidades a la vez

**Síntoma:** dos personajes entraban a la misma celda.  
**Causa:** solo se miraba la posición actual, no el destino en curso.  
**Solución:** reservar `target_position` mientras `moving`.

### 12.5 Velocidad ignoraba el resource

**Síntoma:** `walk` en el inspector no hacía nada.  
**Causa:** el controller usaba solo la constante `MOVE_SPEED`.  
**Solución:** `move_speed` variable + `set_move_speed` desde player/npc al cargar data.

### 12.6 Altura y puentes

**Síntoma:** conector y `no_block` “no hacían nada”, o el tile del puente tapaba al subir/bajar a destiempo.  
**Causa:** reglas solo en destino, sin mirar el origen; `z_index` solo al final del paso.  
**Solución:** `can_enter` con origen/destino y estado `elevated`; `preview_render_state` al iniciar el paso; no bajar de capa hasta **terminar** al salir del puente.

### 12.7 NPC sin nivel al spawnear

**Síntoma:** NPCs bloqueados en tiles de altura ≠ 0.  
**Causa:** `set_active_map` corría *después* del `_ready` de los NPC, o no se llamaba `init_entity_state`.  
**Solución:** registrar la capa de colisión **antes** de `add_child` del mapa; inicializar altura de player y NPCs en el manager.

---

## 13. Contratos al extender el sistema

| Si quieres… | Extiende… | Evita… |
|-------------|-----------|--------|
| Nuevo tipo de paso (salto, dash) | CharacterController + estados | Meter input en Character |
| Nueva IA de NPC | NpcController o un behavior strategy | Duplicar lerp del grid |
| Nuevo comando de ruta | MoveCommand.Type + match en MoveRouteController | Lógica de grid en el resource |
| Nuevo bloqueo de casilla | Custom data + MapCollisionSystem | Ifs de tiles dentro del controller |
| Nueva capa visual (surf, bici) | States + animated controller + flags en data | Reescribir EntityCollisionSystem |

---

## 14. Archivos principales

```text
scripts/overworld/object_events/
  character/
	character_base.gd
	character.gd
	character_controller.gd
	character_states.gd
	character_animated_controller.gd
  player/
	player.gd
	player_data.gd
	player_controller.gd
  npc/
	npc.gd
	npc_data.gd
	npc_controller.gd
  movement/
	entity_collision_system.gd
	move_route.gd
	move_command.gd
	move_route_controller.gd
  object_event.gd          # catálogo OW / utilidades de event objects
```

Escenas de referencia: `scenes/overworld/player/player.tscn`, `scenes/overworld/npc/npc.tscn`.

---

## 15. Resumen en una frase

El personaje es un **root en el grid** con un **visual intercambiable**, un **controller de pasos**, una **capa fina de estados de animación**, y —en NPC— **comportamiento y rutas** que solo piden direcciones; la legalidad del paso la dictan la fachada de colisión y el mapa activo.

---

*Alineado al código de poke-dot-studio (Godot 4.7). Complementa `ARQUITECTURA.md` y `Sistema_Mapa_y_Colision.md`.*

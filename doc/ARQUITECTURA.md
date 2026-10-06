# Arquitectura de PokeDot Studio

Documento formal del estado del motor de overworld.  
Godot 4.7 · GDScript tipado estricto · Grid 16×16 estilo Pokémon GBA.

---

## 1. Objetivos de diseño

1. **Overworld jugable** comparable en feel a los juegos GBA (casillas, giro, caminar, bump, NPCs, mapas).
2. **Separación de responsabilidades:** cada sistema tiene un contrato pequeño; un fallo no obliga a reescribir el resto.
3. **Player fuera de las escenas de mapa:** una sola instancia de sesión; los mapas se instancian y el player se reparenta.
4. **Datos en Resources** (`PlayerData`, `NPCData`, `MapAttributes`, `MoveRoute`) editables en inspector.
5. **Colisión de mapa por metatiles** (capa `Behaviour/Collision` + custom data), no por física continua.

---

## 2. Capas del sistema

```text
┌─────────────────────────────────────────────────────────┐
│  Sesión                                                  │
│  GameSession · GameStartData                             │
└───────────────────────────┬─────────────────────────────┘
							│
┌───────────────────────────▼─────────────────────────────┐
│  Mapas                                                   │
│  MapManager · Map · MapAttributes · MapSection           │
│  MapMusicController · MapBorderController                │
└───────────────────────────┬─────────────────────────────┘
							│
┌───────────────────────────▼─────────────────────────────┐
│  Entidades                                               │
│  Player / NPC · Character · Controllers · States         │
│  MoveRoute / MoveRouteController                         │
└───────────────────────────┬─────────────────────────────┘
							│
┌───────────────────────────▼─────────────────────────────┐
│  Colisión e altura                                       │
│  CollisionFacade · EntityCollisionSystem                 │
│  MapCollisionSystem · CollisionTileData                  │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Sesión de juego

### 3.1 GameSession

- Nodo raíz típico de la escena de boot.
- Posee `@export var start_data: GameStartData`.
- Referencias a `Player` y `MapManager`.
- En `_ready`: solicita el primer mapa; no implementa carga de `.tscn`.

### 3.2 GameStartData (Resource)

| Campo | Uso |
|-------|-----|
| `start_map_id` | `MapSection.MapID` del mapa inicial |
| `start_position` | Celda `Vector2i` de aparición |
| `player_data` | Opcional; si el Player ya trae data en escena, puede omitirse |

### 3.3 Ciclo de vida del Player

- Existe en la escena de boot (o se instancia una vez).
- **No** se guarda dentro de los `.tscn` de mapa.
- `MapManager` lo reparenta a `EventObject` del mapa activo y fija `position = cell * 16`.

---

## 4. Sistema de mapas

### 4.1 MapSection

- Enum `MapID` y diccionario `MAP_SCENES: MapID → ruta .tscn`.
- Enum `RegionID` para metadatos regionales.
- Única tabla de resolución id → escena (el manager no hardcodea rutas).

### 4.2 MapAttributes (Resource)

Datos del mapa: `map_id`, `region_id`, `map_name`, `map_music`, `map_size`, flags (`is_indoor`, `allow_fly`, etc.).

### 4.3 Map (Node2D, `@tool`)

- Expone `attributes`.
- En editor dibuja el rectángulo de `map_size`.
- Notifica a hijos con `on_map_attributes_ready` (música, bordes).
- **No** implementa movimiento, colisión ni carga de otros mapas.

### 4.4 Estructura de escena (`map_base`)

```text
Map_Attributes (Map)
├── Tileset
│   ├── Tile0 … Tile2     (suelo / decoración baja)
│   ├── Tile3             z_index = 2  (capas que tapan al pasar debajo)
│   └── Tile4             z_index = 3
├── Behaviour
│   ├── Collision         TileMapLayer de metatiles
│   └── Borde             patrón 2×2 de borde infinito
├── EventObject           z_index = 1, y_sort_enabled
├── Trigger
├── MapMusicController
└── MapBorderController
```

### 4.5 MapManager

Responsabilidades:

1. Resolver ruta (`MapSection`).
2. Instanciar / liberar el mapa.
3. Registrar `MapCollisionSystem.set_active_map` **antes** de `add_child`.
4. Reparentar player a `EventObject` y posicionar en celda.
5. `init_entity_state` del player y de NPCs del mapa.
6. Emitir `map_changed` / `map_unloaded`.

No conoce combate, diálogos ni inventario.

### 4.6 MapMusicController

- Escucha attributes del mapa.
- Llama a `MusicManager.reproducir_mapa(map_music)`.

### 4.7 MapBorderController

- En runtime rellena celdas fuera de `map_size` con un patrón **2×2** tomado de `Behaviour/Borde`.
- Solo actualiza el área visible + margen respecto a la cámara.
- Dentro de `map_size` borra celdas de borde para no tapar el mapa jugable.

---

## 5. Sistema de personajes

### 5.1 Datos

| Clase | Extiende | Contenido relevante |
|-------|----------|---------------------|
| `CharacterBase` | Resource | id, ow, name, shadow, etc. |
| `PlayerData` | CharacterBase | `walk`, `running` (tiles/s) |
| `NPCData` | CharacterBase | `behavior`, `move_route`, `walk` |

### 5.2 Character (visual)

- Carga sheet OW (rejilla 3×4 de frames), arma animaciones.
- Alinea el sprite a la casilla 16×16 (pies en el borde inferior de la celda).
- Sombra: posición libre (no forzada por el alineado del cuerpo).

### 5.3 CharacterController

- Mueve el **root** de la entidad (`Player`/`Npc`) en pasos de 16 px.
- Velocidad: `move_speed` (px/s), configurable con `set_move_speed(walk * 16)`.
- Giro con hold threshold antes del primer paso.
- Bump: animación + sonido (player) + cooldown.
- Estado de altura: `height_level`, `elevated`.
- Render: `z_index` `Z_GROUND` (0) o `Z_ELEVATED` (3) según puente.
- Al iniciar paso: `preview_render_state` (subir capa pronto; **no** bajar al salir hasta el final).
- Al terminar paso: `apply_cell_state`.

### 5.4 CharacterStates / CharacterAnimatedController

- Estados de animación (idle / walk) sin mezclarse con la física del grid.
- Respeto a `is_bumping()` para no pisar el bump con idle.

### 5.5 Player

- `PlayerController` lee input y llama `set_direction`.
- Loop: input → state → `process_movement`.

### 5.6 NPC

- `NpcController` según `Behavior` (NONE, LOOK_AROUND, WANDER, PATROL, FOLLOW…).
- `MoveRouteController` ejecuta `MoveRoute` / `MoveCommand` (pasos, mirar, esperar, hacia/lejos del player).
- Reintentos ante bloqueo sin “deslizar” a casillas laterales de forma incorrecta (diseño de rutas).

### 5.7 Orden de dibujo entre entidades

- `EventObject.y_sort_enabled = true`.
- Se ordena por la **Y del root**, no del hijo `Character`.

---

## 6. Colisión

### 6.1 EntityCollisionSystem

- Consulta grupos `Player` y `Npc`.
- Ocupación: casilla actual (`current_position`) y **destino reservado** si `moving`.
- Evita que dos entidades entren a la misma celda a la vez.

### 6.2 CollisionTileData

Lee del TileSet de `Behaviour/Collision`:

| Custom data | Tipo | Significado |
|-------------|------|-------------|
| `bloqueo` | bool | Pared / no se entra |
| `cambiar_nivel_altura` | bool | Conector entre niveles |
| `nivel_altura` | int | Nivel lógico de la casilla |
| `no_block` | bool | Casilla de puente (paso bajo/alto) |

### 6.3 MapCollisionSystem

- Mantiene referencia al `TileMapLayer` del mapa activo.
- `can_enter(height, elevated, from, to)` — reglas de paso.
- `apply_cell_state` — actualiza `height_level` / `elevated` al llegar.
- `preview_render_state` — ajusta capa visual al **inicio** del paso (excepto bajar del puente).
- `init_entity_state` — spawn.

#### Reglas resumidas

```text
bloqueo                     → no
desde conector              → sí (transición de nivel)
elevated + destino          → solo no_block, conector o mismo nivel
no_block                    → sí (arriba o abajo según estado)
cambiar_nivel_altura        → sí
suelo                       → sí si height_level == nivel_altura
vacío                       → sí si height_level == 0 (convención)
```

#### Puente y render

- **Por debajo:** `elevated = false`, `z_index = 0` → tiles de `Tile3` (z=2) tapan al personaje.
- **Por encima:** `elevated = true`, `z_index = 3` → personaje sobre el puente.
- Al **salir** del puente, el `z_index` bajo solo se aplica al **completar** el paso.

### 6.4 CollisionFacade

Única puerta para el controller:

```text
is_blocked(controller, target) =
  EntityCollisionSystem.ocupada OR NOT MapCollisionSystem.can_enter(...)
```

---

## 7. Audio

- Autoload `MusicManager`.
- IDs en `SFXGame` / `MapMusicID`.
- El mapa dispara reproducción vía `MapMusicController` según `MapAttributes.map_music`.
- SE de bump del player configurable en el controller.

---

## 8. Herramientas de editor

### Map Creator (`addons/map_creator`)

- Menú para crear un `.tscn` de mapa desde `map_base`.
- Puede actualizar registros de mapas (según implementación actual del plugin).

### Map Editor (`addons/map_editor`)

- Intercepta pintura fuera de `map_size`.
- Utilidades de edición 2D en el viewport del editor.

---

## 9. Lo que deliberadamente aún no está

- Warps / conexiones entre mapas por trigger
- Diálogo e interacción (botón A)
- Encuentros en hierba, surf, ledges unidireccionales como tipo aparte
- Menú, inventario, combate, save/load completo
- Multiplayer

La base de overworld (movimiento, entidades, mapas, altura, puentes) está lista para apoyar esas capas.

---

## 10. Criterios de extensión

Al añadir un sistema nuevo:

1. ¿Tiene ciclo de vida distinto al movimiento? → script/nodo propio.
2. ¿Solo necesita datos del mapa? → leer `MapAttributes` o custom data, no inflar `Map.gd`.
3. ¿Bloquea casillas? → extender custom data + `MapCollisionSystem`, no el controller.
4. ¿Es solo visual de mapa? → controller hijo del Map, no el manager.

---

*Documento alineado al código en `main` de poke-dot-studio (Godot 4.7).*

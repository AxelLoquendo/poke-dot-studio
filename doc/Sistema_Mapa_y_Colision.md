# Sistema de mapa, colisión y altura

## 1. Propósito

Definir qué casillas son transitables, a qué **nivel de altura** pertenece cada entidad, y cómo se resuelven **conectores** y **puentes** (paso inferior / superior), integrados con el orden de dibujo del tileset.

---

## 2. Capa Behaviour/Collision

`TileMapLayer` bajo `Behaviour/Collision`, con TileSet `data/resources/overworld/tileset/collision/collision.tres`.

No usa `StaticBody2D` por tile: cada celda es un **metatile** con custom data.

### Custom data

| Nombre | Tipo | Descripción |
|--------|------|-------------|
| `bloqueo` | bool | Impide entrar |
| `cambiar_nivel_altura` | bool | Conector; al salir permite adoptar otro nivel |
| `nivel_altura` | int | Nivel lógico (0, 1, 2…) |
| `no_block` | bool | Casilla de puente; no bloquea por diferencia de nivel como el suelo normal |

### Guía visual del atlas

- Flechas → conector (`cambiar_nivel_altura`).
- Números 0–9 → niveles de altura.
- Variantes en rojo → suelen llevar `bloqueo`.
- Letras (A–E) / tiles altos con `no_block` → puente.

---

## 3. Estado en la entidad

```text
height_level: int   # nivel lógico actual
elevated: bool      # true = encima del puente / camino elevado
```

- Spawn: `MapCollisionSystem.init_entity_state` según la celda bajo los pies.
- Player: MapManager tras colocar.
- NPC: MapManager recorre grupo `Npc` bajo el mapa (y/o deferred en el NPC).

---

## 4. Pipeline de un paso

```text
start_move
  1. target = posición + dirección * 16
  2. CollisionFacade.is_blocked?
		- EntityCollisionSystem (otras entidades + destino reservado)
		- MapCollisionSystem.can_enter(height, elevated, from, to)
  3. Si bloqueado → bump
  4. Si ok → preview_render_state (capa visual)
  5. Interpolación del root

fin del paso
  6. apply_cell_state(from, to)  → height_level, elevated, z_index
  7. movement_finished
```

---

## 5. Reglas can_enter (resumen)

1. Destino con `bloqueo` → no.
2. Casilla **origen** con `cambiar_nivel_altura` → sí (transición).
3. Si `elevated`:
   - `no_block` o conector → sí;
   - suelo solo si `nivel_altura == height_level`;
   - vacío solo si `height_level == 0`.
4. Si no elevated:
   - conector / `no_block` → sí;
   - suelo si mismo nivel;
   - vacío si nivel 0.

---

## 6. apply_cell_state y preview

| Destino | apply | preview (inicio del paso) |
|---------|-------|---------------------------|
| Conector | `elevated = false` | igual |
| `no_block` desde conector o elevated | `elevated = true` (+ nivel del puente si aplica) | subir z **ya** |
| `no_block` desde abajo | `elevated = false` | z bajo ya |
| Suelo | `height_level = nivel`, `elevated = false` | — |
| **Salir** de elevated a no-elevated | en apply: bajar z | preview **no** baja z (evita que el puente tape a mitad de paso) |

`update_render_layer` en `CharacterController`:

- `elevated` → `entity_root.z_index = 3`
- si no → `z_index = 0`

Así se coordina con `Tile3` (z=2) del mapa.

---

## 7. EntityCollisionSystem

- Independiente del mapa.
- Misma unidad: posiciones mundo alineadas a 16 px.
- Reserva el destino mientras `moving == true`.

---

## 8. Integración MapManager

```text
instantiate mapa
set_active_map(mapa)      # antes de add_child
add_child(mapa)
place player
init_entity_state(player)
init NPCs del mapa
```

Unload: `clear_active_map` antes de liberar el nodo.

---

## 9. Extensiones futuras

- Ledges (solo bajar en una dirección) → nuevo custom data + rama en `can_enter`.
- Agua / surf → tipo de terreno + requisito de estado del player.
- Warps en `Trigger` o custom data de celda → otro sistema que escuche `movement_finished` + celda.

No mezclar esas reglas dentro de `CharacterController`.

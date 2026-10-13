# Mapa, cluster, colisión y eventos de casilla

## 1. Piezas

| Clase | Papel |
|---|---|
| `Map` | Escena de un mapa: tiles, `MapAttributes`, borde, eventos |
| `MapAttributes` | Metadatos exportados (id, nombre, música, clima, conexiones, location_*) |
| `MapFactory` | Cluster continuo: actual + vecinos |
| `MapManager` | Un solo mapa (indoor / API alternativa) |
| `MapCollisionSystem` | Capas de colisión activas del cluster |
| `CollisionFacade` | Un paso → `MoveStepResult` |
| `MapEvent` | Evento de casilla (WARP / COORD / BG) |
| `MapEventResolver` | Evalúa eventos al pisar o al pulsar A |

## 2. Cluster

`MapFactory.load_cluster(map_id, cell, player)`:

1. Descarga el cluster anterior (el player se reparenta fuera antes).
2. Instancia el mapa central y los vecinos según `MapConnectionEntry`.
3. Registra colisión de todo el cluster.
4. Coloca al player en la celda (espacio del mapa) y emite `cluster_loaded`.

`update_current_from_player` detecta si la posición mundial cayó en un vecino; si sí, promueve ese mapa a actual (`current_changed`) y refresca vecinos. `reparent_player_keep_global` conserva la posición mundial.

## 3. Warp

Dos entradas equivalentes en efecto de carga:

1. **Script** `warp MAP_ID x y [dir]` → `ScriptCmdWarp` → fade → `load_cluster` → orientación opcional → fade in. El runner se reparenta a `MapFactory` para no morir con el NPC.
2. **MapEvent WARP** → `MapEventResolver` → mismo `FadeScreen` + `load_cluster`, llegada por `dest_warp_id` o `dest_tile_fallback`.

## 4. Eventos de casilla (`MapEvent`)

`Marker2D` con snap 16×16 en editor. Grupo `map_events`.

| Kind | Cuándo | Qué |
|---|---|---|
| `WARP` | Pisar | Transfer al `dest_map` / `dest_warp_id` |
| `COORD` | Pisar | Script si `condition_ok()` |
| `BG` | A frente a la casilla | Script (cartel); `HIDDEN_ITEM` marca flag si aplica |

Condición: `condition_flag` vacío = siempre; si no, compara `ScriptExecutionContext.global_flags` con `expected_value`.

Cableado:

- Tras cada paso del player: `MapEventResolver.try_step(player, map_factory)`.
- Al pulsar A: `try_interact` antes de buscar NPC.

## 5. Consulta de un paso

`CollisionFacade.resolve_move(controller, direction)` → `MoveStepResult` (`blocked`, `target_world`, `hop`, `behavior_world`).

Orden: entidad y después tile. `EntityCollisionSystem` ocupa casillas de actores. `MapCollisionSystem` lee custom data del tile (`no_block`, altura, puente).

## 6. Comportamientos de tile

`TileBehaviorReader` + `TileBehaviorSystem` + handlers. Hoy el handler concreto es `LedgeBehavior` (dirección del ledge, hop, animación vía contexto del paso).

## 7. Borde

`MapBorderController` pinta el patrón infinito fuera de `map_size` y de los rectángulos conectados, según la cámara.

## 8. Preview de editor

Con `Engine.is_editor_hint()`, los vecinos de preview se instancian sin runtime (sin música, clima, eventos activos).

## 9. Y-sort

Player y NPC cuelgan de `EventObject`. El `z_index` de puente es ortogonal al orden Y.

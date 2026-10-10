# Mapas y colisión

## 1. Identidad de un mapa

`MapSection.MapID` es el enumerado de mapas. `MapSection.MAP_SCENES` traduce cada id a una escena `scenes/overworld/map/<nombre>/<nombre>.tscn`.

`MapAttributes` (resource en el nodo `Map`) guarda id, `map_size` en celdas, lista de `MapConnectionEntry`, música y clima. Una conexión tiene lado, `edge_offset` y `target_map`. `MapConnectionResolver` convierte eso en origen mundial del vecino y en el rectángulo que ocupa. El borde infinito usa ese rectángulo para no pintar encima de un mapa que sí existe.

## 2. Cluster

`MapFactory.load_cluster(map_id, celda, player)`:

1. Descarga instancias previas, reparentando al jugador fuera de ellas.
2. Instancia el mapa y lo marca actual (`set_as_current(true)`), lo que enciende música, clima y borde.
3. Coloca al jugador en la celda, en coordenadas del mapa, y lo reparenta a `EventObject`.
4. `MapCollisionSystem.set_active_map` e `init_entity_state` para el jugador y para cada NPC del mapa.
5. Instancia los vecinos declarados, desactivados como actuales, en la posición que devuelve el resolver.

`update_current_from_player` traduce la posición mundial a un id con los rectángulos de las conexiones. Si el id cambió, ese vecino pasa a actual y `_refrescar_vecinos` descarga los que ya no tocan y carga los nuevos.

Promover no teletransporta. `_reparent_player_keep_global` conserva la posición mundial. El jugador ya está, visualmente, dentro del vecino.

## 3. Mapa único

`MapManager.change_map` existe para interiores: saca al jugador, libera el mapa, limpia la colisión activa, instancia uno nuevo y lo coloca en una celda. No carga vecinos. Un comando de script `warp` todavía no llama a este método.

## 4. Consulta de un paso

`CollisionFacade.resolve_move(controller, direction)` devuelve un `MoveStepResult`:

- `blocked`
- `target_world`
- `hop`
- `behavior_world` (celda cuyo comportamiento se evalúa; en un ledge puede no ser el destino)

El orden dentro de la fachada es entidad y después tile. `EntityCollisionSystem` ocupa la casilla destino si otro actor del grupo ya está ahí. `MapCollisionSystem` lee el `TileData` del mapa activo.

`CollisionTileData` saca de custom data del tile:

- `no_block`: se puede entrar.
- altura y puente, usados por `init_entity_state` / `apply_cell_state` para `height_level`, `elevated` y el `z_index` (0 en suelo, 3 elevado).

`preview_render_state` anticipa esa capa al empezar el paso, para que el sprite no cambie de orden a mitad del lerp.

## 5. Comportamientos de tile

`TileBehaviorReader` identifica el comportamiento. `TileBehaviorSystem` busca un `TileBehaviorHandler`. Hoy el handler concreto es `LedgeBehavior`: solo deja entrar si la dirección del paso coincide con la del ledge, marca hop y la animación de salto la dispara el propio contexto (`jump_animation_played`), que el controlador traduce a `ledge_hop` antes de emitir `step_started`.

Añadir un comportamiento nuevo es un handler. No se edita `start_move`.

## 6. Borde

`MapBorderController` corre en `_process` solo con el mapa actual. Calcula el rectángulo visible de la cámara en espacio local, lo expande `MARGEN_CELDAS` y, si el rango cambió, pinta.

`_pintar_celda` borra la celda si cae dentro de `map_size` o de un rectángulo conectado. Si no, copia el tile del patrón 2×2. Decidir el rango y escribir el `TileMapLayer` son funciones distintas.

## 7. Preview de editor

Con `Engine.is_editor_hint()`, `Map._refresh_connection_previews` instancia los vecinos, les pone meta `META_PREVIEW` y `META_SKIP_PREVIEW`, les apaga música, borde, clima y eventos (`_strip_preview_runtime`) y los tiñe. `_spawn_preview` hace un vecino. No corre en el juego.

## 8. Y-sort

Player y NPC cuelgan de `EventObject`, que ordena por Y. El `z_index` de puente es ortogonal a ese orden: altura de capa, no orden dentro de la capa.

# Personaje, movimiento y NPC

## 1. Piezas

Cada actor (jugador o NPC) es un `Node2D` con los mismos hijos base:

| Nodo | Clase | Papel |
|---|---|---|
| `Character` | `Character` | Sprite y `CharacterBase` (`walk`, nombre, id) |
| `CharacterController` | `CharacterController` | Grilla, lerp, lock |
| `CharacterAnimatedController` | `CharacterAnimatedController` | Frames y sonido de salto |
| `CharacterState` | `CharacterStates` | IDLE / WALK / RUN / LOCKED |
| `PlayerController` o `NpcController` | — | De dónde sale la dirección |
| `MoveRouteController` | NPC (y player si un script lo crea) | Cola de `MoveCommand` |

`PlayerData` y `NPCData` extienden `CharacterBase`. La velocidad de paso es `walk * 16` px/s. Si `walk` es 0, se conserva el default del controlador.

## 2. Ciclo de un paso

`process_movement` sale de inmediato si el estado es `LOCKED`.

Si no está bloqueado:

1. Si `moving`, avanza el lerp; hop de ledge multiplica velocidad y desplaza Y. Al terminar emite `movement_finished`.
2. Umbral de giro (`HOLD_THRESHOLD`) antes de empezar el paso en una dirección nueva.
3. Si no, lee `input_direction` y puede llamar a `start_move`.

`start_move` pide `CollisionFacade.resolve_move`. Bloqueado → bump. Libre → `step_started(direction, hop)`.

`halt_for_interaction` fija o revierte la posición según el progreso del paso, para hablar sin dejar al actor a medias.

## 3. Jugador

`Player._physics_process` ignora input de movimiento si `_script_locked` o `MessageService.is_active()`.

`_unhandled_input` con A (y sin estar moviéndose):

1. `MapEventResolver.try_interact` (BG frente al player).
2. Si no, NPC del grupo `npc` en la casilla frontal con `can_interact` / `interact`.

## 4. NPC

Al interactuar: estado `LOCKED`, pausa de comportamiento y ruta, mira al player, lanza `ScriptRunner` con el `.txt` de `NPCData.script_file`.

Al terminar el script: vuelve a IDLE, `resume_behavior` y libera el runner.

Durante el script, `NpcController` no procesa wander / look around si está locked o en pausa.

## 5. Rutas y scripts de movimiento

`MoveRoute` + `MoveCommand` (`MOVE_*`, `TURN_*`, `FACE_PLAYER`, `WAIT`).

`MoveRouteController.start_route` con `loop = false` emite `route_finished` al acabar (usado por `waitmovement`).

`applymovement` / `moveplayer` construyen la ruta con `MoveRouteParser` y llaman a `start_route`. Si el player no tiene `MoveRouteController`, el comando puede crear uno y hacer `setup` con su `CharacterController`.

## 6. Estados

`CharacterStates.State`: `IDLE`, `WALK`, `RUN`, `LOCKED`. En `LOCKED` el controlador no acepta nuevos pasos.

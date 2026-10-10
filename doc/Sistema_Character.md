# Personaje, movimiento y NPC

## 1. Piezas

Cada actor (jugador o NPC) es un `Node2D` con los mismos hijos:

| Nodo | Clase | Papel |
|---|---|---|
| `Character` | `Character` | Sprite y `CharacterBase` (`walk`, nombre, id) |
| `CharacterController` | `CharacterController` | Grilla, lerp, lock |
| `CharacterAnimatedController` | `CharacterAnimatedController` | Frames y sonido de salto |
| `CharacterState` | `CharacterStates` | IDLE / WALK / RUN / LOCKED |
| `PlayerController` o `NpcController` | — | De dónde sale la dirección |
| `MoveRouteController` | solo NPC | Cola de `MoveCommand` |

`PlayerData` y `NPCData` extienden `CharacterBase`. La velocidad de paso es `walk * 16` píxeles por segundo. Si `walk` es 0, se conserva el default del controlador (64 px/s, cuatro tiles por segundo).

## 2. Ciclo de un paso

`process_movement` sale de inmediato si el estado es `LOCKED`. No completa el lerp en curso.

Si no está bloqueado:

1. Si `moving`, avanza `move_progress` según distancia y velocidad. El hop de ledge multiplica la velocidad por 1.6 y desplaza el sprite en Y con una curva. Al llegar a 1, fija el tile destino, aplica el estado de celda (`MapCollisionSystem.apply_cell_state`) y emite `movement_finished`.
2. Si está esperando el umbral de giro (`HOLD_THRESHOLD`, 0.12 s), cuenta el hold. Cambiar de dirección reinicia el hold y emite `step_started` para mostrar el primer frame hacia el lado nuevo.
3. Si no, lee `input_direction`.

`start_move` no pinta nada. Pide `CollisionFacade.resolve_move`. Si `blocked`, emite `bump_started` y `movement_blocked` y pone un cooldown de 0.25 s. Si no, guarda `target_position`, consulta `TileBehaviorSystem.on_step_start` (un ledge puede forzar `hop`) y emite `step_started(direction, hop)`.

`halt_for_interaction` devuelve si el paso cuenta como completado (`moving` y progreso ≥ 0.5). En ese caso fija la posición en `target_position`. Si no, vuelve a `initial_position`. Limpia `moving`, dirección externa y hop. Quien llama decide si avanza el índice de la ruta.

## 3. Jugador

`Player._physics_process` delega el input en `PlayerController` salvo que `_script_locked` o `MessageService.is_active()` sean verdaderos. En ese caso pone la dirección a cero y aun así llama a `process_movement`, para que un cooldown de bump pueda terminar.

`_unhandled_input` solo reacciona a A, y solo si el jugador no se está moviendo. Busca un NPC del grupo `npc` cuyo `get_tile_position` coincida con la casilla de enfrente (`last_direction * TILE_SIZE`, redondeo). Si `can_interact`, llama a `interact`.

`set_script_locked` lo usa el comando `lock` / `release` del script. No sustituye al lock del NPC.

## 4. NPC

`NpcController.process_behavior` no corre si `behavior_paused` o el estado está locked.

| `NPCData.Behavior` | Efecto |
|---|---|
| `NONE` | Quieto |
| `LOOK_AROUND` | Cada 0.8 s elige una dirección y llama a `look_direction` |
| `WANDER` | Cada 0.8 s, si no se mueve, `request_move` en una dirección aleatoria |
| `FOLLOW` | Si el jugador está a más de 32 px, un paso hacia él cada 0.2 s |
| `PATROL` | Una vez, `MoveRouteController.start_route(npc_data.move_route)` |

`request_move` marca el paso como externo. Al terminar no encadena otro por `input_direction`. La ruta, el wander y el follow dependen de eso.

## 5. Rutas

`MoveRoute` es una lista de `MoveCommand` con flag `loop`. El controlador recuerda `current_command` y `pending_direction`.

Tipos que piden un paso: arriba, abajo, izquierda, derecha, aleatorio, adelante, atrás, hacia el jugador, lejos del jugador. Tipos que no ocupan el lerp: giros y `WAIT`.

Si el paso choca, no avanza el índice. Reintenta la misma dirección a los 0.25 s, salvo que la ruta se haya pausado. El id de corrida (`_run_id`) invalida esperas y reintentos viejos.

`pause_route` pone `executing` en falso y conserva ruta e índice. `resume_route` vuelve a ejecutar el comando apuntado. `complete_current_command` incrementa el índice sin ejecutar: lo usa el diálogo cuando el paso iba por encima de la mitad. `stop_route` tira la ruta. El diálogo no lo usa.

`NpcController.resume_behavior`, si el comportamiento es `PATROL` y todavía hay ruta, llama a `resume_route` y deja `patrol_started` en verdadero. Solo reinicia desde el comando 0 cuando no queda ruta.

## 6. Interacción

`can_interact` es falso si ya hay script, si el NPC está locked o si `script_file` está vacío.

`_freeze_for_script`:

1. `CharacterStates.LOCKED`.
2. `pause_behavior`.
3. `halt_for_interaction`. Si devolvió verdadero, `complete_current_command`.
4. `pause_route`.
5. `face_towards` el jugador. Con empate de ejes gana el horizontal.

`_start_runner` crea un `ScriptRunner` hijo, le pasa el NPC, el jugador y el padre (el mapa o `EventObject`) y arranca un único `ScriptCmdTextFile`.

Al emitir `script_finished`: limpia flags locales, vuelve a `IDLE` y `resume_behavior`.

## 7. Qué no hace esta capa

No elige destino de warp. No abre la caja de texto. No sabe qué dice el `.txt`. Eso es el runner y `MessageService`.

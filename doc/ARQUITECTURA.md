# Arquitectura de PokeDot Studio

Documento de diseño del motor de overworld. Godot 4.7, GDScript tipado estricto, grilla 16×16.

Describe el código de `scripts/`, no una intención futura. Si un comportamiento no aparece aquí, no está implementado.

## 1. Objetivo

PokeDot Studio ejecuta un overworld con el ritmo de los juegos de Game Boy Advance: casilla, giro, paso, choque, NPC, mapa conectado y evento de texto. El combate y la persistencia quedan fuera de este runtime a propósito, para no acoplar el mapa a un modelo de batalla que todavía no existe.

El motor tiene que poder cambiar un subsistema sin reescribir los demás. Audio, borde, colisión, mensaje y movimiento se hablan por señales, autoloads o valores de retorno. No se leen entre sí por dentro.

## 2. Regla de una función

Cada función hace una sola de estas tres cosas:

1. Calcular y devolver un valor (`MoveStepResult`, ancho de texto, siguiente comando).
2. Aplicar un valor ya decidido a nodos, sin volver a decidir.
3. Orquestar: llamar a las otras dos, sin matemática ni construcción de UI dentro.

Si una función resuelve una colisión y además llama a `play_animation`, está mal partida. El controlador emite `step_started`. `CharacterAnimatedController` es quien reproduce la animación y el salto.

## 3. Capas

```text
Presentación     MessageUI, WeatherRenderer, CharacterAnimatedController, FadeScreen
Servicios        MessageService, MusicManager, WeatherManager
Sesión           GameSession, MapFactory, MapManager
Reglas           CollisionFacade, MapCollisionSystem, TileBehaviorSystem,
                 ScriptRunner, MoveRouteController, NpcController
Datos            MapAttributes, NPCData, PlayerData, MoveRoute, WeatherData, .txt
```

Las reglas no instancian `Label` ni `Sprite2D`. La presentación no decide si un paso es legal.

## 4. Sesión

`GameSession` es la raíz de juego. Tiene un `GameStartData` (`start_map_id`, `start_position`, `player_data`) y un hijo `MapFactory`.

En `_ready`:

1. Crea `MessageUI` si el grupo `message_ui` está vacío. `MessageUI` se registra en el autoload `MessageService`.
2. Si hay `player_data`, lo asigna al `Character` del jugador.
3. `MapFactory.load_cluster` carga el mapa de inicio y sus vecinos.
4. Se conecta `movement_finished` del jugador a `update_current_from_player`.

No hay menú de título ni ranuras de guardado en esta escena.

## 5. Mapas

Hay dos cargadores. No son intercambiables.

`MapFactory` es el overworld continuo. Mantiene el mapa actual y los vecinos declarados en `MapAttributes.connections`. Al cruzar el borde, promueve el vecino a actual, reparenta al jugador conservando `global_position` y refresca el anillo de vecinos. Es el camino que usa `GameSession`.

`MapManager.change_map` descarga el mapa entero y carga otro. Sirve para interior y warp, cuando no hay vecinos que conservar. Hoy el arranque no lo usa.

Un `Map` expone `MapAttributes` (id, tamaño, conexiones, música, clima). Al activarse como actual dispara a sus controladores hijos:

- `MapMusicController` pide el BGM al `MusicManager`.
- `MapWeatherController` publica el clima del mapa en `WeatherManager`.
- `MapBorderController` rellena fuera del mapa con un patrón 2×2, sin pintar celdas de mapas conectados.

La colisión activa es única: `MapCollisionSystem.set_active_map`. Los vecinos existen como escenas, pero las consultas de tile van al mapa actual.

El detalle de celdas, altura y ledges está en `Sistema_Mapa_y_Colision.md`.

## 6. Personaje

`CharacterController` posee la posición de grilla, el progreso del paso y el bloqueo. No reproduce animaciones. Emite:

| Señal | Cuándo |
|---|---|
| `step_started(direction, hop)` | Empieza un paso, o un giro que anticipa el paso |
| `facing_changed(direction)` | Mira sin caminar (`look_direction`) |
| `bump_started(direction)` | El paso fue rechazado |
| `bump_ended(direction)` | Terminó el cooldown del choque |
| `movement_finished` | El lerp llegó al tile destino |
| `movement_blocked` | La fachada de colisión rechazó el paso |

`CharacterAnimatedController` se suscribe a las cuatro primeras y aplica sprites, velocidad de bump y el sonido de salto si el padre está en el grupo `Player`. El sonido de choque lo dispara el controlador solo para ese grupo, porque es feedback de input y no de sprite.

`CharacterStates` (`IDLE`, `WALK`, `RUN`, `LOCKED`) observa `moving`. En `LOCKED` el controlador no acepta otro paso y no termina el que estaba a medias: `halt_for_interaction` lo resuelve antes.

El detalle de NPC, patrulla e interacción está en `Sistema_Character.md`.

## 7. Eventos

Un NPC con `script_file` acepta la tecla A del jugador si este está quieto y mira su tile. `Npc._run_script` solo orquesta:

1. `_freeze_for_script` bloquea estado, pausa el comportamiento, corta el paso en el tile de origen o de destino según `move_progress >= 0.5`, pausa la ruta y gira hacia el jugador.
2. `_start_runner` inserta un `ScriptRunner` hijo con un `ScriptCmdTextFile`.

Al terminar, el estado vuelve a `IDLE` y `NpcController.resume_behavior` reanuda la patrulla en el comando guardado. No reinicia la ruta desde el comando 0: si lo hiciera, el tile de la conversación pasaría a ser el origen del circuito.

Flags y variables viven en `ScriptExecutionContext`. Los flags son un diccionario estático de proceso. No se escriben a disco.

El lenguaje está en `Sistema_Scripts.md`. La caja de texto está en `Sistema_Mensajes.md`.

## 8. Presentación global

`MusicManager`, `FadeScreen`, `WeatherManager` y `WeatherRenderer` son autoloads. Un mapa o un comando de script les pide un cambio. Ellos no recorren NPCs ni leen `MapAttributes` por su cuenta, salvo el renderer, que lee la intensidad publicada por el manager.

Ver `Sistema_Presentacion.md`.

## 9. Lo que este motor no hace

- No hay escena de combate ni cálculo de daño.
- No hay mochila, equipo, Pokédex ni PC.
- No hay `SaveService`. Los flags mueren con el proceso.
- `MapManager` no está cableado al arranque. Un warp de script todavía no tiene comando implementado (`warp` se advierte como no portado).
- Los comandos `applymovement`, `moveplayer`, `giveitem`, `sound`, `trainerbattle`, `checkitem`, `compare` y `savegame` se reconocen en el parser y no tienen factory.

## 10. Convenciones

- Grilla: `CharacterController.TILE_SIZE` es 16.
- Grupos: `player`, `npc`. La búsqueda de interacción y de `speaker_id` depende de ellos.
- Identidad de script: `Npc.get_script_id` devuelve `NPCData.id` o, si falta, el nombre del nodo.
- Recursos editables en inspector: `MapAttributes`, `NPCData`, `PlayerData`, `MoveRoute`, `GameStartData`.
- El código nuevo no lee `doc/` como fuente de verdad. Si el documento y el script discrepan, manda el script y se corrige el documento en el mismo cambio.

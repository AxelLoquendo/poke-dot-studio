# Arquitectura de PokeDot Studio

Documento de diseño del motor de overworld. Godot 4.7, GDScript tipado estricto, grilla 16×16.

Describe el código de `scripts/`, no una intención futura. Si un comportamiento no aparece aquí, no está implementado.

## 1. Objetivo

PokeDot Studio ejecuta un overworld con el ritmo de los juegos de Game Boy Advance: casilla, giro, paso, choque, NPC, mapa conectado, evento de casilla y script de texto. El combate, los ítems y la persistencia quedan fuera de este runtime a propósito.

El motor tiene que poder cambiar un subsistema sin reescribir los demás. Audio, borde, colisión, mensaje y movimiento se hablan por señales, autoloads o valores de retorno. No se leen entre sí por dentro.

## 2. Regla de una función

Cada función hace una sola de estas tres cosas:

1. Calcular y devolver un valor (`MoveStepResult`, ancho de texto, siguiente comando).
2. Aplicar un valor ya decidido a nodos, sin volver a decidir.
3. Orquestar: llamar a las otras dos, sin matemática ni construcción de UI dentro.

Si una función resuelve una colisión y además llama a `play_animation`, está mal partida. El controlador emite `step_started`. `CharacterAnimatedController` es quien reproduce la animación y el salto.

## 3. Capas

```text
Presentación     MessageUI, LocationSignpost, WeatherRenderer,
                 CharacterAnimatedController, FadeScreen
Servicios        MessageService, MusicManager, WeatherManager
Sesión           GameSession, MapFactory, MapManager
Reglas           CollisionFacade, MapCollisionSystem, TileBehaviorSystem,
                 ScriptRunner, MoveRouteController, NpcController,
                 MapEventResolver
Datos            MapAttributes, NPCData, PlayerData, MoveRoute,
                 WeatherData, MapEvent, scripts .txt
```

Las reglas no instancian `Label` ni `Sprite2D` de mensaje. La presentación no decide si un paso es legal.

## 4. Sesión

`GameSession` es la raíz de juego. Tiene un `GameStartData` (`start_map_id`, `start_position`, `player_data`) y un hijo `MapFactory`.

En `_ready`:

1. Crea `MessageUI` si el grupo `message_ui` está vacío. `MessageUI` se registra en el autoload `MessageService`.
2. Crea `LocationSignpost` y conecta `MapFactory.cluster_loaded` / `current_changed` a su anuncio de mapa.
3. Si hay `player_data`, lo asigna al `Character` del jugador.
4. `MapFactory.load_cluster` carga el mapa de inicio y sus vecinos.
5. Se conecta `movement_finished` del jugador a `update_current_from_player` y a `MapEventResolver.try_step`.

No hay menú de título ni ranuras de guardado en esta escena.

## 5. Mapas

Hay dos cargadores. No son intercambiables.

**`MapFactory`** es el overworld continuo. Mantiene el mapa actual y los vecinos, registra capas de colisión del cluster y reparenta al jugador. Es el camino de `load_cluster` y del comando `warp` de script.

**`MapManager`** carga un solo mapa (pensado para indoor sin vecinos). Existe en el código; el flujo de juego actual usa `MapFactory`.

`MapAttributes` describe el mapa: id, nombre, música, tamaño, clima, conexiones, `show_location_name`, `location_style`, `location_type`, flags de indoor / fly / dig.

## 6. Eventos de casilla

`MapEvent` (`Marker2D`) es un evento sin Object/NPC, hijo del mapa:

| Kind | Disparo | Efecto |
|---|---|---|
| `WARP` | Al pisar | Transfer con fade vía `MapFactory` |
| `COORD` | Al pisar | Script `.txt` si la condición de flag lo permite |
| `BG` | Al pulsar A frente a la casilla | Cartel / script (objeto oculto: solo flag por ahora) |

`MapEventResolver` concentra la evaluación. `try_step` corre al terminar un paso del jugador. `try_interact` corre al pulsar A (antes que el NPC).

Los warps se enlazan por `warp_id` ↔ `dest_warp_id` entre mapas, con `dest_tile_fallback` de respaldo.

## 7. Scripts

El formato `.txt` lo parsea `ScriptTextParser`. `ScriptCmdTextFile` convierte cada línea en un `ScriptCommand`. `ScriptRunner` ejecuta en secuencia; los comandos asíncronos ponen `context.is_waiting` y llaman `complete_async` al terminar.

El runner de un NPC es hijo del NPC. Antes de un `warp` que destruye el mapa, el comando reparenta el runner a `MapFactory` para que `release` / `end` puedan ejecutarse.

El alcance overworld del intérprete está cerrado: texto, control de flujo, flags, variables, movimiento, fade, clima, sonido y warp. No hay `giveitem`, `trainerbattle` ni `savegame` implementados (pueden figurar como desconocidos o sin factory).

## 8. Mensajes y presentación

`MessageService` es la API. `MessageUI` pinta cajas estilo Essentials (speech / choice / name). `FadeScreen` usa alpha lineal a 0.4 s. `LocationSignpost` muestra el nombre del mapa con gráficos de `assets/ui/Location/` según estilo y tipo.

## 9. Fuera de alcance

Combate, party, mochila, Pokédex, guardado en disco, menú de pausa completo, Surf / bici / HM como sistemas jugables.

## 10. Criterio al añadir código

- ¿Quién calcula y quién aplica?
- ¿La presentación puede vivir sin conocer el mapa?
- ¿El script puede vivir sin conocer el tilemap?

Si la respuesta obliga a cruzar capas, falta un valor intermedio o una señal.

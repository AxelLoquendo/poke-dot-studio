# PokeDot Studio

Motor de overworld estilo Pokémon GBA, en Godot 4.7 y GDScript con tipado estricto. Grilla de 16×16, viewport de referencia 512×384, renderer GL Compatibility.

Este repositorio es el runtime de mapa, personaje, eventos y presentación. No incluye combate, equipo, mochila, Pokédex ni guardado.

La documentación de diseño vive en [`doc/ARQUITECTURA.md`](doc/ARQUITECTURA.md). El resto de los documentos describen un subsistema cada uno y se mantienen alineados al código de `main`, no a iteraciones anteriores.

## Alcance

| Subsistema | Estado |
|---|---|
| Movimiento en grilla, animación y hop de ledge | Operativo |
| Colisión de tile, altura, puente y entidades | Operativo |
| Mapas conectados (cluster) y mapa único (indoor / warp) | Operativo |
| Borde infinito, BGM por mapa, clima | Operativo |
| NPC: wander, look around, follow, patrulla por ruta | Operativo |
| Intérprete de scripts `.txt` y mensajes con choices | Operativo |
| Fade de pantalla | Operativo |
| Combate, menús de partida, persistencia | No implementado |

## Requisitos

- Godot 4.7, renderer GL Compatibility.
- Viewport 512×384, stretch `viewport`, aspect `ignore`.
- Plugins de editor: `addons/map_creator`, `addons/map_editor`.

## Arranque

La escena principal es `scenes/overworld/game/game_start.tscn`. `GameSession` instancia `MessageUI` si no existe, aplica `PlayerData` opcional y pide a `MapFactory` el cluster del mapa indicado en `GameStartData`.

```text
GameSession
  → MessageUI
  → MapFactory.load_cluster(map_id, celda, player)
       → mapa actual + vecinos por MapConnection
       → Player reparentado a EventObject
       → MapCollisionSystem.init_entity_state
```

Cada paso del jugador llama a `MapFactory.update_current_from_player`. Si la celda cae en un vecino, ese mapa pasa a ser el actual y se recargan sus conexiones.

## Autoloads

| Nombre | Responsabilidad |
|---|---|
| `MusicManager` | BGM y efectos. No conoce mapas. |
| `FadeScreen` | Cortina a pantalla completa. |
| `WeatherManager` | Clima activo e intensidad. |
| `WeatherRenderer` | Partículas, tiles y rayos de ese clima. |
| `MessageService` | API de texto para scripts. No pinta. |

## Controles

| Acción | Teclas |
|---|---|
| Movimiento | Flechas, WASD |
| A / aceptar | Z |
| B | X |
| Select | Shift |
| Start | Enter |

## Documentación

- [`doc/ARQUITECTURA.md`](doc/ARQUITECTURA.md) — contrato del motor y reglas de diseño.
- [`doc/Sistema_Mapa_y_Colision.md`](doc/Sistema_Mapa_y_Colision.md) — mapas, cluster, tiles, altura.
- [`doc/Sistema_Character.md`](doc/Sistema_Character.md) — personaje, movimiento, NPC y rutas.
- [`doc/Sistema_Scripts.md`](doc/Sistema_Scripts.md) — formato `.txt` y runner.
- [`doc/Sistema_Mensajes.md`](doc/Sistema_Mensajes.md) — caja de texto, nombre y choices.
- [`doc/Sistema_Presentacion.md`](doc/Sistema_Presentacion.md) — audio, fade y clima.

## Criterio de cambio

Una función calcula, aplica un resultado ya calculado, u orquesta llamadas. No hace dos de esas cosas. El detalle está en la sección 2 de la arquitectura.

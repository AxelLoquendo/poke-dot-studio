# PokeDot Studio

Motor de overworld estilo Pokémon GBA, en Godot 4.7 y GDScript con tipado estricto. Grilla de 16×16, viewport de referencia 512×384, renderer GL Compatibility.

Este repositorio es el runtime de mapa, personaje, eventos de casilla, scripts y presentación. No incluye combate, equipo, mochila, Pokédex ni guardado.

La documentación de diseño vive en [`doc/ARQUITECTURA.md`](doc/ARQUITECTURA.md). El resto de los documentos describen un subsistema cada uno y se mantienen alineados al código de `main`.

## Alcance

| Subsistema | Estado |
|---|---|
| Movimiento en grilla, animación y hop de ledge | Operativo |
| Colisión de tile, altura, puente y entidades | Operativo |
| Mapas conectados (cluster) y mapa único (indoor) | Operativo |
| Borde infinito, BGM por mapa, clima | Operativo |
| NPC: wander, look around, follow, patrulla por ruta | Operativo |
| Intérprete de scripts `.txt` (overworld completo) | Operativo |
| Mensajes, choices, name box | Operativo |
| Fade de pantalla (lerp lineal PE) | Operativo |
| Warp por script y por `MapEvent` | Operativo |
| Eventos de casilla (WARP / COORD / BG) | Operativo |
| Cartel de nombre de mapa (`LocationSignpost`) | Operativo |
| Combate, menús de partida, ítems, persistencia | No implementado |

## Requisitos

- Godot 4.7, renderer GL Compatibility.
- Viewport 512×384, stretch `viewport`, aspect `ignore`.
- Plugins de editor: `addons/map_creator`, `addons/map_editor`.

## Arranque

La escena principal es `scenes/overworld/game/game_start.tscn`. `GameSession` instancia `MessageUI` y `LocationSignpost` si hace falta, aplica `PlayerData` opcional, conecta señales de mapa y pide a `MapFactory` el cluster del mapa indicado en `GameStartData`.

```text
GameSession
  → MessageUI
  → LocationSignpost
  → MapFactory.load_cluster(map_id, celda, player)
       → mapa actual + vecinos por MapConnection
       → Player reparentado a EventObject
       → MapCollisionSystem.init_entity_state
       → cluster_loaded → cartel de nombre (si aplica)
```

Cada paso del jugador llama a `MapFactory.update_current_from_player` y a `MapEventResolver.try_step` (COORD / WARP al pisar).

## Autoloads

| Nombre | Responsabilidad |
|---|---|
| `MusicManager` | BGM y efectos. No conoce mapas. |
| `FadeScreen` | Cortina a pantalla completa (alpha lineal 0.4 s). |
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
- [`doc/Sistema_Mapa_y_Colision.md`](doc/Sistema_Mapa_y_Colision.md) — mapas, cluster, tiles, altura, eventos de casilla.
- [`doc/Sistema_Character.md`](doc/Sistema_Character.md) — personaje, movimiento, NPC y rutas.
- [`doc/Sistema_Scripts.md`](doc/Sistema_Scripts.md) — formato `.txt` y runner.
- [`doc/Sistema_Mensajes.md`](doc/Sistema_Mensajes.md) — caja de texto, nombre y choices.
- [`doc/Sistema_Presentacion.md`](doc/Sistema_Presentacion.md) — audio, fade, clima y cartel de ubicación.

## Criterio de cambio

Una función calcula, aplica un resultado ya calculado, u orquesta llamadas. No hace dos de esas cosas. El detalle está en la sección 2 de la arquitectura.

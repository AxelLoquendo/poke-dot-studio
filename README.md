# PokeDot Studio

Motor de overworld estilo **Pokémon GBA** (top-down, grid 16×16), desarrollado en **Godot 4.7** con GDScript tipado estricto.

Proyecto en solitario. Sucesor conceptual de *pokedot-expansion* / *pokedot-engine*, rediseñado desde cero con separación clara de responsabilidades para evitar refactors constantes.

---

## Estado actual

| Área | Estado |
|------|--------|
| Movimiento en grid (player / NPC) | Completo |
| Animaciones OW y sombra | Completo |
| Rutas y comportamientos de NPC | Completo |
| Colisión entre entidades | Completo |
| Colisión de tiles + altura + puentes | Completo |
| Mapas, bordes infinitos, BGM | Completo |
| Boot / sesión / MapManager | Completo |
| Y-Sort y capas de render (puentes) | Completo |
| Plugins de editor (crear mapa, límites) | Funcional |
| Warps / diálogos / combates / menú | Pendiente |

---

## Requisitos

- **Godot 4.7** (GL Compatibility)
- Viewport de referencia: **512×384** (escala viewport)

---

## Arranque rápido

1. Clonar el repositorio y abrir la carpeta en Godot 4.7.
2. La escena principal está definida en `project.godot` (`run/main_scene`).
3. Activar los plugins **Map Creator** y **Map Editor** si no cargan solos (`Project → Project Settings → Plugins`).
4. Ejecutar: se instancia el **Player**, se carga el mapa de `GameStartData` y se coloca en la celda indicada.

Flujo de arranque:

```text
Boot (GameSession)
  → aplica datos opcionales del player
  → MapManager.change_map(map_id, cell, player)
	   → MapCollisionSystem.set_active_map
	   → instancia mapa
	   → reparent Player → EventObject
	   → init altura player + NPCs
```

---

## Arquitectura (visión general)

```text
GameSession + GameStartData     → qué mapa y celda al iniciar
MapManager                      → carga / descarga mapas, coloca player
Map + MapAttributes             → identidad y datos del mapa
  MapMusicController            → BGM
  MapBorderController           → borde infinito 2×2
  Behaviour/Collision           → metatiles de colisión/altura
  EventObject (Y-Sort)          → player + NPCs
CharacterController             → movimiento grid + altura visual
CollisionFacade                 → entidades OR tiles
```

Principio de diseño: **un script no debe tumbar el engine entero**. Audio, bordes, colisión y movimiento fallan o evolucionan por separado.

Documentación detallada por sistema:

- [`doc/ARQUITECTURA.md`](doc/ARQUITECTURA.md) — overview formal de todo el proyecto
- [`doc/Sistema_Character.md`](doc/Sistema_Character.md) — personajes y movimiento
- [`doc/Sistema_Mapa_y_Colision.md`](doc/Sistema_Mapa_y_Colision.md) — mapas, altura y puentes

---

## Estructura de carpetas

```text
addons/
  map_creator/     Plugin: crear escena de mapa desde plantilla
  map_editor/      Plugin: límites de pintura, utilidades de editor
assets/            Arte compartido (OW, sombras, tilesets)
game/assets/       Arte propio del juego (player Kael/Kaida, etc.)
data/resources/    Resources (.tres): rutas, TileSet de colisión
doc/               Documentación
scenes/overworld/
  game/            Boot / sesión
  map/             map_base + mapas (pueblo, rutas, ciudad…)
  player/          player.tscn
  npc/             npc.tscn
scripts/overworld/
  map/             Map, manager, bordes, música, colisión de tiles
  map/collision/   Facade + TileData
  object_events/   Character, Player, NPC, movement
  sfx/             MusicManager, IDs de audio
sfx/               BGM, ME, SE, cries
```

---

## Convenciones

- **Grid:** 16×16 px por casilla.
- **Posición lógica:** origen del root `Player` / `Npc` (esquina superior izquierda de la casilla).
- **Grupos:** `"Player"`, `"Npc"`.
- **Tipado:** estricto (`untyped_declaration` / `inferred_declaration` como error).
- **Autoload:** `MusicManager`.

---

## Licencia y uso

Proyecto personal de aprendizaje/desarrollo. No redistribuir assets de terceros sin cumplir sus términos. El código del motor es de Axel_CodeInfinity o tambien conocido como Axel Loquendo / PokeDot Studio.

---

## Créditos

- Diseño e implementación: **Axel_CodeInfinity/Axel Loquendo**
- Motor: **Godot Engine 4.7**

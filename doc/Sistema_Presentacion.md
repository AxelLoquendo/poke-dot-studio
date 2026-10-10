# Audio, fade y clima

Estos tres servicios no conocen NPCs ni scripts. Un mapa, al volverse actual, o un comando, les pide un estado. Ellos lo muestran.

## 1. Música y efectos

`MusicManager` es un autoload. Reproduce BGM y SE por id de `SFXGame`. Ese script es un catálogo de rutas bajo `res://sfx/` (`bgm`, `se`, `me`, gritos). No decide cuándo suena una ruta.

`MapMusicController`, hijo del mapa, en `activar` lee el BGM de `MapAttributes` y se lo pasa al manager. Cambiar de mapa actual vuelve a llamar a `activar`. No hay fade de música propio en el controlador: si el manager corta el stream anterior, el corte es el de esa función.

Efectos que hoy salen del overworld, no de un comando `sound` (ese comando no está portado):

- salto de ledge, en `CharacterAnimatedController`, solo grupo `Player`
- choque, en `CharacterController._play_bump`, solo grupo `Player`
- cursor y aceptar de la caja de choices, en `ChoiceWindow` y `MessageUI`

## 2. Fade

`FadeScreen` es un `CanvasLayer` con un `ColorRect` a pantalla completa. `fade_out` y `fade_in` interpolan el alfa con un tween. `set_covered` y `set_clear` no animan.

`ScriptCmdFade` llama al autoload y completa el comando cuando el tween termina. La duración por defecto es la del propio fade. Un argumento numérico en el `.txt` la sustituye.

El fade no pausa el árbol. Quien no deba moverse tiene que estar locked por el script (`lock`) o por el mensaje.

## 3. Clima

`WeatherManager` guarda id, intensidad y si hay transición. `set_weather` / `clear_weather` publican el cambio. No crean sprites.

`MapWeatherController` traduce el clima declarado en el mapa a esa llamada cuando el mapa se activa.

`WeatherRenderer` es el autoload que dibuja. Mantiene tres familias, todas en pantalla y no en coordenadas de mapa:

- Partículas (lluvia, nieve, tormenta). `_update_particles` decide vida y reciclaje. `_mover_particula` aplica delta, drift de nieve y opacidad. El spawn de cada gota está en `_reset_particle` y sigue las reglas de entrada de Essentials (por la derecha si la pendiente es fuerte, por arriba si no). Los índices de splash solo se ven en los últimos 0.2 s de vida.
- Tiles (niebla, arena, ventisca). Una grilla que envuelve el viewport y se desplaza con `tile_delta`.
- Rayo, solo en tormenta, como flash de color.

`WeatherCatalog` y `WeatherData` describen texturas, deltas y opacidad por `WeatherID`. Añadir un clima es un resource y una entrada del catálogo, no un bloque nuevo dentro del bucle de partículas, salvo que el movimiento no sea un delta más un drift.

La intensidad 0 deja las partículas en cero y los tiles transparentes. El manager sigue teniendo id: apagar no borra el tipo.

## 4. Orden respecto al mensaje

El mensaje vive en la capa 95. El clima y el fade son canvas layers de autoload. Un fade cubre el mensaje si su capa es mayor. Hoy el fade se usa entre eventos, no encima de una choice. No hay un contrato de capas escrito en código más allá de `MessageConfig.MESSAGE_LAYER`.

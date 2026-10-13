# Presentación: audio, fade, clima y ubicación

## 1. Audio

`MusicManager` (autoload) reproduce BGM y SE. No conoce mapas: quien decide la pista es el mapa o un comando de script.

`MapMusicController` / atributos del mapa asignan `map_music` al entrar. `sound` en script resuelve un `SFXGame.SoundEffectID` y llama a `reproducir_se`.

## 2. Fade

`FadeScreen` (autoload, `CanvasLayer` 100) cubre la pantalla con un `ColorRect`.

- Duración por defecto: **0.4 s** (PE `pbFadeOutIn`).
- Curva: **alpha lineal** (no SINE).
- API: `fade_out`, `fade_in`, `fade_out_in`, `set_covered`, `set_clear`.
- `process_mode = ALWAYS` para funcionar con el árbol pausado.

Scripts: `fadeout` / `fadein` [segundos]. Warps de script y de `MapEvent` usan el mismo autoload.

## 3. Clima

`WeatherManager` guarda el clima activo y la intensidad. `WeatherRenderer` dibuja partículas / tiles / rayos.

El clima de un mapa sale de `MapAttributes.weather` e `weather_intensity` al activar el mapa. El comando `weather` en script puede cambiarlo en runtime.

## 4. Cartel de nombre de mapa

`LocationSignpost` (creado por `GameSession`) replica el ritmo de PE `LocationWindow`:

- Entrada 0.4 s desde arriba, visible 1.6 s, salida 0.4 s.
- Se cancela si `MessageService.is_active()`.
- No se repite si el **nombre** es el mismo que el anuncio anterior.

### Datos en el mapa

En `MapAttributes`:

| Campo | Uso |
|---|---|
| `map_name` | Texto del cartel |
| `show_location_name` | Si es false, no se muestra |
| `location_style` | `HGSS`, `PLATINUM`, `DP`, `ORAS`, `XY` |
| `location_type` | `DEFAULT`, `TOWN`, `CITY`, `ROUTE`, `FOREST`, `CAVE`, `LAKE`, `PARK`, `SEA` |

### Gráficos

`LocationSignpostConfig` carga desde `res://assets/ui/Location/`:

- HGSS / Pt: `HGSS town.png`, `Pt route.png`, etc. (prefijo + tipo).
- DP / ORAS / XY: un solo archivo (`DP.png`, `ORAS.png`, `XY.png`).

HGSS suele ser 272×64; el banner usa el tamaño nativo del PNG y el texto centrado encima.

### Señales

`MapFactory.cluster_loaded` y `current_changed` → `LocationSignpost.try_show_for_map`.

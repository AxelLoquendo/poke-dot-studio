class_name MessageConfig
extends Object
## Constantes de mensaje alineadas con Pokémon Essentials 21.1 MessageConfig.
## Solo datos: no dibuja ni gestiona input.

const SCREEN_WIDTH: int = 512
const SCREEN_HEIGHT: int = 384

# --- Fuentes (PE MessageConfig) ---
const FONT_PATH: String = "res://font/power green.ttf"
const FONT_SIZE: int = 27
const FONT_Y_OFFSET: int = 8
const SMALL_FONT_PATH: String = "res://font/power green small.ttf"
const SMALL_FONT_SIZE: int = 21
const NARROW_FONT_PATH: String = "res://font/power green narrow.ttf"
const NARROW_FONT_SIZE: int = 27

# --- Colores de texto (0–255 PE → Color 0–1) ---
const DARK_TEXT_MAIN: Color = Color(80.0 / 255.0, 80.0 / 255.0, 88.0 / 255.0, 1.0)
const DARK_TEXT_SHADOW: Color = Color(160.0 / 255.0, 160.0 / 255.0, 168.0 / 255.0, 1.0)
const LIGHT_TEXT_MAIN: Color = Color(248.0 / 255.0, 248.0 / 255.0, 248.0 / 255.0, 1.0)
const LIGHT_TEXT_SHADOW: Color = Color(72.0 / 255.0, 80.0 / 255.0, 88.0 / 255.0, 1.0)

# --- Layout PE: pbBottomLeftLines ---
const LINE_HEIGHT: int = 32
const DEFAULT_LINES: int = 2
const BORDER_X: int = 32
const BORDER_Y: int = 32
const TEXT_PADDING: int = 4
## Pause cursor: 0=fin texto, 1=abajo-derecha, 2=abajo-centro (PE CURSOR_POSITION)
const CURSOR_POSITION: int = 1

# --- Velocidad de texto (PE medium = 2/80 s) ---
const TEXT_SPEED_MEDIUM: float = 2.0 / 80.0
const TEXT_SPEED_SLOW: float = 4.0 / 80.0
const TEXT_SPEED_FAST: float = 1.0 / 80.0

# --- Skins (PE SPEECH_WINDOWSKINS[0], MENU_WINDOWSKINS[0]) ---
const WINDOWSKINS_DIR: String = "res://assets/window_skins/"
const DEFAULT_SPEECH_SKIN: String = "speech hgss 1.png"
const DEFAULT_CHOICE_SKIN: String = "choice 1.png"
const PAUSE_ARROW_PATH: String = "res://assets/window_skins/pause_arrow.png"
const SEL_ARROW_PATH: String = "res://assets/ui/sel_arrow.png"

const MESSAGE_LAYER: int = 95


static func speech_skin_path() -> String:
	return WINDOWSKINS_DIR + DEFAULT_SPEECH_SKIN


static func choice_skin_path() -> String:
	return WINDOWSKINS_DIR + DEFAULT_CHOICE_SKIN


static func message_height(lines: int = DEFAULT_LINES) -> int:
	return BORDER_Y + (lines * LINE_HEIGHT)


static func message_rect(lines: int = DEFAULT_LINES) -> Rect2:
	var h: int = message_height(lines)
	return Rect2(0.0, float(SCREEN_HEIGHT - h), float(SCREEN_WIDTH), float(h))


static func load_font() -> Font:
	if ResourceLoader.exists(FONT_PATH):
		return load(FONT_PATH) as Font
	return null


static func load_speech_texture() -> Texture2D:
	var path: String = speech_skin_path()
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var alt: String = WINDOWSKINS_DIR + "speech em.png"
	if ResourceLoader.exists(alt):
		return load(alt) as Texture2D
	return null


static func load_choice_texture() -> Texture2D:
	var path: String = choice_skin_path()
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func load_pause_arrow() -> Texture2D:
	if ResourceLoader.exists(PAUSE_ARROW_PATH):
		return load(PAUSE_ARROW_PATH) as Texture2D
	return null


static func load_sel_arrow() -> Texture2D:
	if ResourceLoader.exists(SEL_ARROW_PATH):
		return load(SEL_ARROW_PATH) as Texture2D
	return null

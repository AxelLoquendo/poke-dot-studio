extends Object
class_name TitleConfig

const TITLES_DIR: String = "res://assets/Titles/"

## Sky: splash1 + splash2. Añade credits aquí si quieres una sola imagen de créditos.
const SEQUENCE: PackedStringArray = [
	# "credits1.png",  # si solo usas un png de créditos, déjalo el primero
	"splash1.png",
#	"splash2.png",
]

const TITLE_BG: String = "title.png"
const TITLE_START: String = "start.png"
const START_POS: Vector2 = Vector2(0.0, 342.0)

const SECONDS_PER_SPLASH: float = 2.0
const FADE_DURATION: float = 0.4
const START_FLASH_HALF: float = 0.8
const SCREEN_SIZE: Vector2 = Vector2(512.0, 384.0)

static func path(file_name: String) -> String:
	return TITLES_DIR + file_name

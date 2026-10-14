extends Object
class_name TitleConfig
## Constantes alineadas a PE/Sky IntroEventScene.

const TITLES_DIR: String = "res://assets/Titles/"

const SPLASH_IMAGES: PackedStringArray = [
	"splash1.png",
]

## Opcional: mostrar créditos antes del splash (Sky tiene credits1–5).
const CREDITS_IMAGES: PackedStringArray = [
	# "credits1.png",
	# "credits2.png",
	# "credits3.png",
	# "credits4.png",
	# "credits5.png",
]

const TITLE_BG: String = "title.png"
const TITLE_START: String = "start.png"

## PE: TITLE_START_IMAGE_Y = 322 + 20
const START_POS: Vector2 = Vector2(0.0, 342.0)

const SECONDS_PER_SPLASH: float = 2.0
## PE FADE_TICKS = 8 a 20 ticks/s → 0.4 s
const FADE_DURATION: float = 0.4
## PE TICKS_PER_ENTER_FLASH = 40 → ciclo de parpadeo ~2 s
const START_FLASH_HALF: float = 0.8

const SCREEN_SIZE: Vector2 = Vector2(512.0, 384.0)


static func path(file_name: String) -> String:
	return TITLES_DIR + file_name

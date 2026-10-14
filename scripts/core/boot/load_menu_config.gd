extends Object
class_name LoadMenuConfig
## Layout alineado a PE/Sky PokemonLoadPanel + PokemonLoad_Scene.

const DIR: String = "res://assets/ui/Load/"
const BG_PATH: String = DIR + "bg.png"
const PANELS_PATH: String = DIR + "panels.png"

const SCREEN_W: int = 512
const SCREEN_H: int = 384

## Atlas panels.png (408×536)
const PANEL_W: int = 408
const PANEL_CONTINUE_H: int = 222
const PANEL_NEW_H: int = 46
const PANEL_NONCONTINUE_SRC_Y: int = 444

const PANEL_X: float = 48.0
const PANEL_START_Y: float = 32.0

const TEXT_COLOR: Color = Color(232.0 / 255.0, 232.0 / 255.0, 232.0 / 255.0)
const TEXT_SHADOW: Color = Color(136.0 / 255.0, 136.0 / 255.0, 136.0 / 255.0)
const TEXT_DISABLED: Color = Color(0.55, 0.55, 0.55, 1.0)

const TITLE_OFFSET: Vector2 = Vector2(16.0, 10.0)
const FONT_SIZE: int = 24

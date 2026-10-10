class_name DialogueLine
extends Resource

@export var speaker_name: String = ""
@export_multiline var text: String = ""
## Si true, espera input para avanzar; si false, auto-avanza tras `auto_delay`.
@export var wait_input: bool = true
@export var auto_delay: float = 0.0
## Opcional: retrato / emoción (Sky tiene frames de OW; más adelante)
@export var portrait: Texture2D

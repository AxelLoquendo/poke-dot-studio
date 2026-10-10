class_name DialogueSequence
extends Resource

@export var lines: Array[DialogueLine] = []
## Si no vacío, al terminar las líneas muestra choices.
@export var choices: PackedStringArray = PackedStringArray()

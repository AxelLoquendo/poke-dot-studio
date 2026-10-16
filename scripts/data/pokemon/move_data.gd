extends Resource
class_name MoveData

@export var key: StringName = &""
@export var name: String = ""
@export var type: PokemonEnums.TypeId = PokemonEnums.TypeId.NORMAL
@export var category: PokemonEnums.MoveCategory = PokemonEnums.MoveCategory.PHYSICAL
@export var power: int = 0
@export var accuracy: int = 100
@export var total_pp: int = 5
@export var target: StringName = &"NearOther"
@export var function_code: StringName = &"None"
@export var flags: PackedStringArray = PackedStringArray()
@export var effect_chance: int = 0
@export var priority: int = 0
@export_multiline var description: String = ""

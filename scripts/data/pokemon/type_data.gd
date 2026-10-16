extends Resource
class_name TypeData

@export var id: PokemonEnums.TypeId = PokemonEnums.TypeId.NORMAL
@export var key: StringName = &""
@export var name: String = ""
@export var icon_position: int = 0
@export var weaknesses: Array[PokemonEnums.TypeId] = []
@export var resistances: Array[PokemonEnums.TypeId] = []
@export var immunities: Array[PokemonEnums.TypeId] = []

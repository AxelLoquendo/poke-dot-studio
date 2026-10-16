extends Object
class_name PokemonGraphics
## Rutas al estilo Essentials: id → archivo.

const ROOT: String = "res://assets/Pokemon/"
const ITEMS_ROOT: String = "res://assets/Items/"


static func icon_path(species_key: StringName, form: int = 0, shiny: bool = false) -> String:
	var folder: String = "Icons shiny/" if shiny else "Icons/"
	return ROOT + folder + _file_name(species_key, form)


static func front_path(species_key: StringName, form: int = 0, shiny: bool = false) -> String:
	var folder: String = "Front shiny/" if shiny else "Front/"
	return ROOT + folder + _file_name(species_key, form)


static func back_path(species_key: StringName, form: int = 0, shiny: bool = false) -> String:
	var folder: String = "Back shiny/" if shiny else "Back/"
	return ROOT + folder + _file_name(species_key, form)


static func item_path(item_key: StringName) -> String:
	return ITEMS_ROOT + String(item_key).to_upper() + ".png"


static func load_icon(species_key: StringName, form: int = 0, shiny: bool = false) -> Texture2D:
	return _load_texture(icon_path(species_key, form, shiny), icon_path(species_key, 0, shiny))


static func load_front(species_key: StringName, form: int = 0, shiny: bool = false) -> Texture2D:
	return _load_texture(front_path(species_key, form, shiny), front_path(species_key, 0, shiny))


static func load_item(item_key: StringName) -> Texture2D:
	var path: String = item_path(item_key)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func _file_name(species_key: StringName, form: int) -> String:
	var base: String = String(species_key).to_upper()
	if form > 0:
		return "%s_%d.png" % [base, form]
	return base + ".png"


static func _load_texture(path: String, fallback: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if fallback != path and ResourceLoader.exists(fallback):
		return load(fallback) as Texture2D
	# placeholder PE
	var zero: String = ROOT + "Icons/000.png"
	if ResourceLoader.exists(zero):
		return load(zero) as Texture2D
	return null

@tool
extends EditorPlugin

const RUTA_PLANTILLA: String = "res://scenes/overworld/map/map_base.tscn"
const RUTA_POR_DEFECTO: String = "res://scenes/overworld/map/"
const RUTA_MAP_SECTION: String = "res://scripts/overworld/map/map_section.gd"
const MENU_CREAR: String = "🗺️ Crear nuevo mapa"

func _enter_tree() -> void:
	add_tool_menu_item(MENU_CREAR, _abrir_dialogo)

func _exit_tree() -> void:
	remove_tool_menu_item(MENU_CREAR)

func _abrir_dialogo() -> void:
	var dialogo: EditorFileDialog = EditorFileDialog.new()
	dialogo.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialogo.access = EditorFileDialog.ACCESS_RESOURCES
	dialogo.title = "Crear nuevo mapa"
	dialogo.add_filter("*.tscn", "Escena de mapa")
	dialogo.current_dir = RUTA_POR_DEFECTO
	dialogo.current_file = "nuevo_mapa.tscn"
	dialogo.file_selected.connect(func(ruta: String) -> void:
		dialogo.queue_free()
		_crear_mapa(ruta)
	)
	dialogo.canceled.connect(dialogo.queue_free)
	EditorInterface.get_base_control().add_child(dialogo)
	dialogo.popup_file_dialog()

func _crear_mapa(ruta: String) -> void:
	if not ResourceLoader.exists(RUTA_PLANTILLA):
		_mostrar_mensaje("Crear nuevo mapa", "No se encontró la plantilla:\n" + RUTA_PLANTILLA)
		return
	if FileAccess.file_exists(ruta):
		_mostrar_mensaje("Crear nuevo mapa", "Ya existe un archivo en:\n" + ruta)
		return
	var nombre_archivo: String = ruta.get_file().get_basename()
	var clave: String = _crear_clave_map_id(nombre_archivo)
	if clave.is_empty():
		_mostrar_mensaje("Crear nuevo mapa", "El nombre del archivo debe contener letras o números.")
		return
	if _map_id_existe(clave):
		_mostrar_mensaje("Crear nuevo mapa", "%s ya existe en MapSection." % clave)
		return
	if not _registrar_map_section(clave, ruta):
		_mostrar_mensaje("Crear nuevo mapa", "No se pudo actualizar MapSection.")
		return
	await _actualizar_clases_globales()
	var script_section: GDScript = load(RUTA_MAP_SECTION) as GDScript
	if script_section == null:
		_mostrar_mensaje("Crear nuevo mapa", "No se pudo cargar MapSection después de actualizarlo.")
		return
	var constantes: Dictionary = script_section.get_script_constant_map()
	var enum_map_id: Dictionary = constantes.get("MapID", {})
	if not enum_map_id.has(clave):
		_mostrar_mensaje("Crear nuevo mapa", "%s no aparece en el enum después de actualizar MapSection." % clave)
		return
	var id_map: int = enum_map_id[clave]
	var script_attributes: GDScript = MapAttributes as GDScript
	if script_attributes != null:
		script_attributes.reload(true)
	var plantilla: PackedScene = load(RUTA_PLANTILLA) as PackedScene
	if plantilla == null:
		_mostrar_mensaje("Crear nuevo mapa", "No se pudo cargar la plantilla.")
		return
	var escena: Node = plantilla.instantiate()
	if escena == null:
		_mostrar_mensaje("Crear nuevo mapa", "No se pudo instanciar la plantilla.")
		return
	var mapa: Map = escena as Map
	if mapa == null:
		escena.free()
		_mostrar_mensaje("Crear nuevo mapa", "La plantilla no tiene un nodo raíz Map.")
		return
	if mapa.attributes == null:
		mapa.attributes = MapAttributes.new()
	else:
		mapa.attributes = mapa.attributes.duplicate(true) as MapAttributes
	mapa.attributes.map_id = id_map as MapSection.MapID
	mapa.attributes.map_name = nombre_archivo.capitalize()
	var paquete: PackedScene = PackedScene.new()
	var resultado: Error = paquete.pack(mapa)
	escena.free()
	if resultado != OK:
		_mostrar_mensaje("Crear nuevo mapa", "No se pudo empaquetar la nueva escena.")
		return
	var guardado: Error = ResourceSaver.save(paquete, ruta)
	if guardado != OK:
		_mostrar_mensaje("Crear nuevo mapa", "No se pudo guardar el mapa:\n" + error_string(guardado))
		return
	EditorInterface.open_scene_from_path(ruta)
	print("Mapa creado: %s → %s (%d)" % [ruta, clave, id_map])

func _crear_clave_map_id(nombre_archivo: String) -> String:
	var texto: String = nombre_archivo.to_upper()
	var resultado: String = ""
	for caracter: String in texto:
		if caracter >= "A" and caracter <= "Z":
			resultado += caracter
		elif caracter >= "0" and caracter <= "9":
			resultado += caracter
		else:
			if not resultado.ends_with("_"):
				resultado += "_"
	resultado = resultado.trim_suffix("_")
	if resultado.is_empty():
		return ""
	return "MAPSEC_" + resultado

func _map_id_existe(clave: String) -> bool:
	var contenido: String = FileAccess.get_file_as_string(RUTA_MAP_SECTION)
	return contenido.find("\t" + clave + ",") != -1

func _registrar_map_section(clave: String, ruta: String) -> bool:
	var contenido: String = FileAccess.get_file_as_string(RUTA_MAP_SECTION)
	var marcador_enum: String = "enum MapID {"
	var inicio_enum: int = contenido.find(marcador_enum)
	if inicio_enum == -1:
		return false
	var fin_enum: int = contenido.find("}", inicio_enum)
	if fin_enum == -1:
		return false
	var entrada_enum: String = "\t%s,\n" % clave
	contenido = contenido.insert(fin_enum, entrada_enum)
	var marcador_diccionario: String = "const MAP_SCENES: Dictionary = {"
	var inicio_diccionario: int = contenido.find(marcador_diccionario)
	if inicio_diccionario == -1:
		return false
	var fin_diccionario: int = contenido.find("}", inicio_diccionario)
	if fin_diccionario == -1:
		return false
	var entrada_diccionario: String = "\tMapID.%s: %s,\n" % [clave, var_to_str(ruta)]
	contenido = contenido.insert(fin_diccionario, entrada_diccionario)
	var archivo: FileAccess = FileAccess.open(RUTA_MAP_SECTION, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(contenido)
	archivo.close()
	return true

func _actualizar_clases_globales() -> void:
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
	filesystem.update_file(RUTA_MAP_SECTION)
	EditorInterface.get_script_editor().reload_open_files()
	filesystem.scan()
	await filesystem.script_classes_updated

func _mostrar_mensaje(titulo: String, texto: String) -> void:
	var dialogo: AcceptDialog = AcceptDialog.new()
	dialogo.title = titulo
	dialogo.dialog_text = texto
	dialogo.confirmed.connect(dialogo.queue_free)
	dialogo.canceled.connect(dialogo.queue_free)
	EditorInterface.get_base_control().add_child(dialogo)
	dialogo.popup_centered()

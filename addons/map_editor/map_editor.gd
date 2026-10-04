@tool
extends EditorPlugin

const TILE_SIZE: float = 16.0

var _arrastrando_entidad: bool = false
var _entidad_activa: Node2D = null
var _offset_drag: Vector2 = Vector2.ZERO


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	_soltar_entidad()


func _handles(object: Object) -> bool:
	if object is TileMapLayer:
		return _layer_pertenece_a_mapa(object as TileMapLayer)
	if object is Map:
		return true
	if object is Node2D:
		return _es_entidad(object as Node2D)
	return false


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	# --- Entidades (Player / Npc) ---
	if _manejar_input_entidad(event):
		return true

	# --- Límite de tiles (como antes) ---
	return _manejar_input_tiles(event)


# ============================================================
# ENTIDADES — snap 16x16
# ============================================================

func _manejar_input_entidad(event: InputEvent) -> bool:
	var entidad: Node2D = _obtener_entidad_seleccionada()
	if entidad == null:
		_soltar_entidad()
		return false

	var mapa: Map = _obtener_mapa_actual()
	if mapa == null:
		return false

	if event is InputEventMouseButton:
		var boton: InputEventMouseButton = event as InputEventMouseButton
		if boton.button_index != MOUSE_BUTTON_LEFT:
			return false

		if boton.pressed:
			var mundo: Vector2 = _obtener_posicion_mundo(boton.position)
			# Solo empezar drag si el clic está cerca de la entidad
			if not _clic_sobre_entidad(entidad, mundo):
				return false

			_arrastrando_entidad = true
			_entidad_activa = entidad
			_offset_drag = entidad.global_position - mundo
			return true
		else:
			if _arrastrando_entidad:
				_aplicar_snap(entidad, mapa)
				_soltar_entidad()
				return true

	if event is InputEventMouseMotion and _arrastrando_entidad and _entidad_activa != null:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var mundo: Vector2 = _obtener_posicion_mundo(motion.position)
		var deseada: Vector2 = mundo + _offset_drag
		_entidad_activa.global_position = _snap_global(deseada, mapa)
		return true

	return false


func _aplicar_snap(entidad: Node2D, mapa: Map) -> void:
	entidad.global_position = _snap_global(entidad.global_position, mapa)
	# Marcar la escena como modificada
	EditorInterface.mark_scene_as_unsaved()


func _snap_global(pos_global: Vector2, mapa: Map) -> Vector2:
	var local: Vector2 = mapa.to_local(pos_global)
	var celda: Vector2i = Vector2i(
		roundi(local.x / TILE_SIZE),
		roundi(local.y / TILE_SIZE)
	)

	# Opcional: no salir del mapa
	if mapa.attributes != null:
		var size: Vector2i = mapa.attributes.map_size
		if size.x > 0 and size.y > 0:
			celda.x = clampi(celda.x, 0, size.x - 1)
			celda.y = clampi(celda.y, 0, size.y - 1)

	var local_snap: Vector2 = Vector2(celda) * TILE_SIZE
	return mapa.to_global(local_snap)


func _clic_sobre_entidad(entidad: Node2D, mundo: Vector2) -> bool:
	# Área de agarre ~1 tile alrededor del origen de la entidad
	var local: Vector2 = entidad.to_local(mundo)
	return absf(local.x) <= TILE_SIZE and absf(local.y) <= TILE_SIZE


func _soltar_entidad() -> void:
	_arrastrando_entidad = false
	_entidad_activa = null
	_offset_drag = Vector2.ZERO


func _obtener_entidad_seleccionada() -> Node2D:
	var nodos: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	if nodos.is_empty():
		return null
	var nodo: Node = nodos[0]
	if nodo is Node2D and _es_entidad(nodo as Node2D):
		return nodo as Node2D
	return null


func _es_entidad(nodo: Node2D) -> bool:
	if nodo.is_in_group("Player") or nodo.is_in_group("Npc"):
		return true
	# Fallback por nombre de script / escena
	var script: Script = nodo.get_script()
	if script == null:
		return false
	var path: String = script.resource_path
	return path.ends_with("player.gd") or path.ends_with("npc.gd")


# ============================================================
# TILES — no pintar fuera de map_size
# ============================================================

func _manejar_input_tiles(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return false

	var mapa: Map = _obtener_mapa_actual()
	if mapa == null or mapa.attributes == null:
		return false

	var map_size: Vector2i = mapa.attributes.map_size
	if map_size.x <= 0 or map_size.y <= 0:
		return false

	var layer: TileMapLayer = _obtener_tile_layer_seleccionado()
	if layer == null or not _layer_pertenece_a_mapa(layer):
		return false

	var mouse: InputEventMouse = event as InputEventMouse
	var mundo: Vector2 = _obtener_posicion_mundo(mouse.position)
	var local_mapa: Vector2 = mapa.to_local(mundo)
	var celda: Vector2i = Vector2i(
		floori(local_mapa.x / TILE_SIZE),
		floori(local_mapa.y / TILE_SIZE)
	)

	if _celda_dentro_del_mapa(celda, map_size):
		return false

	if event is InputEventMouseButton:
		var boton: InputEventMouseButton = event as InputEventMouseButton
		if (
			boton.button_index == MOUSE_BUTTON_LEFT
			or boton.button_index == MOUSE_BUTTON_RIGHT
		):
			return true

	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (
			(motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
			or (motion.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0
		):
			return true

	return false


func _celda_dentro_del_mapa(celda: Vector2i, tamano: Vector2i) -> bool:
	return (
		celda.x >= 0
		and celda.y >= 0
		and celda.x < tamano.x
		and celda.y < tamano.y
	)


# ============================================================
# UTILIDADES
# ============================================================

func _obtener_mapa_actual() -> Map:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root is Map:
		return root as Map
	return null


func _obtener_tile_layer_seleccionado() -> TileMapLayer:
	var nodos: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	if nodos.is_empty():
		return null
	if nodos[0] is TileMapLayer:
		return nodos[0] as TileMapLayer
	return null


func _layer_pertenece_a_mapa(layer: TileMapLayer) -> bool:
	var mapa: Map = _obtener_mapa_actual()
	if mapa == null:
		return false
	var actual: Node = layer
	while actual != null:
		if actual == mapa:
			return true
		actual = actual.get_parent()
	return false


func _obtener_posicion_mundo(posicion_viewport: Vector2) -> Vector2:
	var viewport: SubViewport = EditorInterface.get_editor_viewport_2d()
	var xform: Transform2D = viewport.get_final_transform()
	return xform.affine_inverse() * posicion_viewport

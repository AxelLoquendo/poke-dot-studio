@tool
extends EditorPlugin

const TILE_SIZE: float = 16.0

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass

func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not event is InputEventMouse:
		return false
	var mapa: Map = _obtener_mapa_actual()
	if mapa == null:
		return false
	if mapa.attributes == null:
		return false
	var tile_layer: TileMapLayer = _obtener_tile_layer_seleccionado()
	if tile_layer == null:
		return false
	var posicion_mundo: Vector2 = _obtener_posicion_mundo(event.position)
	var posicion_local: Vector2 = tile_layer.to_local(posicion_mundo)
	var celda: Vector2i = Vector2i(floor(posicion_local.x / TILE_SIZE), floor(posicion_local.y / TILE_SIZE))
	if _celda_dentro_del_mapa(celda, mapa.attributes.map_size):
		return false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			return true
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			return true
	return false

func _celda_dentro_del_mapa(celda: Vector2i, tamano: Vector2i) -> bool:
	return celda.x >= 0 and celda.x < tamano.x and celda.y >= 0 and celda.y < tamano.y

func _obtener_mapa_actual() -> Map:
	var escena: Node = EditorInterface.get_edited_scene_root()
	if escena == null:
		return null
	if escena is Map:
		return escena
	return escena.get_node_or_null(".") as Map

func _obtener_tile_layer_seleccionado() -> TileMapLayer:
	var seleccionado: Node = EditorInterface.get_selection().get_selected_nodes()[0] if not EditorInterface.get_selection().get_selected_nodes().is_empty() else null
	if seleccionado is TileMapLayer:
		return seleccionado
	return null

func _obtener_posicion_mundo(posicion: Vector2) -> Vector2:
	var viewport: SubViewport = EditorInterface.get_editor_viewport_2d()
	var transformacion: Transform2D = viewport.get_canvas_transform()
	return transformacion.affine_inverse() * posicion

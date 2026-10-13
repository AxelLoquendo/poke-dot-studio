@tool
extends Marker2D
class_name MapEvent
## Evento de casilla. Marker2D = se ve y se arrastra bien en el editor 2D.

enum Kind { WARP, COORD, BG }
enum BgKind { SIGN, HIDDEN_ITEM }

const TILE_SIZE: int = 16

@export var kind: Kind = Kind.COORD
@export var show_debug: bool = true

## Editar casilla aquí también mueve el marcador (útil si el drag se resiste).
@export var tile: Vector2i = Vector2i.ZERO:
	set(value):
		tile = value
		if Engine.is_editor_hint() or is_inside_tree():
			_apply_tile_to_position()

@export_group("Warp")
@export var warp_id: int = 0
@export var dest_map: MapSection.MapID = MapSection.MapID.NONE
@export var dest_warp_id: int = 0
@export var dest_tile_fallback: Vector2i = Vector2i.ZERO
@export_range(0.05, 2.0, 0.05) var warp_fade_duration: float = 0.4
@export var arrival_facing: Vector2 = Vector2.DOWN

@export_group("Coord / BG script")
@export var condition_flag: StringName = &""
@export var expected_value: String = "true"
@export_file("*.txt") var script_file: String = ""

@export_group("BG")
@export var bg_kind: BgKind = BgKind.SIGN
@export var hidden_item_flag: StringName = &""

var _snap_lock: bool = false


func _ready() -> void:
	add_to_group(&"map_events")
	z_index = 100
	if Engine.is_editor_hint():
		set_notify_transform(true)
		# Si tile quedó en 0,0 pero el nodo ya está puesto a mano, sincroniza desde position
		_sync_tile_from_position()
		queue_redraw()
	else:
		_apply_tile_to_position()


func _notification(what: int) -> void:
	# Deferred: no pelea con el drag del mouse frame a frame
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		call_deferred("_on_editor_moved")


func _on_editor_moved() -> void:
	if _snap_lock:
		return
	_snap_to_tile_grid()
	_sync_tile_from_position()
	queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _snap_to_tile_grid() -> void:
	if _snap_lock:
		return
	var snapped_pos: Vector2 = Vector2(
		floorf(position.x / float(TILE_SIZE)) * float(TILE_SIZE),
		floorf(position.y / float(TILE_SIZE)) * float(TILE_SIZE)
	)
	if position != snapped_pos:
		_snap_lock = true
		position = snapped_pos
		_snap_lock = false


func _sync_tile_from_position() -> void:
	var t: Vector2i = Vector2i(
		int(floor(position.x / float(TILE_SIZE))),
		int(floor(position.y / float(TILE_SIZE)))
	)
	if tile != t:
		tile = t  # no reentra de forma agresiva: _apply solo si cambió position


func _apply_tile_to_position() -> void:
	var target: Vector2 = Vector2(tile) * float(TILE_SIZE)
	if position != target:
		_snap_lock = true
		position = target
		_snap_lock = false


func _draw() -> void:
	if not show_debug:
		return
	if not Engine.is_editor_hint() and not show_debug:
		return
	var color: Color
	match kind:
		Kind.WARP:
			color = Color(0.2, 0.6, 1.0, 0.35)
		Kind.COORD:
			color = Color(0.85, 0.25, 0.95, 0.35)
		Kind.BG:
			color = Color(1.0, 0.85, 0.2, 0.35)
	draw_rect(Rect2(Vector2.ZERO, Vector2(TILE_SIZE, TILE_SIZE)), color)
	if kind == Kind.WARP and Engine.is_editor_hint():
		draw_string(
			ThemeDB.fallback_font,
			Vector2(2, 12),
			"W%d" % warp_id,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			Color.WHITE
		)


func get_tile() -> Vector2i:
	# Prioriza global por si el mapa no está en (0,0)
	return Vector2i(
		int(floor(global_position.x / float(TILE_SIZE))),
		int(floor(global_position.y / float(TILE_SIZE)))
	)


func condition_ok() -> bool:
	if condition_flag.is_empty():
		return true
	var valor: Variant = ScriptExecutionContext.global_flags.get(condition_flag, false)
	return str(valor).to_lower() == expected_value.to_lower()


func is_hidden_item_taken() -> bool:
	if hidden_item_flag.is_empty():
		return false
	return bool(ScriptExecutionContext.global_flags.get(hidden_item_flag, false))

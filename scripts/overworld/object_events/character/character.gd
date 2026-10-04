@tool
extends Node
class_name Character

const TILE_SIZE: float = 16.0

@export var data: CharacterBase:
	set(value):
		data = value
		update_character()

@onready var OwSprite: AnimatedSprite2D = $Sprite
@onready var ShadowSprite: Sprite2D = $Shadow

var _last_ow: EventObjects.Obj_Event = EventObjects.Obj_Event.NONE
var _last_shadow: CharacterBase.shadow = CharacterBase.shadow.NONE

func _ready() -> void:
	update_character()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if data == null:
		return
	if data.ow != _last_ow or data.shadow_type != _last_shadow:
		update_character()

func update_character() -> void:
	if data == null:
		return
	if not is_node_ready():
		return
	var ow_path: String = EventObjects.ow_sprites.get(data.ow, "")
	if ow_path != "":
		var texture: Texture2D = load(ow_path)
		if texture:
			update_ow_sprite(texture)
	var shadow_path: String = CharacterBase.shadow_sprites.get(data.shadow_type, "")
	if shadow_path != "":
		ShadowSprite.texture = load(shadow_path)
	else:
		ShadowSprite.texture = null
	_last_ow = data.ow
	_last_shadow = data.shadow_type

func update_ow_sprite(texture: Texture2D) -> void:
	var frame_size: Vector2 = texture.get_size() / Vector2(3, 4)
	var directions: Dictionary = {"Down": 0, "Up": 1, "Left": 2, "Right": 3}
	var steps: Dictionary = {"First_Step": 0, "Idle": 1, "Second_Step": 2}
	for direction: String in directions:
		var y: int = directions[direction]
		for step: String in steps:
			var x: int = steps[step]
			var animation_name: String = step + "_" + direction
			if not OwSprite.sprite_frames.has_animation(animation_name):
				continue
			var atlas_0: AtlasTexture = AtlasTexture.new()
			atlas_0.atlas = texture
			atlas_0.region = Rect2(Vector2(x, y) * frame_size, frame_size)
			OwSprite.sprite_frames.set_frame(animation_name, 0, atlas_0)
			if step != "Idle":
				var atlas_1: AtlasTexture = AtlasTexture.new()
				atlas_1.atlas = texture
				atlas_1.region = Rect2(Vector2(1, y) * frame_size, frame_size)
				OwSprite.sprite_frames.set_frame(animation_name, 1, atlas_1)
	_alinear_a_casilla(frame_size)

func _alinear_a_casilla(frame_size: Vector2) -> void:
	if OwSprite == null:
		return
	OwSprite.centered = true
	OwSprite.position = Vector2(TILE_SIZE * 0.5, TILE_SIZE - frame_size.y * 0.5)

func play_animation(animation_name: String) -> void:
	OwSprite.play(animation_name)

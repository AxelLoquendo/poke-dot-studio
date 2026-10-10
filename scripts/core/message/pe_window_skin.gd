class_name PeWindowSkin
extends RefCounted
## Interpreta windowskins de Pokémon Essentials (formato PE).

var texture: Texture2D
var margin_left: int = 16
var margin_top: int = 16
var margin_right: int = 16
var margin_bottom: int = 16
var body_rect: Rect2i = Rect2i(16, 16, 16, 16)


static func from_texture(tex: Texture2D) -> PeWindowSkin:
	var skin: PeWindowSkin = PeWindowSkin.new()
	skin.texture = tex
	if tex == null:
		return skin
	var w: int = tex.get_width()
	var h: int = tex.get_height()
	# PE loadSkinFile: speech 80×48 / 96×48
	if (w == 80 or w == 96) and h == 48:
		skin.body_rect = Rect2i(32, 16, 16, 16)
		skin.margin_left = 32
		skin.margin_top = 16
		skin.margin_right = w - 48
		skin.margin_bottom = h - 32
		return skin
	# choice 48×48
	if w == 48 and h == 48:
		skin.body_rect = Rect2i(16, 16, 16, 16)
		skin.margin_left = 16
		skin.margin_top = 16
		skin.margin_right = 16
		skin.margin_bottom = 16
		return skin
	var bx: int = maxi((w - 16) / 2, 1)
	var by: int = maxi((h - 16) / 2, 1)
	skin.body_rect = Rect2i(bx, by, mini(16, w - bx), mini(16, h - by))
	skin.margin_left = bx
	skin.margin_top = by
	skin.margin_right = maxi(w - bx - 16, 1)
	skin.margin_bottom = maxi(h - by - 16, 1)
	return skin


func apply_to(nine: NinePatchRect) -> void:
	if nine == null:
		return
	nine.texture = texture
	nine.patch_margin_left = margin_left
	nine.patch_margin_top = margin_top
	nine.patch_margin_right = margin_right
	nine.patch_margin_bottom = margin_bottom
	nine.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	nine.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH


func content_offset() -> Vector2:
	return Vector2(float(margin_left), float(margin_top))


func content_margin_right_bottom() -> Vector2:
	return Vector2(float(margin_right), float(margin_bottom))

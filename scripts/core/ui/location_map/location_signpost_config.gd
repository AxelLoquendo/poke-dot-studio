extends Object
class_name LocationSignpostConfig

const DIR: String = "res://assets/ui/Location/"

const TYPE_FILE: Dictionary = {
	MapAttributes.LocationType.DEFAULT: "default.png",
	MapAttributes.LocationType.TOWN: "town.png",
	MapAttributes.LocationType.CITY: "city.png",
	MapAttributes.LocationType.ROUTE: "route.png",
	MapAttributes.LocationType.FOREST: "forest.png",
	MapAttributes.LocationType.CAVE: "cave.png",
	MapAttributes.LocationType.LAKE: "lake.png",
	MapAttributes.LocationType.PARK: "park.png",
	MapAttributes.LocationType.SEA: "sea.png",
}

const STYLE_PREFIX: Dictionary = {
	MapAttributes.LocationStyle.HGSS: "HGSS ",
	MapAttributes.LocationStyle.PLATINUM: "Pt ",
}

## Sets de un solo archivo (sin variantes por tipo).
const STYLE_SINGLE: Dictionary = {
	MapAttributes.LocationStyle.DP: "DP.png",
	MapAttributes.LocationStyle.ORAS: "ORAS.png",
	MapAttributes.LocationStyle.XY: "XY.png",
}


static func texture_for(
	style: MapAttributes.LocationStyle,
	location_type: MapAttributes.LocationType
) -> Texture2D:
	var path: String = ""
	if STYLE_SINGLE.has(style):
		path = DIR + str(STYLE_SINGLE[style])
	else:
		var prefix: String = str(STYLE_PREFIX.get(style, "HGSS "))
		var file: String = str(TYPE_FILE.get(location_type, "default.png"))
		path = DIR + prefix + file
		if not ResourceLoader.exists(path):
			path = DIR + prefix + "default.png"
	if not ResourceLoader.exists(path):
		push_warning("LocationSignpost: falta %s" % path)
		return null
	return load(path) as Texture2D

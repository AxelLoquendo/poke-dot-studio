class_name WeatherData
extends Resource
## Descripción estática de un clima (gráficos, movimiento, tone).

enum Category {
	NONE,
	RAIN,
	SNOW,
	SAND,
	FOG,
	SUN,
}

@export var id: WeatherID.Id = WeatherID.Id.NONE
@export var category: Category = Category.NONE

## Partículas (gotas, copos, etc.)
@export var particle_textures: Array[Texture2D] = []
@export var particle_delta: Vector2 = Vector2.ZERO
@export var particle_opacity_delta: float = 0.0
@export var max_particles: int = 40

## Overlay en tiles (fog, sandstorm, blizzard)
@export var tile_textures: Array[Texture2D] = []
@export var tile_delta: Vector2 = Vector2.ZERO

## Tone de pantalla (r/g/b = tinte, a = fuerza base)
@export var tone: Color = Color(0.0, 0.0, 0.0, 0.0)

## Extras
@export var has_lightning: bool = false
@export var splash_texture: Texture2D

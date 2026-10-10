class_name TileBehaviorSystem
extends RefCounted

static var _handlers: Dictionary = {}


static func _ensure() -> void:
	if not _handlers.is_empty():
		return
	_handlers[TileBehaviorId.Id.NONE] = TileBehaviorHandler.new()
	_handlers[TileBehaviorId.Id.LEDGE_DOWN] = LedgeBehavior.new(Vector2.DOWN)
	_handlers[TileBehaviorId.Id.LEDGE_UP] = LedgeBehavior.new(Vector2.UP)
	_handlers[TileBehaviorId.Id.LEDGE_LEFT] = LedgeBehavior.new(Vector2.LEFT)
	_handlers[TileBehaviorId.Id.LEDGE_RIGHT] = LedgeBehavior.new(Vector2.RIGHT)


static func get_handler(id: int) -> TileBehaviorHandler:
	_ensure()
	if _handlers.has(id):
		return _handlers[id] as TileBehaviorHandler
	return _handlers[TileBehaviorId.Id.NONE] as TileBehaviorHandler


static func build_context(
	controller: CharacterController,
	from_world: Vector2,
	to_world: Vector2
) -> TileBehaviorContext:
	var ctx: TileBehaviorContext = TileBehaviorContext.new()
	ctx.controller = controller
	ctx.from_world = from_world
	ctx.to_world = to_world
	var delta: Vector2 = to_world - from_world
	if absf(delta.x) > absf(delta.y):
		ctx.direction = Vector2.RIGHT if delta.x > 0.0 else Vector2.LEFT
	elif delta.y != 0.0:
		ctx.direction = Vector2.DOWN if delta.y > 0.0 else Vector2.UP
	else:
		ctx.direction = Vector2.ZERO
	ctx.from_behavior = TileBehaviorReader.get_behavior_at_world(from_world)
	ctx.to_behavior = TileBehaviorReader.get_behavior_at_world(to_world)
	return ctx


## Solo despacha a handlers. NO lee colisión ni altura.
static func can_enter(ctx: TileBehaviorContext) -> bool:
	var from_h: TileBehaviorHandler = get_handler(ctx.from_behavior)
	if not from_h.can_enter(ctx):
		return false
	return get_handler(ctx.to_behavior).can_enter(ctx)


static func on_landed(ctx: TileBehaviorContext) -> void:
	get_handler(ctx.to_behavior).on_landed(ctx)


static func on_step_start(ctx: TileBehaviorContext) -> void:
	get_handler(ctx.from_behavior).on_step_start(ctx)
	get_handler(ctx.to_behavior).on_step_start(ctx)

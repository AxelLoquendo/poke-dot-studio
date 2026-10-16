extends RefCounted
class_name Party

const MAX_SIZE: int = 6

var members: Array[Pokemon] = []


func size() -> int:
	return members.size()


func is_full() -> bool:
	return members.size() >= MAX_SIZE


func get_at(index: int) -> Pokemon:
	if index < 0 or index >= members.size():
		return null
	return members[index]


func add(mon: Pokemon) -> bool:
	if mon == null or is_full():
		return false
	members.append(mon)
	return true


func remove_at(index: int) -> Pokemon:
	if index < 0 or index >= members.size():
		return null
	var mon: Pokemon = members[index]
	members.remove_at(index)
	return mon


func swap(a: int, b: int) -> void:
	if a < 0 or b < 0 or a >= members.size() or b >= members.size():
		return
	var tmp: Pokemon = members[a]
	members[a] = members[b]
	members[b] = tmp


func to_array() -> Array:
	var out: Array = []
	for mon: Pokemon in members:
		out.append(mon.to_dict())
	return out


static func from_array(rows: Array) -> Party:
	var party: Party = Party.new()
	for row: Variant in rows:
		if row is Dictionary:
			party.members.append(Pokemon.from_dict(row))
	return party

class_name MapValidator
extends RefCounted


const SPAWN_POSITION := Vector2i(1, 1)


func is_valid(map_data: MapData) -> bool:
	if map_data == null:
		return false

	if not map_data.is_inside(
		SPAWN_POSITION.x,
		SPAWN_POSITION.y
	):
		return false

	if map_data.get_cell(
		SPAWN_POSITION.x,
		SPAWN_POSITION.y
	) != ".":
		return false

	return has_reachable_area(map_data)


func has_reachable_area(map_data: MapData) -> bool:
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []

	queue.append(SPAWN_POSITION)
	visited[SPAWN_POSITION] = true

	while not queue.is_empty():

		var current: Vector2i = queue.pop_front()

		var directions := [
			Vector2i.UP,
			Vector2i.DOWN,
			Vector2i.LEFT,
			Vector2i.RIGHT
		]

		for direction in directions:

			var next_cell: Vector2i = (
				current + direction
			)

			if not map_data.is_inside(
				next_cell.x,
				next_cell.y
			):
				continue

			if visited.has(next_cell):
				continue

			if map_data.get_cell(
				next_cell.x,
				next_cell.y
			) != ".":
				continue

			visited[next_cell] = true
			queue.append(next_cell)

	return visited.size() > 1
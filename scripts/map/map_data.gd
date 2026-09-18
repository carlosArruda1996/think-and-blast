class_name MapData
extends RefCounted

var width: int
var height: int

var cells: Array[String] = []

func _init(map_width: int, map_height: int):
	width = map_width
	height = map_height
	
	for y in range(height):
		cells.append("".repeat(width))


func get_cell(x: int, y: int) -> String:
	if not is_inside(x, y):
		return ""
	
	return cells[y][x]


func set_cell(x: int, y: int, value: String):
	if not is_inside(x, y):
		return
	
	var row: String = cells[y]
	row = row.substr(0, x) + value + row.substr(x + 1)
	cells[y] = row


func is_inside(x: int, y: int) -> bool:
	return (
		x >= 0
		and x < width
		and y >= 0
		and y < height
	)
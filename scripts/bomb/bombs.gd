extends Node2D

const CELL_SIZE: int = 32

var fuse_time: float = 3.0
var explosion_range: int = 2

var timer: float = 0.0
var exploded: bool = false
var explosion_cells: Array[Vector2i] = []


func _ready():
	queue_redraw()


func _process(delta):
	if exploded:
		return

	timer += delta

	if timer >= fuse_time:
		explode()


# ============================================================
# CONFIGURAÇÃO
# ============================================================

func setup(config: LevelConfig):
	if config == null:
		return

	fuse_time = config.FUSE_TIME
	explosion_range = config.EXPLOSION_RANGE


# ============================================================
# EXPLOSÃO
# ============================================================

func explode():
	if exploded:
		return

	exploded = true

	print("💥 BOMBA EXPLODIU!")

	calculate_explosion()

	apply_explosion_damage()

	queue_redraw()

	await get_tree().create_timer(0.35).timeout

	queue_free()


func calculate_explosion():
	explosion_cells.clear()

	var origin_x = floori(position.x / CELL_SIZE)
	var origin_y = floori(position.y / CELL_SIZE)

	var origin = Vector2i(origin_x, origin_y)

	# Centro da explosão
	explosion_cells.append(origin)

	# Quatro direções
	check_direction(origin, Vector2i.UP)
	check_direction(origin, Vector2i.DOWN)
	check_direction(origin, Vector2i.LEFT)
	check_direction(origin, Vector2i.RIGHT)


func check_direction(origin: Vector2i, direction: Vector2i):
	var level = get_tree().get_first_node_in_group("level")

	if level == null:
		return

	for distance in range(1, explosion_range + 1):

		var cell = origin + direction * distance

		var cell_type = level.get_map_cell(cell.x, cell.y)

		# Fora do mapa
		if cell_type == "":
			break

		# Parede indestrutível
		if cell_type == "#":
			break

		# Bloco destrutível
		if cell_type == "B":

			print("💥 Bloco destruído em: ", cell)

			level.set_map_cell(
				cell.x,
				cell.y,
				"."
			)

			explosion_cells.append(cell)

			break

		# Espaço livre
		explosion_cells.append(cell)


# ============================================================
# DANO
# ============================================================

func apply_explosion_damage():
	var level = get_tree().get_first_node_in_group("level")

	if level == null:
		return

	level.damage_player_in_explosion(explosion_cells)


# ============================================================
# DESENHO
# ============================================================

func _draw():

	if not exploded:

		# Corpo da bomba
		draw_circle(
			Vector2.ZERO,
			10.0,
			Color(0.05, 0.05, 0.05)
		)

		# Pavio
		draw_line(
			Vector2(0, -10),
			Vector2(0, -15),
			Color(0.8, 0.5, 0.1),
			3.0
		)

		# Faísca
		draw_circle(
			Vector2(0, -16),
			2.0,
			Color(1.0, 0.2, 0.1)
		)

	else:

		# Desenha cada célula atingida pela explosão
		for cell in explosion_cells:

			var local_position = Vector2(
				cell.x * CELL_SIZE + CELL_SIZE / 2,
				cell.y * CELL_SIZE + CELL_SIZE / 2
			) - position

			draw_rect(
				Rect2(
					local_position - Vector2(12, 12),
					Vector2(24, 24)
				),
				Color(1.0, 0.45, 0.05)
			)
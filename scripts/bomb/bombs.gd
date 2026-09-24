extends Node2D


# ============================================================
# CONFIGURAÇÕES
# ============================================================

const CELL_SIZE: int = 32


# ============================================================
# ESTADO
# ============================================================

var fuse_time: float = 3.0
var explosion_range: int = 2

var timer: float = 0.0

var exploded: bool = false

var explosion_cells: Array[Vector2i] = []


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready():

	add_to_group("bomb")

	queue_redraw()


# ============================================================
# CONTADOR
# ============================================================

func _process(delta: float):

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
# REAÇÃO EM CADEIA
# ============================================================

func trigger_chain_reaction():

	if exploded:
		return

	print(
		"💥 REAÇÃO EM CADEIA! Bomba atingida."
	)

	explode()


# ============================================================
# EXPLODIR
# ============================================================

func explode():

	if exploded:
		return

	exploded = true

	print(
		"💥 BOMBA EXPLODIU!"
	)

	calculate_explosion()

	apply_explosion_damage()

	queue_redraw()

	await get_tree().create_timer(
		0.35
	).timeout

	queue_free()


# ============================================================
# CALCULAR EXPLOSÃO
# ============================================================

func calculate_explosion():

	explosion_cells.clear()

	var origin_x: int = floori(
		position.x / CELL_SIZE
	)

	var origin_y: int = floori(
		position.y / CELL_SIZE
	)

	var origin := Vector2i(
		origin_x,
		origin_y
	)

	explosion_cells.append(
		origin
	)

	check_direction(
		origin,
		Vector2i.UP
	)

	check_direction(
		origin,
		Vector2i.DOWN
	)

	check_direction(
		origin,
		Vector2i.LEFT
	)

	check_direction(
		origin,
		Vector2i.RIGHT
	)


# ============================================================
# CALCULAR DIREÇÃO
# ============================================================

func check_direction(
	origin: Vector2i,
	direction: Vector2i
):

	var level = get_tree().get_first_node_in_group(
		"level"
	)

	if level == null:
		return

	for distance in range(
		1,
		explosion_range + 1
	):

		var cell := origin + direction * distance

		var cell_type: String = level.get_map_cell(
			cell.x,
			cell.y
		)


		# --------------------------------------------------------
		# FORA DO MAPA
		# --------------------------------------------------------

		if cell_type == "":
			break


		# --------------------------------------------------------
		# PAREDE INDESTRUTÍVEL
		# --------------------------------------------------------

		if cell_type == "#":
			break


		# --------------------------------------------------------
		# OUTRA BOMBA
		# --------------------------------------------------------

		trigger_bomb_at_cell(
			cell
		)


		# --------------------------------------------------------
		# BLOCO DESTRUTÍVEL
		# --------------------------------------------------------

		if cell_type == "B":

			print(
				"💥 Bloco destruído em: ",
				cell
			)

			level.set_map_cell(
				cell.x,
				cell.y,
				"."
			)

			explosion_cells.append(
				cell
			)

			level.try_spawn_power_up(
				cell
			)

			# O bloco interrompe a explosão.
			break


		# --------------------------------------------------------
		# CÉLULA LIVRE
		# --------------------------------------------------------

		explosion_cells.append(
			cell
		)


# ============================================================
# ATIVAR BOMBA ATINGIDA
# ============================================================

func trigger_bomb_at_cell(
	cell: Vector2i
):

	var bombs := get_tree().get_nodes_in_group(
		"bomb"
	)

	for bomb in bombs:

		if bomb == self:
			continue

		if not is_instance_valid(bomb):
			continue

		if bomb.exploded:
			continue

		var bomb_cell := Vector2i(
			floori(
				bomb.position.x / CELL_SIZE
			),
			floori(
				bomb.position.y / CELL_SIZE
			)
		)

		if bomb_cell == cell:

			print(
				"💣 Bomba atingida pela explosão!"
			)

			bomb.trigger_chain_reaction()


# ============================================================
# DANO
# ============================================================

func apply_explosion_damage():

	var level = get_tree().get_first_node_in_group(
		"level"
	)

	if level == null:
		return

	level.damage_player_in_explosion(
		explosion_cells
	)


# ============================================================
# DESENHO
# ============================================================

func _draw():

	if not exploded:

		draw_circle(
			Vector2.ZERO,
			10.0,
			Color(
				0.05,
				0.05,
				0.05
			)
		)

		draw_line(
			Vector2(0, -10),
			Vector2(0, -15),
			Color(
				0.8,
				0.5,
				0.1
			),
			3.0
		)

		draw_circle(
			Vector2(0, -16),
			2.0,
			Color(
				1.0,
				0.2,
				0.1
			)
		)

		return


	for cell in explosion_cells:

		var local_position := Vector2(
			cell.x * CELL_SIZE + CELL_SIZE / 2,
			cell.y * CELL_SIZE + CELL_SIZE / 2
		) - position

		draw_rect(
			Rect2(
				local_position - Vector2(12, 12),
				Vector2(24, 24)
			),
			Color(
				1.0,
				0.45,
				0.05
			)
		)
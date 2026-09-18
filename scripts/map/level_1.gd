extends Node2D


# =========================================================
# CONFIGURAÇÃO DO NÍVEL
# =========================================================

var config := LevelConfig.new()


# =========================================================
# CONFIGURAÇÕES LOCAIS DO LEVEL
# =========================================================

const CELL_SIZE: int = 32

const PLAYER_SCENE = preload(
	"res://scenes/player/player.tscn"
)


# =========================================================
# ESTADO DO NÍVEL
# =========================================================

var lives: int

var map_data: MapData

var spawn_cell := Vector2i(1, 1)


# =========================================================
# INICIALIZAÇÃO
# =========================================================
func _ready():
	add_to_group("level")
	lives = config.MAX_LIVES
	generate_valid_map()
	queue_redraw()
	spawn_player()
	spawn_test_power_up()


# =========================================================
# MAPA
# =========================================================

func generate_valid_map():

	var generator = MapGenerator.new()
	var validator = MapValidator.new()

	var attempts: int = 0
	var max_attempts: int = 100

	while attempts < max_attempts:

		attempts += 1

		var generated_map = generator.generate(config)

		if validator.is_valid(generated_map):

			map_data = generated_map

			print(
				"🗺️ Mapa válido gerado na tentativa: ",
				attempts
			)

			return

	print(
		"❌ Não foi possível gerar "
		+ "um mapa válido."
	)


func set_map_cell(
	x: int,
	y: int,
	value: String
):

	if map_data == null:
		return

	map_data.set_cell(
		x,
		y,
		value
	)

	refresh_map()


func get_map_cell(
	x: int,
	y: int
) -> String:

	if map_data == null:
		return ""

	return map_data.get_cell(
		x,
		y
	)


func refresh_map():

	queue_redraw()


# =========================================================
# JOGADOR
# =========================================================

func spawn_player():

	var player = PLAYER_SCENE.instantiate()

	player.add_to_group("player")

	player.position = cell_to_world(
		spawn_cell
	)

	add_child(player)


func cell_to_world(
	cell: Vector2i
) -> Vector2:

	return Vector2(
		cell.x * CELL_SIZE
		+ CELL_SIZE / 2,

		cell.y * CELL_SIZE
		+ CELL_SIZE / 2
	)


# =========================================================
# MOVIMENTO
# =========================================================

func is_position_walkable(
	position: Vector2
) -> bool:

	if map_data == null:
		return false

	var cell_x = floori(
		position.x / CELL_SIZE
	)

	var cell_y = floori(
		position.y / CELL_SIZE
	)

	if (
		cell_x < 0
		or cell_x >= config.MAP_WIDTH
	):
		return false

	if (
		cell_y < 0
		or cell_y >= config.MAP_HEIGHT
	):
		return false

	var cell_type = map_data.get_cell(
		cell_x,
		cell_y
	)

	if cell_type != ".":
		return false

	# Verifica se existe uma bomba nessa célula
	if is_cell_occupied_by_bomb(
		Vector2i(
			cell_x,
			cell_y
		)
	):
		return false

	return true


# =========================================================
# BOMBA
# =========================================================

func is_cell_occupied_by_bomb(
	cell: Vector2i
) -> bool:

	for bomb in get_tree().get_nodes_in_group(
		"bomb"
	):

		if not is_instance_valid(bomb):
			continue

		var bomb_cell = Vector2i(
			floori(
				bomb.position.x
				/ CELL_SIZE
			),

			floori(
				bomb.position.y
				/ CELL_SIZE
			)
		)

		if bomb_cell == cell:
			return true

	return false


# =========================================================
# DANO DA EXPLOSÃO
# =========================================================

func damage_player_in_explosion(
	explosion_cells: Array[Vector2i]
):

	var player = get_tree().get_first_node_in_group(
		"player"
	)

	if player == null:
		return

	if player.is_dead:
		return

	var player_cell = Vector2i(
		floori(
			player.position.x
			/ CELL_SIZE
		),

		floori(
			player.position.y
			/ CELL_SIZE
		)
	)

	if player_cell in explosion_cells:

		player.die()


# =========================================================
# SISTEMA DE VIDAS
# =========================================================

func player_lost_life():

	lives -= 1

	print("❤️ VIDA PERDIDA!")

	print(
		"❤️ Vidas restantes: ",
		lives
	)

	if lives > 0:

		respawn_player()

	else:

		print(
			"💀 TODAS AS VIDAS "
			+ "FORAM PERDIDAS!"
		)

		restart_level()


func respawn_player():

	var player = get_tree().get_first_node_in_group(
		"player"
	)

	if player == null:
		return

	player.reset_after_death(
		cell_to_world(
			spawn_cell
		)
	)


func restart_level():

	print(
		"🔄 Reiniciando nível..."
	)

	lives = config.MAX_LIVES

	# Remove bombas existentes
	for bomb in get_tree().get_nodes_in_group(
		"bomb"
	):

		if is_instance_valid(bomb):
			bomb.queue_free()

	# Gera um novo mapa através
	# do Generator + Validator
	generate_valid_map()

	refresh_map()

	var player = get_tree().get_first_node_in_group(
		"player"
	)

	if player != null:

		player.is_dead = false
		player.bomb_active = false

		player.position = cell_to_world(
			spawn_cell
		)


# =========================================================
# DESENHO
# =========================================================

func _draw():

	if map_data == null:
		return

	for y in range(config.MAP_HEIGHT):

		for x in range(config.MAP_WIDTH):

			var cell_type = map_data.get_cell(
				x,
				y
			)

			draw_cell(
				x,
				y,
				cell_type
			)


func draw_cell(
	x: int,
	y: int,
	cell_type: String
):

	var position = Vector2(
		x * CELL_SIZE,
		y * CELL_SIZE
	)

	var rectangle = Rect2(
		position,
		Vector2(
			CELL_SIZE,
			CELL_SIZE
		)
	)

	var cell_color

	match cell_type:

		"#":

			cell_color = Color(
				0.08,
				0.08,
				0.08
			)

		"B":

			cell_color = Color(
				0.45,
				0.30,
				0.15
			)

		".":

			cell_color = Color(
				0.16,
				0.16,
				0.16
			)

		_:

			cell_color = Color(
				1.0,
				0.0,
				1.0
			)

	draw_rect(
		rectangle,
		cell_color
	)

	draw_line(
		position,
		position + Vector2(
			CELL_SIZE,
			0
		),
		Color(
			0.25,
			0.25,
			0.25
		),
		1.0
	)

	draw_line(
		position,
		position + Vector2(
			0,
			CELL_SIZE
		),
		Color(
			0.25,
			0.25,
			0.25
		),
		1.0
	)

func spawn_test_power_up():

	var power_up_scene = preload(
		"res://scenes/items/PowerUp.tscn"
	)

	var power_up = power_up_scene.instantiate()

	power_up.position = cell_to_world(
		Vector2i(3, 1)
	)

	add_child(power_up)

	print(
		"🎴 Power-up de teste criado."
	)

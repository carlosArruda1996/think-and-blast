extends Node2D


# ============================================================
# CONFIGURAÇÃO
# ============================================================

var config := LevelConfig.new()


# ============================================================
# CONSTANTES
# ============================================================

const CELL_SIZE: int = 32

const PLAYER_SCENE = preload(
	"res://scenes/player/player.tscn"
)

const POWER_UP_SCENE = preload(
	"res://scenes/items/PowerUp.tscn"
)


# ============================================================
# ESTADO DO NÍVEL
# ============================================================

var lives: int
var map_data: MapData
var spawn_cell := Vector2i(1, 1)

var power_ups_spawned: int = 0


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready():

	add_to_group("level")

	lives = config.MAX_LIVES

	generate_valid_map()

	queue_redraw()

	spawn_player()


# ============================================================
# GERAR MAPA VÁLIDO
# ============================================================

func generate_valid_map():

	var generator := MapGenerator.new()
	var validator := MapValidator.new()

	var attempts: int = 0
	var max_attempts: int = 100

	power_ups_spawned = 0

	while attempts < max_attempts:

		attempts += 1

		var generated_map: MapData = generator.generate(config)

		if validator.is_valid(generated_map):

			map_data = generated_map

			print(
				"🗺️ Mapa válido gerado na tentativa: ",
				attempts
			)

			return

	print(
		"❌ Não foi possível gerar um mapa válido."
	)


# ============================================================
# ALTERAR CÉLULA DO MAPA
# ============================================================

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


# ============================================================
# OBTER CÉLULA DO MAPA
# ============================================================

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


# ============================================================
# ATUALIZAR MAPA
# ============================================================

func refresh_map():

	queue_redraw()


# ============================================================
# POWER-UPS
# ============================================================

func try_spawn_power_up(
	cell: Vector2i
):

	if power_ups_spawned >= config.POWER_UP_COUNT:

		print(
			"🎴 Limite de Power-Ups atingido: ",
			config.POWER_UP_COUNT
		)

		return


	var power_up = POWER_UP_SCENE.instantiate()

	if power_up == null:

		print(
			"❌ ERRO: PowerUp.tscn não pôde ser instanciado!"
		)

		return


	power_up.position = cell_to_world(cell)

	add_child(power_up)

	power_ups_spawned += 1

	print(
		"🎴 POWER-UP GERADO EM: ",
		cell
	)

	print(
		"🎴 Power-Ups no nível: ",
		power_ups_spawned,
		"/",
		config.POWER_UP_COUNT
	)


# ============================================================
# JOGADOR
# ============================================================

func spawn_player():

	var player = PLAYER_SCENE.instantiate()

	player.add_to_group("player")

	player.position = cell_to_world(
		spawn_cell
	)

	add_child(player)


# ============================================================
# CÉLULA → MUNDO
# ============================================================

func cell_to_world(
	cell: Vector2i
) -> Vector2:

	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE / 2,
		cell.y * CELL_SIZE + CELL_SIZE / 2
	)


# ============================================================
# MOVIMENTAÇÃO
# ============================================================

func is_position_walkable(
	position: Vector2
) -> bool:

	if map_data == null:
		return false

	var cell_x: int = floori(
		position.x / CELL_SIZE
	)

	var cell_y: int = floori(
		position.y / CELL_SIZE
	)

	if cell_x < 0:
		return false

	if cell_x >= config.MAP_WIDTH:
		return false

	if cell_y < 0:
		return false

	if cell_y >= config.MAP_HEIGHT:
		return false

	var cell_type: String = map_data.get_cell(
		cell_x,
		cell_y
	)

	if cell_type != ".":
		return false

	if is_cell_occupied_by_bomb(
		Vector2i(
			cell_x,
			cell_y
		)
	):
		return false

	return true


# ============================================================
# VERIFICAR BOMBA NA CÉLULA
# ============================================================

func is_cell_occupied_by_bomb(
	cell: Vector2i
) -> bool:

	var bombs := get_tree().get_nodes_in_group(
		"bomb"
	)

	for bomb in bombs:

		if not is_instance_valid(bomb):
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
			return true

	return false


# ============================================================
# DANO AO JOGADOR
# ============================================================

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

	var player_cell := Vector2i(
		floori(
			player.position.x / CELL_SIZE
		),
		floori(
			player.position.y / CELL_SIZE
		)
	)

	if player_cell in explosion_cells:

		player.die()


# ============================================================
# PERDEU UMA VIDA
# ============================================================

func player_lost_life():

	lives -= 1

	print(
		"❤️ VIDA PERDIDA!"
	)

	print(
		"❤️ Vidas restantes: ",
		lives
	)

	if lives > 0:

		respawn_player()

	else:

		print(
			"💀 TODAS AS VIDAS FORAM PERDIDAS!"
		)

		restart_level()


# ============================================================
# RESSUSCITAR
# ============================================================

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


# ============================================================
# REINICIAR NÍVEL
# ============================================================

func restart_level():

	print(
		"🔄 Reiniciando nível..."
	)

	lives = config.MAX_LIVES

	for bomb in get_tree().get_nodes_in_group(
		"bomb"
	):

		if is_instance_valid(bomb):
			bomb.queue_free()

	for power_up in get_tree().get_nodes_in_group(
		"power_up"
	):

		if is_instance_valid(power_up):
			power_up.queue_free()

	generate_valid_map()

	refresh_map()

	var player = get_tree().get_first_node_in_group(
		"player"
	)

	if player != null:

		player.is_dead = false

		player.bombs_used = 0

		player.position = cell_to_world(
			spawn_cell
		)


# ============================================================
# DESENHAR MAPA
# ============================================================

func _draw():

	if map_data == null:
		return

	for y in range(config.MAP_HEIGHT):

		for x in range(config.MAP_WIDTH):

			var cell_type: String = map_data.get_cell(
				x,
				y
			)

			draw_cell(
				x,
				y,
				cell_type
			)


# ============================================================
# DESENHAR CÉLULA
# ============================================================

func draw_cell(
	x: int,
	y: int,
	cell_type: String
):

	var position := Vector2(
		x * CELL_SIZE,
		y * CELL_SIZE
	)

	var rectangle := Rect2(
		position,
		Vector2(
			CELL_SIZE,
			CELL_SIZE
		)
	)

	var cell_color: Color

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
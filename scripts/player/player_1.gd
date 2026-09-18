extends CharacterBody2D


# ============================================================
# CONFIGURAÇÕES TÉCNICAS
# ============================================================

const SPEED: float = 120.0
const PLAYER_RADIUS: float = 10.0
const CELL_SIZE: int = 32

const BOMB_SCENE = preload(
	"res://scenes/bomb/bombs.tscn"
)


# ============================================================
# ESTADO DO JOGADOR
# ============================================================

var is_dead: bool = false

# Quantidade máxima de bombas que o jogador pode ter
var bombs_max: int = 1

# Quantidade de bombas atualmente colocadas
var bombs_used: int = 0


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready():

	var level = get_tree().get_first_node_in_group("level")

	if level != null:

		bombs_max = level.config.INITIAL_BOMBS

	bombs_used = 0

	queue_redraw()

	print(
		"💣 Bombas disponíveis: ",
		bombs_max
	)


# ============================================================
# MOVIMENTO
# ============================================================

func _physics_process(delta):

	if is_dead:
		return

	var direction = Vector2.ZERO


	if Input.is_action_pressed("ui_up"):

		direction = Vector2.UP

	elif Input.is_action_pressed("ui_down"):

		direction = Vector2.DOWN

	elif Input.is_action_pressed("ui_left"):

		direction = Vector2.LEFT

	elif Input.is_action_pressed("ui_right"):

		direction = Vector2.RIGHT


	if direction == Vector2.ZERO:

		velocity = Vector2.ZERO

	else:

		var movement = direction * SPEED * delta

		var new_position = position + movement

		var level = get_tree().get_first_node_in_group("level")


		if level != null:

			var current_cell = Vector2i(
				floori(position.x / CELL_SIZE),
				floori(position.y / CELL_SIZE)
			)

			var target_cell = Vector2i(
				floori(new_position.x / CELL_SIZE),
				floori(new_position.y / CELL_SIZE)
			)


			if target_cell == current_cell:

				position = new_position

			else:

				if level.is_position_walkable(new_position):

					position = new_position


	# ========================================================
	# BOMBA
	# ========================================================

	if Input.is_action_just_pressed("place_bomb"):

		place_bomb()


# ============================================================
# COLOCAR BOMBA
# ============================================================

func place_bomb():

	if is_dead:
		return


	# --------------------------------------------------------
	# Verificar limite de bombas
	# --------------------------------------------------------

	if bombs_used >= bombs_max:

		print(
			"💣 Limite de bombas atingido: ",
			bombs_used,
			"/",
			bombs_max
		)

		return


	# --------------------------------------------------------
	# Descobrir nível
	# --------------------------------------------------------

	var level = get_tree().get_first_node_in_group("level")

	if level == null:
		return


	# --------------------------------------------------------
	# Criar bomba
	# --------------------------------------------------------

	var bomb = BOMB_SCENE.instantiate()


	# --------------------------------------------------------
	# Configuração da bomba
	# --------------------------------------------------------

	bomb.setup(level.config)


	# --------------------------------------------------------
	# Descobrir célula atual
	# --------------------------------------------------------

	var cell_x = floori(
		position.x / CELL_SIZE
	)

	var cell_y = floori(
		position.y / CELL_SIZE
	)


	# --------------------------------------------------------
	# Posicionar bomba no centro da célula
	# --------------------------------------------------------

	bomb.position = Vector2(
		cell_x * CELL_SIZE + CELL_SIZE / 2,
		cell_y * CELL_SIZE + CELL_SIZE / 2
	)


	# --------------------------------------------------------
	# Registrar bomba
	# --------------------------------------------------------

	bomb.add_to_group("bomb")

	get_parent().add_child(bomb)


	# --------------------------------------------------------
	# Atualizar contador
	# --------------------------------------------------------

	bombs_used += 1


	print(
		"💣 Bomba colocada em: ",
		cell_x,
		", ",
		cell_y
	)

	print(
		"💣 Bombas em uso: ",
		bombs_used,
		"/",
		bombs_max
	)


	# --------------------------------------------------------
	# Detectar quando a bomba desaparecer
	# --------------------------------------------------------

	bomb.tree_exited.connect(
		_on_bomb_removed
	)


# ============================================================
# BOMBA REMOVIDA
# ============================================================

func _on_bomb_removed():

	bombs_used = max(
		0,
		bombs_used - 1
	)


	print(
		"💥 Bomba removida."
	)

	print(
		"💣 Bombas em uso: ",
		bombs_used,
		"/",
		bombs_max
	)


# ============================================================
# MORTE
# ============================================================

func die():

	if is_dead:
		return


	is_dead = true

	velocity = Vector2.ZERO

	print(
		"💀 JOGADOR MORREU!"
	)


	var level = get_tree().get_first_node_in_group("level")

	if level != null:

		level.player_lost_life()


# ============================================================
# RENASCIMENTO
# ============================================================

func reset_after_death(respawn_position: Vector2):

	position = respawn_position

	is_dead = false

	bombs_used = 0

	print(
		"❤️ Jogador renasceu."
	)

	print(
		"💣 Bombas disponíveis: ",
		bombs_max
	)

	queue_redraw()


# ============================================================
# DESENHO
# ============================================================

func _draw():

	if is_dead:
		return


	draw_circle(
		Vector2.ZERO,
		PLAYER_RADIUS,
		Color(0.2, 0.8, 0.4)
	)
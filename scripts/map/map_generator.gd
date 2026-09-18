class_name MapGenerator
extends RefCounted


# =========================================================
# GERAÇÃO DO MAPA
# =========================================================

func generate(config: LevelConfig) -> MapData:

	if config == null:
		return null

	var map_data = MapData.new(
		config.MAP_WIDTH,
		config.MAP_HEIGHT
	)

	generate_base_map(
		map_data
	)

	generate_destructible_blocks(
		map_data
	)

	return map_data


# =========================================================
# MAPA BASE
# =========================================================

func generate_base_map(
	map_data: MapData
):

	for y in range(map_data.height):

		for x in range(map_data.width):

			# Borda externa
			if (
				x == 0
				or x == map_data.width - 1
				or y == 0
				or y == map_data.height - 1
			):

				map_data.set_cell(
					x,
					y,
					"#"
				)

			# Paredes internas fixas
			elif (
				x % 2 == 0
				and y % 2 == 0
			):

				map_data.set_cell(
					x,
					y,
					"#"
				)

			# Espaço livre
			else:

				map_data.set_cell(
					x,
					y,
					"."
				)


# =========================================================
# BLOCOS DESTRUTÍVEIS
# =========================================================

func generate_destructible_blocks(
	map_data: MapData
):

	const DESTRUCTIBLE_BLOCK_CHANCE: float = 0.45

	for y in range(
		1,
		map_data.height - 1
	):

		for x in range(
			1,
			map_data.width - 1
		):

			# Só podemos colocar um bloco
			# em uma célula livre
			if map_data.get_cell(x, y) != ".":
				continue

			# Mantém a área inicial segura
			if is_spawn_safe_cell(
				x,
				y
			):
				continue

			# Sorteia a criação do bloco
			if randf() < DESTRUCTIBLE_BLOCK_CHANCE:

				map_data.set_cell(
					x,
					y,
					"B"
				)


# =========================================================
# ÁREA SEGURA DO SPAWN
# =========================================================

func is_spawn_safe_cell(
	x: int,
	y: int
) -> bool:

	if x == 1 and y == 1:
		return true

	if x == 2 and y == 1:
		return true

	if x == 1 and y == 2:
		return true

	return false
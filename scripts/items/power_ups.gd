class_name PowerUp
extends Area2D

enum PowerUpType {
	BOMB_UP
}


@export var power_up_type: PowerUpType = PowerUpType.BOMB_UP


func _ready():
	add_to_group("power_up")

	body_entered.connect(
		_on_body_entered
	)

	queue_redraw()


func _on_body_entered(body):

	if not body.is_in_group("player"):
		return

	apply_power_up(body)

	queue_free()


func apply_power_up(player):

	match power_up_type:

		PowerUpType.BOMB_UP:

			player.bombs_max += 1

			print("🎴 POWER-UP: +1 BOMBA!")
			print("💣 Bombas máximas: ", player.bombs_max)

func _draw():

	draw_rect(
		Rect2(
			Vector2(-10, -14),
			Vector2(20, 28)
		),
		Color(0.9, 0.9, 0.9)
	)

	draw_circle(
		Vector2(0, 2),
		6.0,
		Color(0.05, 0.05, 0.05)
	)

	draw_line(
		Vector2(0, -4),
		Vector2(0, -9),
		Color(0.8, 0.5, 0.1),
		2.0
	)

	draw_circle(
		Vector2(0, -10),
		1.5,
		Color(1.0, 0.2, 0.1)
	)
extends CharacterBody2D

@export var speed: float = 400.0  # Prędkość przeciwnika
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # Pobranie referencji do sprite'a
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D  # Pobranie referencji do kolizji
var target: Node2D = null  # Referencja do gracza

func _ready() -> void:
	# Znalezienie gracza w grupie "player"
	target = get_tree().get_first_node_in_group("player")
	if target == null:
		print("Nie znaleziono gracza w grupie 'player'!")

func _process(delta: float) -> void:
	if target:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		# Obracanie przeciwnika tylko w lewo/prawo
		if direction.x > 0:
			sprite.flip_h = false  # Patrzy w prawo
			collision_shape.scale.x = 1  # Kolizja w normalnej pozycji
		elif direction.x < 0:
			sprite.flip_h = true  # Patrzy w lewo
			collision_shape.scale.x = -1  # Odbicie kolizji w lewo

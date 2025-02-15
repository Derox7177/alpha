extends Area2D

@export var speed: float = 200.0  # Prędkość kuli ognia
@export var damage: int = 30  # Obrażenia zadawane przeciwnikom
@export var max_distance: float = 200.0  # Maksymalny dystans lotu
@export var lifetime: float = 2.0  # Czas życia kuli ognia (sekundy)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # Pobranie referencji do animacji
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D  # Pobranie kolizji

var start_position: Vector2  # Pozycja startowa Fireballa
var direction: Vector2 = Vector2.RIGHT  # Domyślny kierunek lotu

func _ready():
	start_position = global_position  # Zapamiętaj pozycję startową
	connect("body_entered", _on_body_entered)  # Połączenie wykrycia kolizji

	# Sprawdzenie, czy Fireball wykrywa kolizje
	print("🔥 Fireball gotowy, monitoring:", monitoring)

	# Automatyczne usunięcie Fireballa po czasie (lifetime)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	# Przemieszczanie kuli ognia do przodu
	global_position += direction * speed * delta

	# Jeśli kula ognia przeleci więcej niż max_distance, znika
	if global_position.distance_to(start_position) > max_distance:
		print("🔥 Fireball przekroczył maksymalny dystans i znika.")
		queue_free()

func _on_area_entered(area: Area2D):
	print("🔥 Fireball trafił w:", area.name)

	if area.is_in_group("enemy"):  # Jeśli trafiono wroga
		print("🎯 Fireball trafił wroga!")

		if area.has_method("take_damage"):
			area.take_damage(damage)  # Zadaj obrażenia
			print("🔥 Fireball zadał", damage, "obrażeń wrogowi!")
		else:
			print("❌ Wróg nie ma funkcji take_damage()!")

		queue_free()  # Zniszcz kulę ognia po trafieniu

func set_direction(new_direction: Vector2):
	direction = new_direction
	
func _on_body_entered(body: Node):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()


extends Area2D

# Eksportowane zmienne – modyfikowalne w edytorze:
@export var speed: float = 400.0         # Prędkość fireballa
@export var damage: int = 30             # Obrażenia zadawane przeciwnikom
@export var max_distance: float = 300.0    # Maksymalny dystans, jaki fireball może przebyć
@export var lifetime: float = 3.0          # Czas życia fireballa w sekundach

# Pobieramy referencje do węzłów podrzędnych:
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D      # Animacja fireballa
@onready var collision_shape: CollisionShape2D = $CollisionShape2D  # Kształt kolizji

# Zmienne wewnętrzne:
var start_position: Vector2               # Zapamiętuje początkową pozycję fireballa
var direction: Vector2 = Vector2.RIGHT    # Kierunek ruchu (domyślnie w prawo)
var has_hit_enemy: bool = false  # 🔹 Flaga - sprawdza, czy Lighting już trafił wroga

func _ready():
	# 🔹 Ustawienie sygnału wykrywania kolizji
	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)

	# 🔹 Uruchomienie animacji
	print("⚡ Błyskawica gotowa!")
	sprite.play("default")  
	sprite.animation_finished.connect(_on_animation_finished)

	# 🔹 Automatyczne usunięcie po czasie
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_animation_finished():
	print("⚡ Animacja zakończona, błyskawica znika.")
	queue_free()  

func _on_area_entered(area: Area2D):
	if area.is_in_group("enemy") and not has_hit_enemy:  # Sprawdzamy, czy Lighting już trafił wroga
		print("🎯 Lighting trafił wroga:", area.name)
		if area.has_method("take_damage"):
			area.take_damage(damage)  
			print("🔥 Lighting zadał", damage, "obrażeń wrogowi!")
		else:
			print("❌ Wróg nie ma funkcji take_damage()!")
		has_hit_enemy = true  # 🔹 Oznaczamy, że wróg został trafiony (nie znikamy od razu!)

func _on_body_entered(body: Node):
	if body.is_in_group("enemy") and not has_hit_enemy:
		print("🎯 Lighting trafił wroga (body):", body.name)
		if body.has_method("take_damage"):
			body.take_damage(damage)  
			print("🔥 Lighting zadał", damage, "obrażeń wrogowi!")
		else:
			print("❌ Wróg nie ma funkcji take_damage()!")
		has_hit_enemy = true  # 🔹 Oznaczamy, że wróg został trafiony (nie znikamy od razu!)

func set_direction(new_direction: Vector2):
	direction = new_direction

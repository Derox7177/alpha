# Fireball.gd
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

func _ready():
	# Inicjalizacja fireballa:
	start_position = global_position                      # Zapamiętujemy początkową pozycję
	connect("body_entered", _on_body_entered)             # Podłączamy sygnał kolizji z ciałem
	print("🔥 Fireball gotowy, monitoring:", monitoring)  # Komunikat debugowy
	sprite.play("default")                                # Uruchamiamy animację "default"
	# Po upływie 'lifetime' fireball zostaje automatycznie usunięty:
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	# Aktualizacja pozycji fireballa:
	global_position += direction * speed * delta          # Przemieszczamy fireball
	# Jeśli fireball przekroczy maksymalny dystans, usuwamy go:
	if global_position.distance_to(start_position) > max_distance:
		print("🔥 Fireball przekroczył maksymalny dystans i znika.")
		queue_free()

func _on_area_entered(area: Area2D):
	# Funkcja wywoływana, gdy fireball wejdzie w kolizję z innym Area2D
	print("🔥 Fireball trafił w:", area.name)
	if area.is_in_group("enemy"):                         # Sprawdzamy, czy trafiony obiekt należy do grupy "enemy"
		print("🎯 Fireball trafił wroga!")
		if area.has_method("take_damage"):
			area.take_damage(damage)                      # Zadajemy obrażenia, jeśli metoda istnieje
			print("🔥 Fireball zadał", damage, "obrażeń wrogowi!")
		else:
			print("❌ Wróg nie ma funkcji take_damage()!")
		queue_free()                                      # Usuwamy fireball po trafieniu

func set_direction(new_direction: Vector2):
	# Ustawiamy kierunek ruchu fireballa na podstawie podanego wektora
	direction = new_direction
	
	# Ustawiamy flip_h – jeśli fireball leci w lewo (x < 0), sprite zostanie odbity poziomo
	sprite.flip_h = direction.x < 0
	
	# Zamiast flip_v, modyfikujemy skalę w osi Y, aby poprawnie odbić animację w pionie:
	# Jeśli kierunek wskazuje w dół (y > 0), ustawiamy scale.y na wartość ujemną,
	# co odwróci animację pionowo. Jeśli fireball leci do góry (y ≤ 0), scale.y pozostaje dodatnia.
	if direction.y > 0:
		sprite.scale.y = -abs(sprite.scale.y)
	else:
		sprite.scale.y = abs(sprite.scale.y)

func _on_body_entered(body: Node):
	# Obsługa kolizji, gdy fireball trafia w ciało (np. CharacterBody2D)
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

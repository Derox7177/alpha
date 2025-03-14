extends Node2D

@export var enemy_scene: PackedScene  # Scena przeciwnika
@onready var spawn_area: Area2D = $Area2D
@onready var spawn_timer: Timer = $Spawntime

func _ready():
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.start()

func _spawn_enemy():
	if enemy_scene == null:
		print("❌ Błąd: Nie przypisano sceny przeciwnika!")
		return
	
	# Pobieramy losową pozycję spawnu
	var spawn_position: Vector2 = _get_random_spawn_position()
	
	if spawn_position != Vector2.ZERO:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_position
		get_tree().current_scene.add_child(enemy)  # Dodanie do bieżącej sceny gry
		print("👾 Spawn przeciwnika na pozycji:", spawn_position)
	else:
		print("⚠️ Nie udało się znaleźć poprawnej pozycji dla przeciwnika!")

func _get_random_spawn_position() -> Vector2:
	if spawn_area and spawn_area.get_child_count() > 0:
		var shape: CollisionShape2D = spawn_area.get_child(0) as CollisionShape2D
		if shape and shape.shape is RectangleShape2D:
			var rect: RectangleShape2D = shape.shape
			var extents = rect.extents

			var random_x = randf_range(-extents.x, extents.x) + spawn_area.global_position.x
			var random_y = randf_range(-extents.y, extents.y) + spawn_area.global_position.y
			return Vector2(random_x, random_y)

	print("❌ Błąd: Nie znaleziono poprawnego CollisionShape2D!")
	return Vector2.ZERO

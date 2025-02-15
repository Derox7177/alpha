extends CharacterBody2D

@export var speed: float = 300.0  # Prędkość gracza
@export var atk: int = 10  # Siła ataku gracza
@export var hp: int = 100  # Punkty życia gracza
@export var attack_range: float = 100.0  # Zasięg ataku gracza

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D  # Pobranie referencji do animacji

var is_attacking: bool = false  # Flaga sprawdzająca, czy gracz atakuje

func _physics_process(delta: float) -> void:
	if is_attacking:  
		return  # Jeśli atak trwa, nie wykonuj ruchu

	var direction_x := Input.get_axis("left", "right")
	var direction_y := Input.get_axis("up", "down")
	
	var direction := Vector2(direction_x, direction_y)

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		anim.play("walk")  # Animacja chodzenia
	else:
		velocity = Vector2.ZERO
		anim.play("idle")  # Animacja bezczynności

	move_and_slide()

	# Atak lewym przyciskiem myszy
	if Input.is_action_just_pressed("mouse_left"):
		attack()

func attack():
	if is_attacking:  
		return  # Jeśli atak już trwa, nie odtwarzaj animacji ponownie

	is_attacking = true  # Ustawienie flagi ataku
	anim.play("attack")  # Odtworzenie animacji ataku

	# Sprawdzenie kolizji z przeciwnikiem w pobliżu
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is CharacterBody2D and global_position.distance_to(enemy.global_position) <= attack_range:
			enemy.take_damage(atk)  # Zadanie obrażeń przeciwnikowi
			print("Gracz zaatakował przeciwnika!")

	# Czekanie na zakończenie animacji ataku
	await anim.animation_finished  
	is_attacking = false  # Flaga wraca do false po zakończeniu ataku
	anim.play("idle")  # Powrót do idle

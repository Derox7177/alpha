extends CharacterBody2D

@export var speed: float = 300.0  # Prędkość gracza
@export var atk: int = 10  # Siła ataku gracza
@export var hp: int = 100  # Punkty życia gracza
@export var attack_range: float = 100.0  # Zasięg ataku gracza
@export var fireball_scene: PackedScene  # Wczytaj Fireball.tscn

@export var max_mana: int = 100  # Maksymalna ilość many
var mana: int = max_mana  # Aktualna ilość many
var fireball_cost: int = 10  # Koszt many do rzutu Fireballa

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D  # Pobranie referencji do animacji

var is_attacking: bool = false  # Flaga sprawdzająca, czy gracz atakuje
var fireball_cd: bool = false  # Cooldown Fireballa

func _ready():
	# Timer do regeneracji many (1 mana na sekundę)
	var mana_regen_timer = Timer.new()
	mana_regen_timer.wait_time = 1.0
	mana_regen_timer.autostart = true
	mana_regen_timer.one_shot = false
	mana_regen_timer.timeout.connect(_regenerate_mana)
	add_child(mana_regen_timer)

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

	# Sprawdzenie, czy gracz nacisnął przycisk ataku (normalny atak)
	if Input.is_action_just_pressed("mouse_left"):
		attack()

	# Sprawdzenie, czy gracz nacisnął `1` do Fireballa
	if Input.is_action_just_pressed("one") and not fireball_cd:
		cast_fireball()

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
	
func cast_fireball():
	if fireball_cd:  
		return

	# Sprawdzenie, czy gracz ma wystarczającą ilość many
	if mana < fireball_cost:
		print("❌ Brak many na Fireball!")
		return

	# Zużycie many
	mana -= fireball_cost
	print("🔥 Fireball rzucony! Pozostała mana:", mana)

	fireball_cd = true  # Ustawienie cooldownu
	is_attacking = true  # Blokowanie ruchu podczas rzutu Fireballa
	anim.play("attack2")  # Odtworzenie animacji ataku dystansowego

	await anim.animation_finished  # Poczekaj na zakończenie animacji

	if fireball_scene == null:
		print("❌ Błąd: fireball_scene nie jest przypisane!")
		fireball_cd = false  # Reset cooldownu, jeśli fireball nie jest dostępny
		is_attacking = false
		return

	var fireball = fireball_scene.instantiate() as Area2D
	fireball.global_position = global_position  # Ustawienie pozycji startowej

	# Ustaw kierunek zgodnie z orientacją gracza
	var direction = Vector2.RIGHT if not anim.flip_h else Vector2.LEFT
	fireball.set_direction(direction)  # Przekazanie kierunku do Fireballa

	get_parent().add_child(fireball)  # Dodanie kuli ognia do sceny

	print("🔥 Gracz użył Fireballa!")

	# Czekanie na cooldown Fireballa
	await get_tree().create_timer(2.0).timeout
	fireball_cd = false  # Reset cooldownu
	is_attacking = false  # Odblokowanie ataku i ruchu
	anim.play("idle")  # Powrót do idle

func _regenerate_mana():
	if mana < max_mana:
		mana += 1
		print("🔵 Mana zregenerowana:", mana)

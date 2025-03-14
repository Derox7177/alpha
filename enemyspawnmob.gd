extends CharacterBody2D

@export var speed: float = 100.0  # Prędkość ruchu
@export var chase_speed: float = 200.0  # Prędkość gonienia gracza
@export var atk: int = 5  # Siła ataku przeciwnika
@export var hp: int = 50  # Punkty życia przeciwnika
@export var attack_range: float = 100.0  # Zasięg ataku wroga
@export var attack_interval: float = 2.0  # Czas między atakami (sekundy)
@export var exp_reward: int = 100  # EXP dla gracza
@export var detection_range: float = 300.0  # Zasięg wykrycia gracza
@export var move_range: float = 400.0  # Maksymalny obszar losowego ruchu

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var attack_cooldown: Timer = Timer.new()
@onready var move_timer: Timer = Timer.new()

var target: Node2D = null  # Referencja do gracza
var is_attacking: bool = false
var is_chasing: bool = false  # Czy wróg goni gracza
var move_target: Vector2  # Punkt docelowy losowego ruchu
var start_position: Vector2  # Początkowa pozycja wroga

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")

	if target == null:
		print("❌ Nie znaleziono gracza!")

	start_position = global_position  # Zapisujemy pozycję startową

	# Konfiguracja paska HP
	if health_bar:
		health_bar.max_value = hp
		health_bar.value = hp

	# Ustawienie timera ataku
	attack_cooldown.wait_time = attack_interval
	attack_cooldown.one_shot = true
	add_child(attack_cooldown)

	# ✅ Dodanie timera ruchu do drzewa sceny
	move_timer.wait_time = randf_range(2, 4)  # Wróg zmienia kierunek co 2-4 sekundy
	move_timer.timeout.connect(_choose_new_move_target)
	move_timer.autostart = true  # Ustawienie automatycznego startu
	add_child(move_timer)  # ✅ Teraz timer jest w drzewie sceny!

	_choose_new_move_target()  # Pierwszy ruch losowy


func _process(_delta: float) -> void:
	if is_attacking:
		return  # Nie poruszaj się, jeśli wróg atakuje

	if target:
		var direction = target.global_position - global_position
		var distance = direction.length()

		if distance <= detection_range:
			is_chasing = true  # Wróg zaczyna gonić gracza

		if is_chasing and distance > attack_range:
			# Wróg goni gracza
			velocity = direction.normalized() * chase_speed
			anim.play("walk")
		elif is_chasing and distance <= attack_range:
			# Wróg zatrzymuje się i atakuje
			velocity = Vector2.ZERO
			if not is_attacking and not attack_cooldown.time_left > 0:
				attack()
		else:
			# Jeśli wróg nie widzi gracza, porusza się losowo
			move_randomly()

		# Obracanie przeciwnika na podstawie kierunku
		if velocity.x > 0:
			anim.flip_h = false
			collision_shape.scale.x = 1
		elif velocity.x < 0:
			anim.flip_h = true
			collision_shape.scale.x = -1

	move_and_slide()

	# Aktualizacja pozycji paska HP
	if health_bar:
		health_bar.global_position = global_position + Vector2(-20, -60)

func _choose_new_move_target():
	# Wybieramy nowy losowy punkt do ruchu w obrębie "move_range"
	var random_x = randf_range(start_position.x - move_range, start_position.x + move_range)
	var random_y = randf_range(start_position.y - move_range, start_position.y + move_range)
	move_target = Vector2(random_x, random_y)

	# Ustaw nowy czas do następnego ruchu
	move_timer.wait_time = randf_range(2, 4)
	move_timer.start()

func move_randomly():
	if global_position.distance_to(move_target) > 10:
		var direction = (move_target - global_position).normalized()
		velocity = direction * speed
		anim.play("walk")
	else:
		_choose_new_move_target()

func attack():
	if is_attacking or attack_cooldown.time_left > 0:
		return  # Nie atakuj, jeśli trwa animacja ataku lub cooldown

	is_attacking = true
	anim.play("attack")
	attack_cooldown.start()  # Rozpocznij cooldown ataku

	# Opóźnienie ataku (po 0.5s wróg zadaje obrażenia)
	await get_tree().create_timer(0.5).timeout  

	if target and global_position.distance_to(target.global_position) <= attack_range:
		var shield = target.get_node_or_null("Shield")

		if shield:
			print("🛡️ Wróg trafił w tarczę! Zadaję", atk, "obrażeń tarczy.")
			shield.absorb_damage(atk)
		else:
			target.take_damage(atk)
			print("⚔️ Wróg trafił gracza!")

	await anim.animation_finished
	is_attacking = false
	anim.play("idle")

func take_damage(damage: int):
	hp = max(0, hp - damage)
	if health_bar:
		health_bar.value = hp

	print("💥 Wróg otrzymał", damage, "obrażeń! HP:", hp)

	if hp <= 0:
		die()

func die():
	print("💀 Wróg został pokonany!")

	# Przekazanie EXP graczowi
	if target and target.has_method("add_exp"):
		target.add_exp(exp_reward)
		print("🎉 Gracz otrzymał", exp_reward, "EXP!")

	set_physics_process(false)
	velocity = Vector2.ZERO
	move_and_slide()

	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	anim.play("death")

	# Usunięcie po krótkim czasie (0.5 sekundy)
	await get_tree().create_timer(0.2).timeout
	queue_free()

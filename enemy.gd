extends CharacterBody2D

@export var speed: float = 100.0  # Prędkość patrolowania
@export var chase_speed: float = 200.0  # Prędkość gonienia gracza
@export var atk: int = 5  # Siła ataku przeciwnika
@export var hp: int = 50  # Punkty życia przeciwnika
@export var attack_range: float = 100.0  # Zasięg ataku wroga
@export var attack_interval: float = 2.0  # Czas między atakami (sekundy)
@export var exp_reward: int = 100  # EXP dla gracza
@export var detection_range: float = 300.0  # Zasięg wykrycia gracza
@export var patrol_distance: float = 200.0  # Odległość patrolowania

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var attack_cooldown: Timer = Timer.new()


var target: Node2D = null  # Referencja do gracza
var is_attacking: bool = false
var is_chasing: bool = false  # Czy wróg goni gracza
var patrol_direction: int = 1  # Kierunek patrolowania (1 = prawo, -1 = lewo)
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
	attack_cooldown.wait_time = attack_interval
	attack_cooldown.one_shot = true


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
			# Wróg zatrzymuje się i przygotowuje do ataku (ale nie spamuje)
			velocity = Vector2.ZERO
			if not is_attacking and not attack_cooldown.time_left > 0:
				attack()
		else:
			# Jeśli wróg nie widzi gracza, patroluje lewo-prawo
			patrol()

		# Obracanie przeciwnika tylko w lewo/prawo
		if direction.x > 0:
			anim.flip_h = false
			collision_shape.scale.x = 1
		elif direction.x < 0:
			anim.flip_h = true
			collision_shape.scale.x = -1

		move_and_slide()

		# Aktualizacja pozycji paska HP
		if health_bar:
			health_bar.global_position = global_position + Vector2(-20, -60)

func patrol():
	var patrol_target_left = start_position.x - patrol_distance
	var patrol_target_right = start_position.x + patrol_distance

	# Jeśli wróg dotarł do granicy patrolu, zmienia kierunek
	if global_position.x <= patrol_target_left:
		patrol_direction = 1  # Idź w prawo
	elif global_position.x >= patrol_target_right:
		patrol_direction = -1  # Idź w lewo

	# Przesuwanie wroga w kierunku patrolu
	velocity = Vector2(patrol_direction * speed, 0)
	anim.play("walk")

	# 🔹 Obracanie na podstawie faktycznego kierunku ruchu
	if patrol_direction > 0:
		anim.flip_h = false  # Wróg patrzy w prawo
	else:
		anim.flip_h = true   # Wróg patrzy w lewo

	move_and_slide()  # Aktualizacja pozycji



func attack():
	if is_attacking or attack_cooldown.time_left > 0:
		return  # Nie atakuj, jeśli trwa animacja ataku lub cooldown

	is_attacking = true
	anim.play("attack")
	attack_cooldown.start()  # Rozpocznij cooldown ataku

	# Czekanie na odpowiedni moment w animacji ataku
	await get_tree().create_timer(0.5).timeout  # Opóźnienie na zadanie obrażeń

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
	await anim.animation_finished
	queue_free()

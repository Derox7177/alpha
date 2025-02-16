extends CharacterBody2D

@export var speed: float = 200.0  # Wolniejszy niż gracz
@export var atk: int = 5  # Siła ataku przeciwnika
@export var hp: int = 50  # Punkty życia przeciwnika
@export var attack_range: float = 50.0  # Zasięg ataku wroga
@export var attack_interval: float = 10.0  # Czas między atakami

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D  # Animacja
@onready var health_bar: ProgressBar = $HealthBar  # Pasek HP
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D  # Kolizja
var target: Node2D = null  # Referencja do gracza
var is_attacking: bool = false  # Flaga ataku, aby animacja nie powtarzała się w pętli

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")  # Dodanie do grupy "enemy", aby gracz mógł atakować
	
	if target == null:
		print("Nie znaleziono gracza!")

	# Konfiguracja paska HP
	if health_bar:
		health_bar.max_value = hp
		health_bar.value = hp

	# Timer do ataku co 10 sekund
	var attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.autostart = true
	attack_timer.one_shot = false
	attack_timer.timeout.connect(attack)
	add_child(attack_timer)

func _process(_delta: float) -> void:
	if is_attacking:
		return  # Nie poruszaj się, jeśli wróg atakuje

	if target:
		var direction = target.global_position - global_position
		var distance = direction.length()

		if distance > attack_range:  # Jeśli gracz jest poza zasięgiem ataku
			direction = direction.normalized()
			velocity = direction * speed
			anim.play("walk")  # Wróg idzie w stronę gracza
		else:
			velocity = Vector2.ZERO
			if not is_attacking:
				anim.play("idle")  # Wróg zatrzymuje się

		# Obracanie przeciwnika tylko w lewo/prawo
		if direction.x > 0:
			anim.flip_h = false  # Patrzy w prawo
			collision_shape.scale.x = 1  # Kolizja w normalnej pozycji
		elif direction.x < 0:
			anim.flip_h = true  # Patrzy w lewo
			collision_shape.scale.x = -1  # Odbicie kolizji w lewo

		move_and_slide()

	# Aktualizacja pozycji paska HP nad przeciwnikiem
	if health_bar:
		health_bar.global_position = global_position + Vector2(-20, -60)

func attack():
	if is_attacking:
		return  # Uniknięcie ponownego ataku, jeśli animacja trwa

	is_attacking = true  # Flaga ataku
	anim.play("attack")  # Odtworzenie animacji ataku

	if target and target is CharacterBody2D:
		target.hp -= atk  # Wróg zadaje obrażenia graczowi
		print("Wróg zaatakował gracza! HP gracza:", target.hp)

		# Jeśli gracz zginął, usuń go
		if target.hp <= 0:
			print("Gracz został pokonany!")
			target.queue_free()

	# Czekanie na zakończenie animacji ataku
	await anim.animation_finished  
	is_attacking = false  # Flaga ataku wraca do false
	anim.play("idle")  # Powrót do idle

func take_damage(damage: int):
	hp = max(0, hp - damage)  # Zapewnia, że HP nie spadnie poniżej 0

	if health_bar:
		health_bar.value = hp  # Aktualizacja paska HP

	print("Wróg otrzymał", damage, "obrażeń! HP:", hp)

	if hp <= 0:
		die()

func die():
	print("💀 Wróg został pokonany!")

	set_physics_process(false)  # Wyłączenie fizyki, wróg się nie porusza
	velocity = Vector2.ZERO  # Natychmiastowe zatrzymanie
	move_and_slide()  # Aktualizacja pozycji

	# Wyłączenie kolizji, aby nie blokował gracza
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	anim.play("death")  # Odtworzenie animacji śmierci
	await anim.animation_finished  # Poczekanie na zakończenie animacji
	queue_free()  # Usunięcie przeciwnika ze sceny

# Player.gd
extends CharacterBody2D

# Eksportowane zmienne – parametry gracza:
@export var speed: float = 300.0            # Prędkość ruchu gracza
@export var atk: int = 10                   # Siła ataku melee
@export var hp: int = 100                   # Aktualne punkty życia
@export var max_hp: int = 100               # Maksymalne punkty życia
@export var attack_range: float = 100.0     # Zasięg ataku melee
@export var fireball_scene: PackedScene     # Scena fireballa
@export var blackhole_scene: PackedScene
@export var lighting_scene: PackedScene
@export var max_mana: int = 100             # Maksymalna ilość many
var mana: int = max_mana                    # Aktualna ilość many
var fireball_cost: int = 10                 # Koszt many za rzut fireballa
var blackhole_cost: int = 10 
var lighting_cost: int = 10

# Referencje do elementów UI – ustawione według ścieżek w drzewie scen:
@onready var hp_bar: TextureProgressBar = get_node("/root/Game/UI/Control/VBoxContainer/HPBar")
@onready var mana_bar: TextureProgressBar = get_node("/root/Game/UI/Control/VBoxContainer/ManaBar")
@onready var hp_label: Label = get_node("/root/Game/UI/Control/VBoxContainer/HPBar/HPLabel")
@onready var mana_label: Label = get_node("/root/Game/UI/Control/VBoxContainer/ManaBar/ManaLabel")
@onready var fireball_icon: TextureRect = get_node("/root/Game/UI/FireballUI/FireballIcon")
@onready var fireball_cd_label: Label = get_node("/root/Game/UI/FireballUI/FireballCDLabel")
@onready var fireball_key_label: Label = get_node("/root/Game/UI/FireballUI/FireballKeyLabel")
@onready var blackhole_icon: TextureRect = get_node("/root/Game/UI/blackholeUI/blackholeIcon")
@onready var blackhole_cd_label: Label = get_node("/root/Game/UI/blackholeUI/blackholeCDLabel")
@onready var blackhole_key_label: Label = get_node("/root/Game/UI/blackholeUI/blackholeKeyLabel")
@onready var lighting_icon: TextureRect = get_node("/root/Game/UI/lightingUI/lightingIcon")
@onready var lighting_cd_label: Label = get_node("/root/Game/UI/lightingUI/lightingCDLabel")
@onready var lighting_key_label: Label = get_node("/root/Game/UI/lightingUI/lightingKeyLabel")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D  # Referencja do animacji gracza

# Flagi i zmienne pomocnicze:
var is_attacking: bool = false           # Flaga ataku
var fireball_cd: bool = false   
var blackhole_cd: bool = false          # Flaga cooldownu fireballa
var lighting_cd: bool = false
# W tej wersji nie używamy już 'facing_direction', ponieważ fireball celujemy w myszkę

func _ready():
	# Sprawdzamy referencje UI
	if not hp_bar or not mana_bar or not hp_label or not mana_label:
		print("❌ Błąd: Brak referencji do UI!")
		return
	_update_ui()  # Aktualizujemy interfejs

	# Timer do regeneracji many – 1 mana na sekundę
	var mana_regen_timer = Timer.new()
	mana_regen_timer.wait_time = 1.0
	mana_regen_timer.autostart = true
	mana_regen_timer.one_shot = false
	mana_regen_timer.timeout.connect(_regenerate_mana)
	add_child(mana_regen_timer)

func _physics_process(delta: float) -> void:
	# Obsługa ruchu gracza (jeśli nie atakuje)
	if is_attacking:
		return

	# Pobieramy wejście z klawiatury dla ruchu (osie X i Y)
	var direction_x := Input.get_axis("left", "right")
	var direction_y := Input.get_axis("up", "down")
	var direction := Vector2(direction_x, direction_y)

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		anim.play("walk")  # Animacja chodzenia

		# Obracanie gracza w poziomie na podstawie wejścia
		if direction.x > 0:
			anim.flip_h = false  # Gracz patrzy w prawo
		elif direction.x < 0:
			anim.flip_h = true   # Gracz patrzy w lewo
	else:
		velocity = Vector2.ZERO
		anim.play("idle")  # Animacja bezczynności

	move_and_slide()

	# Sprawdzenie ataku melee (kliknięcie LPM)
	if Input.is_action_just_pressed("mouse_left"):
		attack()

	# Rzut fireballa – klawisz "one" i brak cooldownu
	if Input.is_action_just_pressed("one") and not fireball_cd:
		cast_fireball()
		
	if Input.is_action_just_pressed("two") and not fireball_cd:
		cast_blackhole()
		
	if Input.is_action_just_pressed("three") and not fireball_cd:
		cast_lighting()

func attack():
	# Obsługa ataku melee
	if is_attacking:
		return
	is_attacking = true
	anim.play("attack")  # Uruchamiamy animację ataku

	# Pobieramy przeciwników z grupy "enemy" i sprawdzamy zasięg
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is CharacterBody2D and global_position.distance_to(enemy.global_position) <= attack_range:
			enemy.take_damage(atk)  # Zadajemy obrażenia
			print("Gracz zaatakował przeciwnika!")
	
	await anim.animation_finished  # Czekamy na zakończenie animacji ataku
	is_attacking = false
	anim.play("idle")  # Powrót do animacji bezczynności

func cast_fireball():
	# Obsługa rzutu fireballa
	if fireball_cd:
		return
	if fireball_scene == null:
		print("❌ Błąd: fireball_scene nie jest przypisane!")
		return
	if mana < fireball_cost:
		print("❌ Brak many na Fireball!")
		return

	# Zużywamy manę i aktualizujemy UI
	mana -= fireball_cost
	_update_ui()
	print("🔥 Fireball rzucony! Pozostała mana:", mana)

	fireball_cd = true
	fireball_icon.modulate = Color(0.5, 0.5, 0.5, 1)  # Efekt wizualny – przyciemnienie ikony
	fireball_cd_label.text = "3s"  # Wyświetlenie tekstu cooldown

	# Instancjujemy fireball i ustawiamy jego pozycję na pozycji gracza
	var fireball = fireball_scene.instantiate() as Area2D
	fireball.global_position = global_position
	get_parent().add_child(fireball)

	# Obliczamy kierunek fireballa na podstawie pozycji myszy:
	# global_position odnosi się do pozycji gracza
	var mouse_pos: Vector2 = get_global_mouse_position()
	var fireball_direction: Vector2 = (mouse_pos - global_position).normalized()
	fireball.set_direction(fireball_direction)  # Ustawiamy kierunek fireballa
	print("🔥 Gracz użył Fireballa w kierunku myszy!")

	# Odliczanie cooldownu (3 sekundy)
	for i in range(3, 0, -1):
		await get_tree().create_timer(1.0).timeout
		fireball_cd_label.text = str(i) + "s"
	fireball_cd_label.text = ""
	fireball_icon.modulate = Color(1, 1, 1, 1)  # Przywracamy oryginalny kolor ikony
	fireball_cd = false

func _update_ui():
	# Aktualizacja wyświetlanych wartości HP i many
	hp_bar.value = hp
	mana_bar.value = mana
	hp_label.text = str(hp, " / ", max_hp)
	mana_label.text = str(mana, " / ", max_mana)

func take_damage(amount: int):
	# Obsługa otrzymywania obrażeń przez gracza
	hp = max(0, min(hp - amount, max_hp))
	_update_ui()
	if hp == 0:
		die()

func die():
	# Obsługa śmierci gracza
	print("💀 Gracz zginął!")
	queue_free()

func _regenerate_mana():
	# Regeneracja many (1 mana na sekundę)
	if mana < max_mana:
		mana = min(max_mana, mana + 1)
		_update_ui()
		
func cast_blackhole():
	# Obsługa rzutu blackholea
	if blackhole_cd:
		return
	if blackhole_scene == null:
		print("❌ Błąd: blackhole_scene nie jest przypisane!")
		return
	if mana < blackhole_cost:
		print("❌ Brak many na blackhole!")
		return

	# Zużywamy manę i aktualizujemy UI
	mana -= blackhole_cost
	_update_ui()
	print("🔥 blackhole rzucony! Pozostała mana:", mana)

	blackhole_cd = true
	blackhole_icon.modulate = Color(0.5, 0.5, 0.5, 1)  # Efekt wizualny – przyciemnienie ikony
	blackhole_cd_label.text = "3s"  # Wyświetlenie tekstu cooldown

	# Instancjujemy blackhole i ustawiamy jego pozycję na pozycji gracza
	var blackhole = blackhole_scene.instantiate() as Area2D
	blackhole.global_position = global_position
	get_parent().add_child(blackhole)

	# Obliczamy kierunek blackholea na podstawie pozycji myszy:
	# global_position odnosi się do pozycji gracza
	var mouse_pos: Vector2 = get_global_mouse_position()
	var blackhole_direction: Vector2 = (mouse_pos - global_position).normalized()
	blackhole.set_direction(blackhole_direction)  # Ustawiamy kierunek blackholea
	print("🔥 Gracz użył blackholea w kierunku myszy!")

	# Odliczanie cooldownu (3 sekundy)
	for i in range(3, 0, -1):
		await get_tree().create_timer(1.0).timeout
		blackhole_cd_label.text = str(i) + "s"
	blackhole_cd_label.text = ""
	blackhole_icon.modulate = Color(1, 1, 1, 1)  # Przywracamy oryginalny kolor ikony
	blackhole_cd = false
	
func cast_lighting():
	# Obsługa rzutu lightinga
	if lighting_cd:
		return
	if lighting_scene == null:
		print("❌ Błąd: lighting_scene nie jest przypisane!")
		return
	if mana < lighting_cost:
		print("❌ Brak many na lighting!")
		return

	# Zużywamy manę i aktualizujemy UI
	mana -= lighting_cost
	_update_ui()
	print("🔥 lighting rzucony! Pozostała mana:", mana)

	lighting_cd = true
	lighting_icon.modulate = Color(0.5, 0.5, 0.5, 1)  # Efekt wizualny – przyciemnienie ikony
	lighting_cd_label.text = "3s"  # Wyświetlenie tekstu cooldown

	# Instancjujemy lighting i ustawiamy jego pozycję na pozycji gracza
	var lighting = lighting_scene.instantiate() as Area2D
	lighting.global_position = global_position
	get_parent().add_child(lighting)

	# Obliczamy kierunek lightinga na podstawie pozycji myszy:
	# global_position odnosi się do pozycji gracza
	var mouse_pos: Vector2 = get_global_mouse_position()
	var lighting_direction: Vector2 = (mouse_pos - global_position).normalized()
	lighting.set_direction(lighting_direction)  # Ustawiamy kierunek lightinga
	print("🔥 Gracz użył lightinga w kierunku myszy!")

	# Odliczanie cooldownu (3 sekundy)
	for i in range(3, 0, -1):
		await get_tree().create_timer(1.0).timeout
		lighting_cd_label.text = str(i) + "s"
	lighting_cd_label.text = ""
	lighting_icon.modulate = Color(1, 1, 1, 1)  # Przywracamy oryginalny kolor ikony
	lighting_cd = false

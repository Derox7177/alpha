# Player.gd
extends CharacterBody2D

# Eksportowane zmienne – parametry gracza:
@export var speed: float = 300.0            # Prędkość ruchu gracza
@export var atk: int = 10                   # Siła ataku melee
@export var hp: int = 100                   # Aktualne punkty życia
@export var max_hp: int = 100               # Maksymalne punkty życia
@export var hp_regen: int = 1
@export var attack_range: float = 100.0     # Zasięg ataku melee
@export var fireball_scene: PackedScene     # Scena fireballa
@export var blackhole_scene: PackedScene
@export var lighting_scene: PackedScene
@export var shield_scene: PackedScene

@export var max_mana: int = 100             # Maksymalna ilość many
var mana: int = max_mana                    # Aktualna ilość many
var fireball_cost: int = 10                 # Koszt many za rzut fireballa
var blackhole_cost: int = 10 
var lighting_cost: int = 10
var shield_cost: int = 10

# Referencje do elementów UI – ustawione według ścieżek w drzewie scen:
@onready var hp_bar: TextureProgressBar = get_node("/root/pustynia/UI/Control/VBoxContainer/HPBar")
@onready var mana_bar: TextureProgressBar = get_node("/root/pustynia/UI/Control/VBoxContainer/ManaBar")
@onready var hp_label: Label = get_node("/root/pustynia/UI/Control/VBoxContainer/HPBar/HPLabel")
@onready var mana_label: Label = get_node("/root/pustynia/UI/Control/VBoxContainer/ManaBar/ManaLabel")
@onready var fireball_icon: TextureRect = get_node("/root/pustynia/UI/FireballUI/FireballIcon")
@onready var fireball_cd_label: Label = get_node("/root/pustynia/UI/FireballUI/FireballCDLabel")
@onready var fireball_key_label: Label = get_node("/root/pustynia/UI/FireballUI/FireballKeyLabel")
@onready var blackhole_icon: TextureRect = get_node("/root/pustynia/UI/blackholeUI/blackholeIcon")
@onready var blackhole_cd_label: Label = get_node("/root/pustynia/UI/blackholeUI/blackholeCDLabel")
@onready var blackhole_key_label: Label = get_node("/root/pustynia/UI/blackholeUI/blackholeKeyLabel")
@onready var lighting_icon: TextureRect = get_node("/root/pustynia/UI/lightingUI/lightingIcon")
@onready var lighting_cd_label: Label = get_node("/root/pustynia/UI/lightingUI/lightingCDLabel")
@onready var lighting_key_label: Label = get_node("/root/pustynia/UI/lightingUI/lightingKeyLabel")
@onready var shield_icon: TextureRect = get_node("/root/pustynia/UI/shieldUI/shieldIcon")
@onready var shield_cd_label: Label = get_node("/root/pustynia/UI/shieldUI/shieldCDLabel")
@onready var shield_key_label: Label = get_node("/root/pustynia/UI/shieldUI/shieldKeyLabel")
@onready var shield_bar: ProgressBar = get_node("/root/pustynia/UI/shieldUI/shieldBar")
@onready var exp_bar: TextureProgressBar = get_node("/root/pustynia/UI/ExpBar/ExpBar")
@onready var lvlchara: Label = get_node("/root/pustynia/UI/ExpBar/lvlchara")
@onready var stat_panel: Control = get_node("/root/pustynia/UI/StatPanel")
@onready var stat_points_label: Label = get_node("/root/pustynia/UI/StatPanel/PanelContainer/VBoxContainer/StatPointsLabel")
@onready var speed_label: Label = get_node("/root/pustynia/UI/StatPanel/PanelContainer/VBoxContainer/StatPointsLabel/SpeedButton/SpeedLabel")
@onready var attack_label: Label = get_node("/root/pustynia/UI/StatPanel/PanelContainer/VBoxContainer/StatPointsLabel/AttackButton/AttackLabel")
@onready var hp_label_stat: Label = get_node("/root/pustynia/UI/StatPanel/PanelContainer/VBoxContainer/StatPointsLabel/HpButton/HpLabel")





@onready var anim: AnimatedSprite2D = $AnimatedSprite2D  # Referencja do animacji gracza

# Flagi i zmienne pomocnicze:
var is_attacking: bool = false           # Flaga ataku
var fireball_cd: bool = false   
var blackhole_cd: bool = false          # Flaga cooldownu fireballa
var lighting_cd: bool = false
var shield_cd: bool = false
var exp: int = 0
var exp_to_next_level: int = 100
var level: int = 1
var stat_points: int = 0
# W tej wersji nie używamy już 'facing_direction', ponieważ fireball celujemy w myszkę

# Funkcja dodająca EXP i awansująca gracza
func add_exp(amount: int):
	exp += amount
	while exp >= exp_to_next_level:
		exp -= exp_to_next_level
		level_up()
	_update_ui()  # Aktualizujemy UI po zmianie EXP

func level_up():
	level += 1
	exp_to_next_level += 10  # Każdy nowy poziom wymaga o 10 EXP więcej
	stat_points += 1
	print("🎉 Level Up! Nowy poziom:", level)
	_update_ui()  # Aktualizacja interfejsu po awansie

# Funkcja ulepszania statystyk
func upgrade_stat(stat: String):
	if stat_points > 0:
		if stat == "speed":
			speed += 10
		elif stat == "attack":
			atk += 10
		elif stat == "hp":
			max_hp += 10
			hp += 10
		stat_points -= 1
		_update_ui()
		print("📈 Statystyka", stat, "zwiększona!")
	else:
		print("❌ Brak dostępnych punktów statystyk!")

func _input(event):
	if event.is_action_pressed("staty"):
		stat_panel.visible = not stat_panel.visible  # Przełącz widoczność panelu

func _ready():
	
	stat_panel.visible = false  # Ukrywamy panel na starcie
	
	 # Podpinanie sygnałów do przycisków (upewnij się, że są poprawne)
	var speed_button = get_node("/root/pustynia/UI/StatPanel/PanelContainer/VBoxContainer/StatPointsLabel/SpeedButton")
	var attack_button = get_node("/root/pustynia/UI/StatPanel/PanelContainer/VBoxContainer/StatPointsLabel/AttackButton")
	var hp_button = get_node("/root/pustynia/UI/StatPanel/PanelContainer/VBoxContainer/StatPointsLabel/HpButton")

	if speed_button: speed_button.pressed.connect(_on_speed_button_pressed)
	if attack_button: attack_button.pressed.connect(_on_attack_button_pressed)
	if hp_button: hp_button.pressed.connect(_on_hp_button_pressed)


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
	
	var hp_regen_timer = Timer.new()
	hp_regen_timer.wait_time = 1.0
	hp_regen_timer.autostart = true
	hp_regen_timer.one_shot = false
	hp_regen_timer.timeout.connect(_regenerate_hp)
	add_child(hp_regen_timer)

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
		
	if Input.is_action_just_pressed("four") and not fireball_cd:
		cast_shield()

func _on_speed_button_pressed():
	upgrade_stat("speed")

func _on_attack_button_pressed():
	upgrade_stat("attack")

func _on_hp_button_pressed():
	upgrade_stat("hp")


func attack():
	if is_attacking:
		return
	is_attacking = true
	anim.play("attack")
	

	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is CharacterBody2D and global_position.distance_to(enemy.global_position) <= attack_range:
			enemy.take_damage(atk)
			print("🎯 Trafienie!")

	
	await anim.animation_finished
	

	is_attacking = false
	anim.play("idle")


func _on_attack_finished():
	is_attacking = false
	anim.play("idle")
	print("Atak zakończony, można ponownie atakować.")



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
	exp_bar.value = exp
	exp_bar.max_value = exp_to_next_level
	stat_points_label.text = "Punkty: " + str(stat_points)
	speed_label.text = "Speed: " + str(speed)
	attack_label.text = "Attack: " + str(atk)
	hp_label_stat.text = "HP: " + str(max_hp)
	hp_bar.value = hp
	mana_bar.value = mana
	hp_label.text = str(hp) + " / " + str(max_hp)
	mana_label.text = str(mana) + " / " + str(max_mana)
	lvlchara.text = "Lvl: " + str(level)  # Aktualizacja etykiety poziomu
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
		
func _regenerate_hp():
	# Regeneracja many (1 hp na sekundę)
	if hp < max_hp:
		hp = min(max_hp, hp + 1)
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
	print("🔥 Lighting rzucony! Pozostała mana:", mana)

	lighting_cd = true
	lighting_icon.modulate = Color(0.5, 0.5, 0.5, 1)  # Efekt wizualny – przyciemnienie ikony
	lighting_cd_label.text = "3s"  # Wyświetlenie tekstu cooldown

	# Instancjujemy Lighting
	var lighting = lighting_scene.instantiate() as Area2D

	# 🔹 Pobranie pozycji kursora
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()  # Wektor kierunku do myszki

	# 🔹 Pobranie CollisionShape2D gracza
	var player_collision = $CollisionShape2D
	var offset = Vector2.ZERO  # Domyślne przesunięcie

	if player_collision:
		var collision_size = player_collision.shape.get_rect().size  
		
		# 🔹 Znalezienie największego wymiaru kolizji (dla poprawnego odsunięcia)
		var max_radius = max(collision_size.x, collision_size.y) / 2  

		# 🔹 Ustawienie pozycji Lightning minimalnie poza kolizją
		offset = direction_to_mouse * (max_radius + 30)  # +5 jednostek, żeby był tuż za kolizją

	lighting.global_position = global_position + offset  # Ustawienie pozycji Lighting

	# Dodanie Lighting do sceny
	get_parent().add_child(lighting)

	# 🔹 Lighting porusza się w stronę kursora
	lighting.set_direction(direction_to_mouse)

	print("🔥 Gracz użył Lightinga w kierunku myszy!")

	# Odliczanie cooldownu (3 sekundy)
	for i in range(3, 0, -1):
		await get_tree().create_timer(1.0).timeout
		lighting_cd_label.text = str(i) + "s"

	lighting_cd_label.text = ""
	lighting_icon.modulate = Color(1, 1, 1, 1)  # Przywracamy oryginalny kolor ikony
	lighting_cd = false

func cast_shield():
	if shield_cd:
		print("❌ Tarcza jest na cooldownie!")
		return
	if shield_scene == null:
		print("❌ Błąd: Shield.tscn nie jest przypisane!")
		return
	if mana < shield_cost:
		print("❌ Brak many na tarczę!")
		return

	# 🔹 Zużycie many
	mana -= shield_cost
	_update_ui()
	print("🛡️ Gracz aktywował tarczę!")

	# 🔹 Sprawdź, czy gracz już ma tarczę (unikamy dodania kilku naraz)
	if has_node("Shield"):
		print("⚠️ Gracz już ma aktywną tarczę!")
		return

	# 🔹 Tworzymy tarczę i przypisujemy gracza
	var shield = shield_scene.instantiate() as Area2D
	shield.name = "Shield"  # Upewniamy się, że ma poprawną nazwę
	shield.player = self  # Przypisanie gracza do tarczy
	add_child(shield)  # Dodanie tarczy jako dziecko gracza

	# 🔹 Powiązanie tarczy z paskiem ShieldBar
	shield.shield_bar = shield_bar  
	shield_bar.max_value = shield.max_absorb  # Ustawienie maksymalnej wartości
	shield_bar.value = shield.max_absorb  # Ustawienie pełnej wytrzymałości tarczy
	shield_bar.visible = true  # Pokazanie paska

	print("🛡️ Tarcza została dodana do gracza! Aktualne dzieci:", get_children())

	# 🔹 Ustawienie cooldownu (8 sekund)
	shield_cd = true  
	shield_icon.modulate = Color(0.5, 0.5, 0.5, 1)  
	shield_cd_label.text = "8s"  

	# 🔹 Odliczanie cooldownu (pętla odliczająca 8 sekund)
	for i in range(8, 0, -1):
		await get_tree().create_timer(1.0).timeout
		shield_cd_label.text = str(i) + "s"

	# 🔹 Reset cooldownu
	shield_cd_label.text = ""  
	shield_icon.modulate = Color(1, 1, 1, 1)  
	shield_cd = false
	print("🛡️ Tarcza gotowa do ponownego użycia!")

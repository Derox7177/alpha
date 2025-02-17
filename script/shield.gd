extends Area2D

@export var max_absorb: int = 80  # Maksymalna ilość obrażeń, które tarcza może pochłonąć
@export var duration: float = 4.0  # Czas trwania tarczy
@export var player: Node2D  # Referencja do gracza
var shield_bar: ProgressBar  # 🔹 Pasek wytrzymałości tarczy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  
@onready var collision_shape: CollisionShape2D = $CollisionShape2D  

var current_absorb: int  

func _ready():
	current_absorb = max_absorb  
	sprite.play("default")  
	print("🛡️ Tarcza aktywowana!")

	# 🔹 Automatyczne usunięcie tarczy po upływie `duration` sekund
	await get_tree().create_timer(duration).timeout
	print("🛡️ Tarcza wygasła!")
	_destroy_shield()

func _process(_delta):
	if player:
		global_position = player.global_position

func absorb_damage(amount: int):
	current_absorb -= amount
	print("🛡️ Tarcza pochłonęła", amount, "obrażeń! Pozostało:", max(0, current_absorb))

	if shield_bar:
		shield_bar.value = current_absorb  # 🔹 Aktualizacja paska wytrzymałości

	if current_absorb <= 0:
		print("💥 Tarcza została zniszczona!")
		_destroy_shield()  # 🔹 Zamiast `queue_free()`, nowa funkcja `_destroy_shield()`

func _destroy_shield():
	print("🛡️ Usuwanie tarczy i paska!")
	if shield_bar:
		shield_bar.visible = false  # 🔹 Ukrycie paska tarczy
		
	queue_free()  # 🔹 Usunięcie tarczy po wyczerpaniu pochłaniania obrażeń
	

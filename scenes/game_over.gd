extends CanvasLayer  # Poprawione - CanvasLayer zamiast Control

@onready var restart_button: Button = $ColorRect/Button

func _ready():
	hide()  # Ukryj ekran Game Over na starcie
	restart_button.pressed.connect(_on_restart_pressed)

func show_game_over():
	print("❌ Wyświetlam ekran Game Over!")
	show()  # Pokaż ekran

func _on_restart_pressed():
	print("🔄 Restart gry!")
	hide()  # Ukryj ekran Game Over przed restartem
	await get_tree().process_frame  # Poczekaj jedną klatkę, aby ukrycie się wykonało
	get_tree().reload_current_scene()  # Reset gry

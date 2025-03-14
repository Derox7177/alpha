extends CanvasLayer

@onready var resume_button = $VBoxContainer/ContinueButton
@onready var restart_button = $VBoxContainer/RestartButton
@onready var main_menu_button = $VBoxContainer/MenuButton
@onready var exit_button = $VBoxContainer/ExitButton

var is_menu_open = false  # Zmienna zapobiegająca podwójnemu otwieraniu menu

func _ready():
	hide()  # Ukrywamy menu na starcie
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _input(event):
	if event.is_action_pressed("pause"):
		if not is_menu_open:  # Zapobiega podwójnemu otwieraniu
			is_menu_open = true
			show()
			get_tree().paused = true
		else:
			is_menu_open = false
			hide()
			get_tree().paused = false

func _on_resume_pressed():
	is_menu_open = false
	hide()
	get_tree().paused = false  # Kontynuacja gry

func _on_restart_pressed():
	is_menu_open = false
	hide()
	get_tree().paused = false
	get_tree().reload_current_scene()  # Reset gry

func _on_main_menu_pressed():
	is_menu_open = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")  # Powrót do menu

func _on_exit_pressed():
	get_tree().quit()

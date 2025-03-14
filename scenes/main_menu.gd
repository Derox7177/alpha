extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var tutorial_button = $VBoxContainer/TutorialButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var tutorial_label = $TutorialLabel  # Label do wyświetlania instrukcji

func _ready():
	tutorial_label.hide()  # Ukrywamy samouczek na starcie
	
	# Podpinamy przyciski do funkcji
	play_button.pressed.connect(_on_play_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_play_pressed():
	# Sprawdź czy plik istnieje
	var scene_path = "res://scenes/game.tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("❌ Błąd: Scena gry nie istnieje! Sprawdź ścieżkę:", scene_path)

func _on_tutorial_pressed():
	# Pokazanie / ukrycie samouczka
	tutorial_label.visible = not tutorial_label.visible  

func _on_exit_pressed():
	get_tree().quit()  # Zamknięcie gry

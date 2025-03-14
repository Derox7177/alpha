extends Area2D

@export var target_scene: String = "res://pustynia.tscn"  # Ścieżka do nowej sceny

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):  # Sprawdzenie, czy gracz wszedł w teleport
		print("🔄 Przenoszenie na scenę:", target_scene)
		get_tree().change_scene_to_file(target_scene)  # Ładowanie nowej sceny

extends CharacterBody2D  # lub StaticBody2D, jeśli NPC się nie porusza

var player_in_range = false

func _process(delta):
	if  Input.is_action_just_pressed("inter"):
		print("✅ Gracz przy NPC! Otwieram dialog...")
		DialogHandler.start_dialogue()

func _on_area_entered(area):
	print("✅ Wykryto obiekt:", area.name)
	if area.name == "Player":
		print("✅ Gracz dotknął NPC!")
		player_in_range = true

func _on_area_exited(area):
	print("❌ Obiekt opuścił NPC:", area.name)
	if area.name == "Player":
		print("❌ Gracz odszedł od NPC!")
		player_in_range = false

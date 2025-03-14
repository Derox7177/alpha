extends Node

## Załadowanie pliku dialogów
@export var dialogue_resource: DialogueResource = preload("res://dialogi/dialog1.dialogue")

## Pobranie okna dialogowego
@onready var balloon = get_node("/root/Game/ExampleBalloon")

func _ready():
	print("Sprawdzam ExampleBalloon...")  
	if balloon:
		print("✅ ExampleBalloon znaleziony!")
	else:
		print("❌ Błąd: ExampleBalloon nie znaleziony!")

	if dialogue_resource:
		print("✅ dialogue_resource jest ustawione: ", dialogue_resource)
	else:
		print("❌ Błąd: dialogue_resource jest nadal puste w _ready()!")

## Rozpoczęcie dialogu
func start_dialogue():
	print("✅ Próba otwarcia Balloon...")
	
	if balloon:
		print("✅ Balloon znaleziony! Pokazuję okno dialogu.")
		balloon.visible = true  
		balloon.show()

		if dialogue_resource:
			print("✅ Dialog przekazany: ", dialogue_resource)
			print("📜 Tytuły w pliku:", dialogue_resource.titles)  
			balloon.start(dialogue_resource, "start")
		else:
			print("❌ Błąd: dialogue_resource nadal nie jest ustawione!")

## Ukrycie okna po zakończeniu dialogu
func _on_dialogue_ended():
	if balloon:
		print("✅ Ukrywam okno dialogowe po zakończeniu rozmowy")
		balloon.close_dialogue()



## Przejście do kolejnej linii dialogu
func _on_dialogue_advanced():
	if balloon:
		balloon.apply_dialogue_line()

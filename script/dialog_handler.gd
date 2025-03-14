extends Node

## Załadowanie pliku dialogów
@export var dialogue_resource: DialogueResource = preload("res://dialogi/dialog1.dialogue")

var balloon  ## Referencja do okna dialogowego

func _ready():
	print("🔍 Szukam ExampleBalloon w drzewie scen...")
	
	## Dynamiczne pobranie węzła po jego załadowaniu
	await get_tree().process_frame  ## Poczekaj 1 klatkę, aby upewnić się, że sceny są załadowane
	balloon = get_tree().get_first_node_in_group("dialog_balloon") 

	if balloon:
		print("✅ ExampleBalloon znaleziony!")
	else:
		print("❌ Błąd: ExampleBalloon nie znaleziony. Sprawdź, czy scena Game jest załadowana!")

	if dialogue_resource:
		print("✅ dialogue_resource jest ustawione: ", dialogue_resource)
	else:
		print("❌ Błąd: dialogue_resource jest nadal puste w _ready()!")

## Rozpoczęcie dialogu
func start_dialogue():
	print("✅ Próba otwarcia Balloon...")
	
	if not balloon:
		balloon = get_tree().get_first_node_in_group("dialog_balloon")

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
	else:
		print("❌ Nie znaleziono ExampleBalloon - dialog nie może się rozpocząć.")

## Ukrycie okna po zakończeniu dialogu
func _on_dialogue_ended():
	if balloon:
		print("✅ Ukrywam okno dialogowe po zakończeniu rozmowy")
		balloon.close_dialogue()

## Przejście do kolejnej linii dialogu
func _on_dialogue_advanced():
	if balloon:
		balloon.apply_dialogue_line()

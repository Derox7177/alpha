extends CanvasLayer

## Akcja do przejścia do następnej linii dialogu
@export var next_action: StringName = &"ui_accept"

## Akcja do pomijania tekstu dialogowego
@export var skip_action: StringName = &"ui_cancel"

## Pobranie elementów UI
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## Przechowywanie dialogu
var dialogue_resource: DialogueResource
var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var dialogue_line: DialogueLine

func _ready() -> void:
	hide()  # Ukrycie okna na starcie
	print("✅ Balloon ukryty na starcie!")

## Rozpoczęcie dialogu
func start(dialogue_res: DialogueResource, title: String) -> void:
	print("✅ Balloon otrzymał dialog:", dialogue_res, "Tytuł:", title)
	dialogue_resource = dialogue_res

	var next_line = await dialogue_resource.get_next_dialogue_line(title)
	print("📌 Odczytany dialog:", next_line)

	if next_line:
		self.dialogue_line = next_line
		apply_dialogue_line()
	else:
		print("❌ Błąd: `get_next_dialogue_line()` zwrócił `null`!")

## Wyświetlenie tekstu i odpowiedzi w oknie dialogowym
func apply_dialogue_line() -> void:
	if dialogue_line == null:
		print("❌ Błąd: dialogue_line jest `null`!")
		return

	print("✅ Wyświetlam linijkę:", dialogue_line.text)

	# Ustaw nazwę postaci i tekst
	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = dialogue_line.character
	dialogue_label.dialogue_line = dialogue_line

	# Sprawdzenie dostępnych opcji dialogowych
	if dialogue_line.responses.is_empty():
		print("🔎 Brak `responses`, sprawdzam `branches`...")
		if "branches" in dialogue_line:
			dialogue_line.responses = dialogue_line.branches
			print("✅ Przypisano `branches` jako `responses`")

	print("✅ Opcje do wyboru:", dialogue_line.responses)

	# Ukrycie menu odpowiedzi i przypisanie odpowiedzi do menu
	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses  

	if dialogue_line.responses.size() > 0:
		responses_menu.show()
	else:
		print("❌ Brak opcji do wyboru – sprawdzam `END`...")
		print("📌 Wartość `next_id`: ", dialogue_line.next_id)

		# Sprawdzenie, czy to faktycznie koniec dialogu
		if dialogue_line.next_id == "" or dialogue_line.next_id == "END":
			print("✅ Ostatnia linia dialogu – zamykam okno PO WYŚWIETLENIU TEKSTU!")
			await get_tree().create_timer(2.0).timeout  # Poczekaj 2 sekundy, by gracz mógł przeczytać
			close_dialogue()
		else:
			print("🔄 Pobieram następną linijkę dialogu...")
			var next_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.next_id)

			if next_line == null or next_line.responses.is_empty():
				print("✅ To faktycznie koniec dialogu – zamykam okno!")
				await get_tree().create_timer(2.0).timeout  # Poczekaj 2 sekundy
				close_dialogue()
			else:
				print("🔄 Dialog trwa dalej...")
				dialogue_line = next_line
				apply_dialogue_line()


## Przejście do następnej linii
func next(next_id: String) -> void:
	print("🔄 Przechodzę do następnej linii:", next_id)

	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)
	if dialogue_line != null:
		apply_dialogue_line()
	else:
		print("✅ Ostatnia linia dialogu – zamykam okno PO WYŚWIETLENIU TEKSTU!")
		await get_tree().create_timer(2.0).timeout  # Poczekaj 2 sekundy
		close_dialogue()


## Obsługa kliknięcia opcji odpowiedzi
func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	print("✅ Wybrano opcję:", response.text)
	next(response.next_id)

func close_dialogue():
	print("✅ Dialog zakończony, ukrywam okno!")
	hide()
	is_waiting_for_input = false
	dialogue_line = null
	responses_menu.hide()
	dialogue_label.text = ""  # Wyczyść tekst dialogu
	character_label.text = ""  # Wyczyść nazwę postaci

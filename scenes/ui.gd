extends Control

@onready var level_label = $LevelLabel
@onready var xp_bar = $XPBar
@onready var stat_points_label = $StatPointsLabel

@onready var hp_label = $StatsContainer/HPStat/HPLabel
@onready var mana_label = $StatsContainer/ManaStat/ManaLabel
@onready var speed_label = $StatsContainer/SpeedStat/SpeedLabel
@onready var ap_label = $StatsContainer/APStat/APLabel

@onready var add_hp_button = $StatsContainer/HPStat/AddHPButton
@onready var add_mana_button = $StatsContainer/ManaStat/AddManaButton
@onready var add_speed_button = $StatsContainer/SpeedStat/AddSpeedButton
@onready var add_ap_button = $StatsContainer/APStat/AddAPButton

var player  # Referencja do gracza

func _ready():
	add_hp_button.pressed.connect(_on_add_hp)
	add_mana_button.pressed.connect(_on_add_mana)
	add_speed_button.pressed.connect(_on_add_speed)
	add_ap_button.pressed.connect(_on_add_ap)

func set_player(p):
	player = p
	_update_ui()

func _update_ui():
	if player:
		level_label.text = "Level: " + str(player.level)
		xp_bar.value = player.xp
		stat_points_label.text = "Punkty statystyk: " + str(player.skill_points)

		hp_label.text = "HP: " + str(player.hp)
		mana_label.text = "Mana: " + str(player.mana)
		speed_label.text = "Speed: " + str(player.speed)
		ap_label.text = "AP: " + str(player.ap)

func _on_add_hp():
	if player and player.skill_points > 0:
		player.hp += 5
		player.skill_points -= 1
		_update_ui()

func _on_add_mana():
	if player and player.skill_points > 0:
		player.mana += 5
		player.skill_points -= 1
		_update_ui()

func _on_add_speed():
	if player and player.skill_points > 0:
		player.speed += 10
		player.skill_points -= 1
		_update_ui()

func _on_add_ap():
	if player and player.skill_points > 0:
		player.ap += 2
		player.skill_points -= 1
		_update_ui()

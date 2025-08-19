# main_menu.gd
# Script for the main menu screen.

extends Control

@onready var sound_toggle_button: CheckButton = $VBoxContainer/SoundToggleButton
@onready var button_sound = $ButtonSound
@onready var instructions_popup: PanelContainer = $InstructionsPopup
@onready var info_popup: PanelContainer = $InfoPopup
@onready var difficulty_prompt: PanelContainer = $DifficultyPrompt
@onready var same_button: Button = $DifficultyPrompt/VBoxContainer/HBoxContainer/NewButton
@onready var completion_button: Button = $DifficultyPrompt/VBoxContainer/HBoxContainer/CompletionButton
@onready var frustration_button: Button = $DifficultyPrompt/VBoxContainer/HBoxContainer/FrustrationButton

func _ready():
	await Firebase.Auth.login_anonymous()
	if GlobalState.firebase_data.is_empty() or GlobalState.firebase_updated:
		var query = FirestoreQuery.new().from("high_scores")
		GlobalState.firebase_data = await Firebase.Firestore.query(query)
		GlobalState.firebase_data.shuffle()
		_sort_firebase_leaderboard_data()
		GlobalState.firebase_updated = false
	completion_button.pressed.connect(_on_completion_or_frustration_button_pressed.bind("completion"))
	frustration_button.pressed.connect(_on_completion_or_frustration_button_pressed.bind("frustration"))
	_update_sound_button_text()
	sound_toggle_button.button_pressed = GlobalState.is_sound_enabled

# This is the new "quick start" logic.
func _on_start_button_pressed():
	if GlobalState.is_sound_enabled:
		button_sound.play()
	difficulty_prompt.show()

func _on_return_button_pressed():
	if GlobalState.is_sound_enabled:
		button_sound.play()
	difficulty_prompt.hide()

func _on_new_button_pressed():
	GlobalState.mode = "family"
	if GlobalState.is_sound_enabled:
		button_sound.play()
	# 1. Load the raw family data.
	var all_family_data = Utils.load_family_data()
	if all_family_data.is_empty():
		print("Error: Could not load family data to start game.")
		return

	# 2. Generate a random list of confirmed family members.
	var confirmed_family = []
	var family_keys = all_family_data.keys()
	family_keys.shuffle() # Randomize the order of families.
	
	# Decide to generate between 2 and 4 family members.
	var num_members_to_generate = randi_range(2, 4)
	
	# Take a unique slice from the shuffled keys.
	for i in range(min(num_members_to_generate, family_keys.size())):
		var family_key = family_keys[i]
		var data = all_family_data[family_key]
		
		# Randomly choose a gender.
		var gender = "male" if randi() % 2 == 0 else "female"
		var family_name = data.get("default_name_" + gender, "N/A")
		
		# Build the data dictionary for this member.
		confirmed_family.append({
			"name": family_name,
			"family_key": family_key,
			"gender": gender
		})

	# 3. Save the generated list to the GlobalState.
	GlobalState.confirmed_family = confirmed_family
	print("Generated random family: ", confirmed_family)
	GlobalState.initial_difficulty = 3
	
	# 4. Change to the game scene.
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")

func _on_completion_or_frustration_button_pressed(mode: String):
	GlobalState.mode = mode
	if GlobalState.is_sound_enabled:
		button_sound.play()
	Utils.load_completion_or_frustration_mode()
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")

func _on_instructions_button_pressed():
	if GlobalState.is_sound_enabled:
		button_sound.play()
	instructions_popup.show_popup()
	
func _on_button_family_pressed():
	if GlobalState.is_sound_enabled:
		button_sound.play()
	GlobalState.initial_difficulty = 3
	get_tree().change_scene_to_file("res://scenes/family_scene.tscn")	

func _on_sound_toggle_toggled(button_pressed: bool):
	# Update the global state with the new setting.
	GlobalState.is_sound_enabled = button_pressed
	_update_sound_button_text()

func _on_leaderboard_button_pressed():
	if GlobalState.is_sound_enabled:
		button_sound.play()
	instructions_popup.hide()
	info_popup.show_popup()

func _update_sound_button_text():
	if GlobalState.is_sound_enabled:
		button_sound.play()
		sound_toggle_button.text = "Sound On"
	else:
		sound_toggle_button.text = "Sound Off"
		
func _sort_firebase_leaderboard_data():
	var sorted_data = GlobalState.firebase_data.duplicate()
	sorted_data.sort_custom(func(a, b):
		var score_a = a.score
		var score_b = b.score
		if score_a != score_b:
			return score_a > score_b # Higher score first
		else:
			# If scores are tied, the one with the smaller family wins.
			var dist_a = a.family.size()
			var dist_b = b.family.size()
			return dist_a < dist_b
	)
	var top_20 = sorted_data.slice(0, 20)
	# Reset it in case it gets refreshed by the player
	GlobalState.leaders = []
	for entry in top_20:
		var family_size = entry.family.size()
		var names = []
		for member in entry.family:
			names.append(member.get("name", "N/A"))
		names.sort()
		var names_str = ", ".join(names)
		
		GlobalState.leaders.append(
			[family_size, names_str, entry.progress_percent, entry.score]
		)
	print("Leaders:")
	print(GlobalState.leaders)

# main_menu.gd
# Script for the main menu screen.

extends Control

@onready var sound_toggle_button: CheckButton = $VBoxContainer/SoundToggleButton
@onready var button_sound = $ButtonSound
@onready var instructions_popup = $InstructionsPopup
@onready var difficulty_prompt: PanelContainer = $DifficultyPrompt
@onready var same_button: Button = $DifficultyPrompt/VBoxContainer/HBoxContainer/NewButton
@onready var completion_button: Button = $DifficultyPrompt/VBoxContainer/HBoxContainer/CompletionButton
@onready var frustration_button: Button = $DifficultyPrompt/VBoxContainer/HBoxContainer/FrustrationButton

func _ready():
	await Firebase.Auth.login_anonymous()
	var query = FirestoreQuery.new().from("high_scores")
	GlobalState.firebase_data = await Firebase.Firestore.query(query)
	GlobalState.firebase_data.shuffle()
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

func _on_completion_button_pressed():
	if GlobalState.is_sound_enabled:
		button_sound.play()
	
	for document in GlobalState.firebase_data:
		if not GlobalState.used_trip_ids.has(document.doc_name) and document.completed:		
			GlobalState.confirmed_family = document.family
			GlobalState.current_trip_quests = document.quests
			GlobalState.initial_difficulty = document.difficulty
			GlobalState.used_trip_ids.append(document.doc_name)
			print("Loaded completed trip: ", document.doc_name)
			break
	
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")

func _on_frustration_button_pressed():
	if GlobalState.is_sound_enabled:
		button_sound.play()
	
	for document in GlobalState.firebase_data:
		if (
			not GlobalState.used_trip_ids.has(document.doc_name) 
			and document.progress_percent > 0.75
			and not document.completed
		):		
			GlobalState.confirmed_family = document.family
			GlobalState.current_trip_quests = document.quests
			GlobalState.initial_difficulty = document.difficulty
			GlobalState.used_trip_ids.append(document.doc_name)
			print("Loaded completed trip: ", document.doc_name)
			break
	
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

func _update_sound_button_text():
	if GlobalState.is_sound_enabled:
		button_sound.play()
		sound_toggle_button.text = "Sound On"
	else:
		sound_toggle_button.text = "Sound Off"

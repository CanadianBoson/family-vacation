# main_menu.gd
# Script for the main menu screen.

extends Control

# This is the new "quick start" logic.
func _on_start_button_pressed():
	# 1. Load the raw family data.
	var all_family_data = _load_family_data()
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
		var name = data.get("default_name_" + gender, "N/A")
		
		# Build the data dictionary for this member.
		confirmed_family.append({
			"name": name,
			"family_key": family_key,
			"gender": gender
		})

	# 3. Save the generated list to the GlobalState.
	GlobalState.confirmed_family = confirmed_family
	print("Generated random family: ", confirmed_family)
	
	# 4. Change to the game scene.
	get_tree().change_scene_to_file("res://game_scene.tscn")

# This function is called when the 'Instructions' button is pressed.
func _on_instructions_button_pressed():
	var result = get_tree().change_scene_to_file("res://instructions.tscn")
	if result != OK:
		print("Error: Could not load the instructions scene.")

# This function is called when the 'Exit' button is pressed.
func _on_exit_button_pressed():
	# This line quits the application.
	get_tree().quit()
	
func _on_button_family_pressed():
	get_tree().change_scene_to_file("res://family_scene.tscn")	

# Helper function to load the family data from the JSON file.
func _load_family_data() -> Dictionary:
	var file_path = "res://data/families.json"
	if not FileAccess.file_exists(file_path):
		print("Error: Family data file not found at ", file_path)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("families"):
		return json_data.families
	
	return {}

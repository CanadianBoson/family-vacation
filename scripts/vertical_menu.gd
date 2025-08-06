# vertical_menu.gd
# This script dynamically builds a two-column menu from the global game state.
extends Control

const MenuItemScene = preload("res://scenes/menu_item.tscn")

@onready var left_column: VBoxContainer = $ColumnsContainer/LeftColumn
@onready var right_column: VBoxContainer = $ColumnsContainer/RightColumn
@onready var quest_manager: Node = get_tree().get_root().get_node("GameScene/QuestManager")

var ITEM_COLORS = [
	Color.SEA_GREEN, Color.DEEP_SKY_BLUE, Color.HOT_PINK,
	Color.MEDIUM_PURPLE, Color.ORANGE, Color.SANDY_BROWN
]

var image_paths = []

var menu_item_instances = []
var all_quest_data = {}
var all_family_data = {}

func _ready():
	# Remove the _load_image_paths() call
	all_family_data = _load_family_data() # Load the family data
	all_quest_data = _load_all_dropdown_options()
	_build_menu()

func _load_all_dropdown_options() -> Dictionary:
	var file_path = "res://data/dropdown_data.json"
	if not FileAccess.file_exists(file_path): return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("details"):
		return json_data.details
	return {}

# --- New: Public function to allow the game scene to force a refresh ---
func rebuild_menu():
	# Clear old menu items before rebuilding.
	for item in menu_item_instances:
		item.queue_free()
	menu_item_instances.clear()
	_build_menu()
	
func _build_menu():
	# If quests have already been generated for this trip, load them.
	if not GlobalState.current_trip_quests.is_empty():
		_load_menu_from_global_state()
		return

	var confirmed_family = GlobalState.confirmed_family
	var num_members = confirmed_family.size()
	if num_members == 0: return

	var game_difficulty = GlobalState.initial_difficulty * 8
	var difficulty_per_member = int(game_difficulty / float(num_members))
	
	var available_colors = ITEM_COLORS.duplicate()
	available_colors.shuffle()
	var available_dropdown_keys = all_quest_data.keys()
	available_dropdown_keys.shuffle()

	for i in range(num_members):
		var member_data = confirmed_family[i]
		var family_key = member_data.get("family_key")
		
		# Generate the quests for this member.
		var bullet_points_for_item = _select_quests_for_member(family_key, difficulty_per_member, available_dropdown_keys)
		
		# --- New: Store the generated data in GlobalState ---
		GlobalState.current_trip_quests.append({
			"member_data": member_data,
			"quests": bullet_points_for_item
		})
		# ----------------------------------------------------
		
		# Create the UI for the menu item.
		_create_menu_item_ui(i, member_data, bullet_points_for_item, available_colors)

# --- New: Advanced quest selection algorithm ---
func _select_quests_for_member(family_key: String, target_difficulty: int, available_keys: Array) -> Array:
	var selected_quests = []
	var selected_keys = []
	var current_difficulty = 0

	var matching_quests = []
	var other_quests = []
	
	if family_key == "Rando":
		other_quests = available_keys.duplicate()
	else:
		for key in available_keys:
			if all_quest_data[key].get("family") == family_key:
				matching_quests.append(key)
			else:
				other_quests.append(key)

	# Try to fill the difficulty target
	while current_difficulty < target_difficulty and selected_quests.size() < 6:
		var pool_to_use = other_quests
		# 75% chance to pick from matching quests if available
		if randf() < 0.75 and not matching_quests.is_empty():
			pool_to_use = matching_quests
		
		var found_quest = false
		# Iterate through the chosen pool to find a compatible quest
		for quest_key in pool_to_use:
			var quest_data = all_quest_data[quest_key]
			var quest_diff = quest_data.get("difficulty", 0)
			
			# Check if adding this quest would be a good fit
			if current_difficulty + quest_diff <= target_difficulty + 2: # Allow a small overshoot
				var is_compatible = true
				var incompatible_list = quest_data.get("incompatible", [])
				for existing_key in selected_keys:
					if incompatible_list.has(existing_key):
						is_compatible = false
						break
				
				if is_compatible:
					# Add the quest
					quest_data["key"] = quest_key
					selected_quests.append(quest_data)
					selected_keys.append(quest_key)
					current_difficulty += quest_diff
					
					# Remove from all pools to ensure it's not picked again
					available_keys.erase(quest_key)
					matching_quests.erase(quest_key)
					other_quests.erase(quest_key)
					
					found_quest = true
					break # Found a quest for this iteration, break to restart the while loop
		
		# If no suitable quest was found in any pool, we have to stop.
		if not found_quest:
			break

	return selected_quests

func calculate_scores() -> Dictionary:
	var quest_score : int = 0
	var family_score : int = 0
	
	for item in menu_item_instances:
		var all_quests_in_item_satisfied = true
		if item.bullet_points_to_display.is_empty():
			all_quests_in_item_satisfied = false
		for quest_data in item.bullet_points_to_display:
			var quest_key = quest_data.get("key")
			if quest_manager.is_quest_satisfied(quest_key):
				quest_score += quest_data.get("difficulty", 0)
			else:
				all_quests_in_item_satisfied = false
		if all_quests_in_item_satisfied:
			family_score += 5
			
	var total_score = quest_score + family_score
	
	return {
		"quest_score": quest_score,
		"family_score": family_score,
		"total_score": total_score
	}
	
func _load_family_data() -> Dictionary:
	var file_path = "res://data/families.json"
	if not FileAccess.file_exists(file_path): return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("families"):
		return json_data.families
	return {}

func _load_menu_from_global_state():
	var available_colors = ITEM_COLORS.duplicate()
	available_colors.shuffle()
	
	for i in range(GlobalState.current_trip_quests.size()):
		var trip_data = GlobalState.current_trip_quests[i]
		_create_menu_item_ui(i, trip_data.member_data, trip_data.quests, available_colors)

func _create_menu_item_ui(index: int, member_data: Dictionary, quests: Array, available_colors: Array):
	var menu_item = MenuItemScene.instantiate()
	if index % 2 == 0:
		left_column.add_child(menu_item)
	else:
		right_column.add_child(menu_item)
	menu_item_instances.append(menu_item)

	if available_colors.is_empty():
		available_colors = ITEM_COLORS.duplicate()
		available_colors.shuffle()
	var unique_color = available_colors.pop_front()

	var specific_image_path = ""
	var family_key = member_data.get("family_key")
	var gender = member_data.get("gender")
	if all_family_data.has(family_key):
		specific_image_path = all_family_data[family_key].get("image_path_" + gender, "")
		
	menu_item.setup(member_data.name, unique_color, specific_image_path, quests, quest_manager)

func get_max_possible_score() -> int:
	var max_score = 0
	for item in menu_item_instances:
		var all_quests_in_item_satisfied = true
		if item.bullet_points_to_display.is_empty():
			all_quests_in_item_satisfied = false
		for quest_data in item.bullet_points_to_display:
			max_score += quest_data.get("difficulty", 0)
		if all_quests_in_item_satisfied:
			max_score += 5
	return max_score

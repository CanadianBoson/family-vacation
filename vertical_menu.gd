# vertical_menu.gd
# This script dynamically builds a two-column menu from the global game state.
extends Control

const MenuItemScene = preload("res://menu_item.tscn")

@onready var left_column: VBoxContainer = $ColumnsContainer/LeftColumn
@onready var right_column: VBoxContainer = $ColumnsContainer/RightColumn
@onready var quest_manager: Node = get_tree().get_root().get_node("GameScene/QuestManager")

var ITEM_COLORS = [
	Color.html("#4A90E2"), Color.html("#50E3C2"), Color.html("#F5A623"),
	Color.html("#BD10E0"), Color.html("#7ED321"), Color.html("#D0021B")
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

func _build_menu():
	var confirmed_family = GlobalState.confirmed_family
	if confirmed_family.is_empty():
		print("Warning: No confirmed family members found in GlobalState to build menu.")
		return
	
	var available_colors = ITEM_COLORS.duplicate()
	available_colors.shuffle()
	var available_images = image_paths.duplicate()
	available_images.shuffle()
	var available_dropdown_keys = all_quest_data.keys()
	available_dropdown_keys.shuffle()

	for i in range(confirmed_family.size()):
		var member_data = confirmed_family[i]
		var menu_item = MenuItemScene.instantiate()
		
		if i % 2 == 0:
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
			var family_info = all_family_data[family_key]
			specific_image_path = family_info.get("image_path_" + gender, "")
		
		# --- New Weighted and Compatible Quest Selection Logic ---
		var bullet_points_for_item = []
		var selected_quest_keys = []
		var num_to_show = randi_range(2, 3)

		# Separate available quests into matching and other pools.
		var matching_quests = []
		var other_quests = []
		
		if family_key == "Rando":
			other_quests = available_dropdown_keys.duplicate()
		else:
			for key in available_dropdown_keys:
				if all_quest_data[key].get("family") == family_key:
					matching_quests.append(key)
				else:
					other_quests.append(key)

		# Select quests one by one, checking for compatibility.
		for _j in range(num_to_show):
			var quest_pool = []
			# 75% chance to pick from matching quests, 25% from others.
			if randf() < 0.75 and not matching_quests.is_empty():
				quest_pool = matching_quests
			else:
				quest_pool = other_quests

			# Fallback if the preferred pool is empty.
			if quest_pool.is_empty():
				quest_pool = other_quests if quest_pool == matching_quests else matching_quests
			
			if quest_pool.is_empty():
				break # No more quests to assign.

			# Attempt to find a compatible quest from the chosen pool.
			var found_compatible_quest = false
			for quest_key in quest_pool:
				var is_compatible = true
				var incompatible_list = all_quest_data[quest_key].get("incompatible", [])
				# Check against quests already selected for this item.
				for existing_key in selected_quest_keys:
					if incompatible_list.has(existing_key):
						is_compatible = false
						break
				
				if is_compatible:
					selected_quest_keys.append(quest_key)
					# Remove from all pools to ensure uniqueness.
					available_dropdown_keys.erase(quest_key)
					matching_quests.erase(quest_key)
					other_quests.erase(quest_key)
					found_compatible_quest = true
					break # Move to the next quest slot.
			
			if not found_compatible_quest:
				print("Could not find a compatible quest for this slot.")

		# Build the final data list from the selected keys.
		for key in selected_quest_keys:
			var item_data = all_quest_data[key]
			item_data["key"] = key
			bullet_points_for_item.append(item_data)
		# -----------------------------------------------------------
		
		menu_item.setup(member_data.name, unique_color, specific_image_path, bullet_points_for_item, quest_manager)

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

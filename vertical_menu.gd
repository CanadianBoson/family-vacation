# vertical_menu.gd
# This script dynamically builds a two-column vertical menu.
extends Control

const MenuItemScene = preload("res://menu_item.tscn")

# --- Updated: References to the two new column containers ---
@onready var left_column: VBoxContainer = $ColumnsContainer/LeftColumn
@onready var right_column: VBoxContainer = $ColumnsContainer/RightColumn
# -----------------------------------------------------------

@onready var quest_manager: Node = get_tree().get_root().get_node("GameScene/QuestManager")

var ITEM_COLORS = [
	Color.html("#4A90E2"), Color.html("#50E3C2"), Color.html("#F5A623"),
	Color.html("#BD10E0"), Color.html("#7ED321"), Color.html("#D0021B")
]
const IMAGE_FOLDER_PATH = "res://menu_images/"
var image_paths = []

var menu_item_instances = []
var all_quest_data = {}

func _ready():
	_load_image_paths()
	all_quest_data = _load_all_dropdown_options()
	_build_menu()

func _load_image_paths():
	var dir = DirAccess.open(IMAGE_FOLDER_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				image_paths.append(IMAGE_FOLDER_PATH + file_name)
			file_name = dir.get_next()

func _load_all_dropdown_options() -> Dictionary:
	var file_path = "res://dropdown_data.json"
	if not FileAccess.file_exists(file_path): return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("details"):
		return json_data.details
	return {}

func _build_menu():
	var file_path = "res://menu_items.json"
	if not FileAccess.file_exists(file_path): return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) != TYPE_DICTIONARY or not json_data.has("items"): return
	
	var item_texts = json_data.items
	item_texts.shuffle()

	var available_colors = ITEM_COLORS.duplicate()
	available_colors.shuffle()
	var available_images = image_paths.duplicate()
	available_images.shuffle()
	var available_dropdown_keys = all_quest_data.keys()
	available_dropdown_keys.shuffle()

	# --- Updated: Loop with an index to distribute items into columns ---
	for i in range(item_texts.size()):
		var text = item_texts[i]
		var menu_item = MenuItemScene.instantiate()
		
		# Decide which column to add the item to based on the index.
		if i % 2 == 0: # Even numbers (0, 2, 4...) go to the left column.
			left_column.add_child(menu_item)
		else: # Odd numbers (1, 3, 5...) go to the right column.
			right_column.add_child(menu_item)
		
		menu_item_instances.append(menu_item)

		if available_colors.is_empty():
			available_colors = ITEM_COLORS.duplicate()
			available_colors.shuffle()
		var unique_color = available_colors.pop_front()

		var unique_image_path = ""
		if not image_paths.is_empty():
			if available_images.is_empty():
				available_images = image_paths.duplicate()
				available_images.shuffle()
			unique_image_path = available_images.pop_front()
		
		var bullet_points_for_item = []
		var num_to_show = randi_range(2, 3)
		
		if available_dropdown_keys.size() >= num_to_show:
			var selected_keys = available_dropdown_keys.slice(0, num_to_show)
			var is_compatible = true
			
			for key1 in selected_keys:
				var incompatible_list = all_quest_data[key1].get("incompatible", [])
				for key2 in selected_keys:
					if key1 != key2 and incompatible_list.has(key2):
						is_compatible = false
						break
				if not is_compatible:
					break
			
			if is_compatible:
				for j in range(num_to_show):
					var key = available_dropdown_keys.pop_front()
					var item_data = all_quest_data[key]
					item_data["key"] = key
					bullet_points_for_item.append(item_data)
			else:
				var key = available_dropdown_keys.pop_front()
				var item_data = all_quest_data[key]
				item_data["key"] = key
				bullet_points_for_item.append(item_data)
		elif not available_dropdown_keys.is_empty():
			var key = available_dropdown_keys.pop_front()
			var item_data = all_quest_data[key]
			item_data["key"] = key
			bullet_points_for_item.append(item_data)
		
		# --- Updated: Pass the quest_manager reference to the menu item ---
		menu_item.setup(text, unique_color, unique_image_path, bullet_points_for_item, quest_manager)

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
			
	var total_score : int = quest_score + family_score
	
	return {
		"quest_score": quest_score,
		"family_score": family_score,
		"total_score": total_score
	}

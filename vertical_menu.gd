# vertical_menu.gd
# This script dynamically builds a vertical menu from a JSON file,
# ensuring each item gets unique colors, images, and dropdown text.
extends Control

const MenuItemScene = preload("res://menu_item.tscn")

@onready var vbox: VBoxContainer = $MenuVBox

var ITEM_COLORS = [
	Color.html("#4A90E2"), # Blue
	Color.html("#50E3C2"), # Teal
	Color.html("#F5A623"), # Orange
	Color.html("#BD10E0"), # Purple
	Color.html("#7ED321"), # Green
	Color.html("#D0021B")  # Red
]

const IMAGE_FOLDER_PATH = "res://menu_images/"
var image_paths = []

func _ready():
	_load_image_paths()
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
	else:
		print("Error: Could not open image directory at ", IMAGE_FOLDER_PATH)

# This function now loads the main dictionary.
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
	var available_images = image_paths.duplicate()
	available_colors.shuffle()
	available_images.shuffle()
	
	# Load the dropdown data dictionary and get its keys.
	var dropdown_data_dict = _load_all_dropdown_options()
	var available_dropdown_keys = dropdown_data_dict.keys()
	available_dropdown_keys.shuffle()

	for text in item_texts:
		var menu_item = MenuItemScene.instantiate()
		vbox.add_child(menu_item)

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
		
		# Distribute a unique set of bullet point objects to each item.
		var bullet_points_for_item = []
		var num_to_show = randi_range(1, 3)
		for i in range(num_to_show):
			if not available_dropdown_keys.is_empty():
				var key = available_dropdown_keys.pop_front()
				bullet_points_for_item.append(dropdown_data_dict[key])
		
		menu_item.setup(text, unique_color, unique_image_path, bullet_points_for_item)

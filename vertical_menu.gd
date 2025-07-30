# vertical_menu.gd
# This script dynamically builds a vertical menu from a JSON file.
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

func _build_menu():
	var file_path = "res://menu_items.json"
	
	if not FileAccess.file_exists(file_path):
		print("Error: Menu items JSON file not found at ", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)

	if typeof(json_data) != TYPE_DICTIONARY or not json_data.has("items"):
		print("Error: Invalid JSON format in ", file_path)
		return

	var item_texts = json_data.items
	item_texts.shuffle()

	for text in item_texts:
		var menu_item = MenuItemScene.instantiate()
		vbox.add_child(menu_item)

		var random_color = ITEM_COLORS.pick_random()
		var random_image_path = ""
		if not image_paths.is_empty():
			random_image_path = image_paths.pick_random()
		
		menu_item.setup(text, random_color, random_image_path)

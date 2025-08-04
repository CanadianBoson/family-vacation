# family_scene.gd
# This script manages the new three-panel family selection screen with added constraints.
extends Control

# Preload the new scene for the right-hand panel entries.
const ConfirmedItemScene = preload("res://family_item.tscn")

# --- UI Node References for the new 3-panel layout ---
@onready var family_list_vbox: VBoxContainer = $HBoxContainer/LeftPanel/FamilyListVBox
@onready var family_image: TextureRect = $HBoxContainer/MiddlePanel/VBoxContainer/FamilyImage
@onready var gender_toggle_button: CheckButton = $HBoxContainer/MiddlePanel/VBoxContainer/GenderToggle
@onready var name_input: LineEdit = $HBoxContainer/MiddlePanel/VBoxContainer/NameInput
@onready var description_label: Label = $HBoxContainer/MiddlePanel/VBoxContainer/DescriptionLabel
@onready var confirm_button: Button = $HBoxContainer/MiddlePanel/VBoxContainer/ConfirmButton
@onready var confirmed_list_vbox: VBoxContainer = $HBoxContainer/RightPanel/ScrollContainer/ConfirmedListVBox
@onready var back_button: Button = $BackButton

# --- State Variables ---
var _family_data = {}
var _selected_family_key = ""
var _selected_gender = "male"
# --- New: Array to track confirmed names for uniqueness ---
var _confirmed_names = []

func _ready():
	_load_family_data()
	_populate_family_list()
	
	# Connect signals for the middle and back buttons.
	gender_toggle_button.toggled.connect(_on_gender_toggle_toggled)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# --- New: Set the max length for the name input ---
	name_input.max_length = 10
	
	# Select the first family by default to populate the middle panel.
	if not _family_data.is_empty():
		_on_family_selected(_family_data.keys()[0])

# Loads the family data from the JSON file.
func _load_family_data():
	var file_path = "res://data/families.json"
	if not FileAccess.file_exists(file_path): return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("families"):
		_family_data = json_data.families

# Creates the clickable menu in the LeftPanel.
func _populate_family_list():
	for family_key in _family_data.keys():
		var button = Button.new()
		button.text = family_key # Now only shows the key.
		button.pressed.connect(_on_family_selected.bind(family_key))
		family_list_vbox.add_child(button)

# Called when a family button in the LeftPanel is clicked.
func _on_family_selected(family_key: String):
	_selected_family_key = family_key
	_update_middle_panel()

# Called when the GenderToggle button is clicked.
func _on_gender_toggle_toggled(button_pressed: bool):
	_selected_gender = "female" if button_pressed else "male"
	_update_middle_panel()

# Updates the middle panel with the currently selected family's default info.
func _update_middle_panel():
	if _selected_family_key.is_empty() or not _family_data.has(_selected_family_key):
		return

	var data = _family_data[_selected_family_key]
	
	description_label.text = data.get("description", "No description available.")
	
	if _selected_gender == "male":
		name_input.text = data.get("default_name_male", "N/A")
		family_image.texture = load(data.get("image_path_male", ""))
	else: # female
		name_input.text = data.get("default_name_female", "N/A")
		family_image.texture = load(data.get("image_path_female", ""))

# Called when the "Confirm" button is pressed.
func _on_confirm_button_pressed():
	# --- New: Check if the confirmed list is already full ---
	if confirmed_list_vbox.get_child_count() >= 6:
		print("Cannot add more than 6 family members.")
		return
		
	var final_name = name_input.text
	
	# --- New: Check if the name is already in use ---
	if _confirmed_names.has(final_name):
		print("Error: Name '%s' is already in use." % final_name)
		return # Stop execution if the name is a duplicate.
		
	# Create a new instance of our confirmed item scene.
	var new_item = ConfirmedItemScene.instantiate()
	
	var info_text = "%s (%s)" % [final_name, _selected_family_key]
	
	# Set its text and add it to the RightPanel.
	new_item.set_info(info_text)
	confirmed_list_vbox.add_child(new_item)
	
	# --- New: Add the name to our tracking list and connect its delete signal ---
	_confirmed_names.append(final_name)
	new_item.delete_requested.connect(_on_confirmed_item_deleted.bind(new_item, final_name))

# --- New: This function is called when a confirmed item is middle-clicked ---
func _on_confirmed_item_deleted(item_node: Node, name_to_remove: String):
	# Remove the name from our tracking list.
	_confirmed_names.erase(name_to_remove)
	# --- FIX: The parent scene must be responsible for deleting the node. ---
	item_node.queue_free()
	print("Removed '%s' from the confirmed list." % name_to_remove)

# Returns to the main menu.
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")

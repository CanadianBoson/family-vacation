# family_scene.gd
# This script now loads its state from the GlobalState autoload.
extends Control

const ConfirmedItemScene = preload("res://family_item.tscn")

@onready var family_list_vbox: VBoxContainer = $VBoxContainer/HBoxContainer/LeftPanel/FamilyListVBox
@onready var family_image: TextureRect = $VBoxContainer/HBoxContainer/MiddlePanel/VBoxContainer/FamilyImage
@onready var gender_toggle_button: CheckButton = $VBoxContainer/HBoxContainer/MiddlePanel/VBoxContainer/GenderToggle
@onready var name_input: LineEdit = $VBoxContainer/HBoxContainer/MiddlePanel/VBoxContainer/NameInput
@onready var description_label: Label = $VBoxContainer/HBoxContainer/MiddlePanel/VBoxContainer/DescriptionLabel
@onready var confirm_button: Button = $VBoxContainer/HBoxContainer/MiddlePanel/VBoxContainer/ConfirmButton
@onready var confirmed_list_vbox: VBoxContainer = $VBoxContainer/HBoxContainer/RightPanel/ScrollContainer/ConfirmedListVBox
@onready var start_game_button: Button = $VBoxContainer/HBoxContainer/RightPanel/StartGameButton
@onready var back_button: Button = $BackButton
@onready var difficulty_label: Label = $VBoxContainer/DifficultyLabel
@onready var difficulty_slider: HSlider = $VBoxContainer/DifficultySlider
@onready var info_button: Button = $InfoButton
@onready var instructions_popup: PanelContainer = $InstructionsPopupFamily
@onready var warning_label: Label = $WarningLabel
@onready var warning_timer: Timer = $WarningTimer

var _family_data = {}
var _selected_family_key = ""
var _selected_gender = "male"
var _confirmed_family_data = []

func _ready():
	_load_family_data()
	_populate_family_list()
	
	_on_difficulty_slider_value_changed(GlobalState.initial_difficulty)
	gender_toggle_button.toggled.connect(_on_gender_toggle_toggled)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	difficulty_slider.value_changed.connect(_on_difficulty_slider_value_changed)
	warning_timer.timeout.connect(warning_label.hide)
	name_input.max_length = 10
	
	# --- New: Check GlobalState and repopulate the confirmed list ---
	if not GlobalState.confirmed_family.is_empty():
		for member_data in GlobalState.confirmed_family:
			_add_confirmed_member(member_data)
	# ----------------------------------------------------------------
	
	# The Start Game button is now managed by the _update_start_button_visibility function.
	_update_start_button_visibility()
	
	if not _family_data.is_empty():
		_on_family_selected(_family_data.keys()[0])

# --- (Your _load_family_data and _populate_family_list functions are unchanged) ---
func _load_family_data():
	var file_path = "res://data/families.json"
	if not FileAccess.file_exists(file_path): return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("families"):
		_family_data = json_data.families

func _populate_family_list():
	for family_key in _family_data.keys():
		var button = Button.new()
		button.text = family_key
		button.pressed.connect(_on_family_selected.bind(family_key))
		family_list_vbox.add_child(button)

func _on_family_selected(family_key: String):
	_selected_family_key = family_key
	_update_middle_panel()

func _on_gender_toggle_toggled(button_pressed: bool):
	_selected_gender = "female" if button_pressed else "male"
	_update_middle_panel()

func _update_middle_panel():
	if _selected_family_key.is_empty(): return
	var data = _family_data[_selected_family_key]
	description_label.text = data.get("description", "No description available.")
	if _selected_gender == "male":
		name_input.text = data.get("default_name_male", "N/A")
		family_image.texture = load(data.get("image_path_male", ""))
	else:
		name_input.text = data.get("default_name_female", "N/A")
		family_image.texture = load(data.get("image_path_female", ""))

func _on_confirm_button_pressed():
	if confirmed_list_vbox.get_child_count() >= 6: return
	var final_name = name_input.text
	for member in _confirmed_family_data:
		if member.name == final_name: return
		
	var new_member_data = {
		"name": final_name, "family_key": _selected_family_key, "gender": _selected_gender
	}
	_add_confirmed_member(new_member_data)
	# --- New: Validate the slider after adding a member ---
	_validate_slider_value()

# --- New: Refactored helper function to add a confirmed member ---
func _add_confirmed_member(member_data: Dictionary):
	var new_item = ConfirmedItemScene.instantiate()
	var info_text = "%s (%s)" % [member_data.name, member_data.family_key]
	new_item.set_info(info_text)
	confirmed_list_vbox.add_child(new_item)
	_confirmed_family_data.append(member_data)
	new_item.delete_requested.connect(_on_confirmed_item_deleted.bind(new_item, member_data))
	_update_start_button_visibility()

func _on_confirmed_item_deleted(item_node: Node, data_to_remove: Dictionary):
	_confirmed_family_data.erase(data_to_remove)
	item_node.queue_free()
	_update_start_button_visibility()
	# --- New: Validate the slider after removing a member ---
	_validate_slider_value()

# --- New: Helper function to manage the Start Game button's visibility ---
func _update_start_button_visibility():
	if _confirmed_family_data.size() >= 2:
		start_game_button.show()
	else:
		start_game_button.hide()

func _on_start_game_button_pressed():
	GlobalState.current_trip_quests = []
	GlobalState.initial_difficulty = int(difficulty_slider.value)	
	GlobalState.confirmed_family = _confirmed_family_data
	get_tree().change_scene_to_file("res://game_scene.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_difficulty_slider_value_changed(new_value: float):
	var snapped_value = round(new_value)
	var num_members = _confirmed_family_data.size()
	var limit = 10
	var limit_reason = ""
	
	if num_members == 2:
		limit = 6
		limit_reason = " (Max 6 for 2 members)"
	elif num_members == 3:
		limit = 8
		limit_reason = " (Max 8 for 3 members)"
	
	if snapped_value > limit:
		snapped_value = limit
		_flash_warning_text("Difficulty limited to %d for %d members." % [limit, num_members])
	
	difficulty_slider.value = snapped_value
	difficulty_label.text = "Initial Difficulty: %d" % snapped_value

# This function is called when the "Info" button is pressed.
func _on_info_button_pressed():
	instructions_popup.show_popup()

func _validate_slider_value():
	# Trigger the value_changed logic with the slider's current value.
	_on_difficulty_slider_value_changed(difficulty_slider.value)

# --- New: Helper function to show the warning text ---
func _flash_warning_text(text: String):
	warning_label.text = text
	warning_label.show()
	warning_timer.start()

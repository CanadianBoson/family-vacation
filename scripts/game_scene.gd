# GameScene.gd
# This script now handles the full drag-and-drop logic for moving pins.
extends Node2D

var pin_scene = preload("res://scenes/pin.tscn")

signal data_updated

@onready var pins_container = $PinsContainer
@onready var hover_label = $HoverLabel
@onready var grid_overlay = $GridOverlay
@onready var pin_manager = $PinManager
@onready var ledger_manager = $LedgerPanel/LedgerManager
@onready var animation_player = $AnimationPlayer
@onready var quest_manager = $QuestManager
@onready var current_difficulty_label = $ScoreTracker/CurrentDifficultyLabel
@onready var quest_score_label = $ScoreTracker/QuestScoreLabel
@onready var family_score_label = $ScoreTracker/FamilyScoreLabel
@onready var score_value_label = $ScoreTracker/ScoreValueLabel
@onready var max_value_label = $ScoreTracker/MaxValueLabel
@onready var vertical_menu = $VerticalMenu
@onready var detailed_info_box = $DetailedInfoBox
@onready var info_city_name = $DetailedInfoBox/VBoxContainer/CityNameLabel
@onready var info_country = $DetailedInfoBox/VBoxContainer/CountryLabel
@onready var info_lat = $DetailedInfoBox/VBoxContainer/LatLabel
@onready var info_lon = $DetailedInfoBox/VBoxContainer/LonLabel
@onready var info_population = $DetailedInfoBox/VBoxContainer/PopulationLabel
@onready var info_capital = $DetailedInfoBox/VBoxContainer/CapitalLabel
@onready var info_eu = $DetailedInfoBox/VBoxContainer/EULabel
@onready var hover_timer = $HoverTimer
@onready var instructions_button = $MenuButtons/HBoxContainer/LeftColumn/InstructionsButton
@onready var info_popup = $PopupLayer/InfoPopup
@onready var instructions_popup = $PopupLayer/InstructionsPopup
@onready var difficulty_prompt: PanelContainer = $PopupLayer/DifficultyPrompt
@onready var new_trip_button: Button = $MenuButtons/HBoxContainer/LeftColumn/NewTripButton
@onready var easier_button: Button = $PopupLayer/DifficultyPrompt/VBoxContainer/HBoxContainer/EasierButton
@onready var same_button: Button = $PopupLayer/DifficultyPrompt/VBoxContainer/HBoxContainer/SameButton
@onready var harder_button: Button = $PopupLayer/DifficultyPrompt/VBoxContainer/HBoxContainer/HarderButton
@onready var return_button: Button = $PopupLayer/DifficultyPrompt/VBoxContainer/HBoxContainer/ReturnButton
@onready var confirmation_popup: PanelContainer = $PopupLayer/ConfirmationPopup
@onready var family_continue_button: Button = $PopupLayer/ConfirmationPopup/VBoxContainer/HBoxContainer/ContinueButton
@onready var family_return_button: Button = $PopupLayer/ConfirmationPopup/VBoxContainer/HBoxContainer/ReturnButton

var CAR_COLOR = Color.GREEN
var BOAT_COLOR = Color.BLUE
var TRAIN_COLOR = Color.DARK_ORCHID
var PLANE_COLOR = Color.FIREBRICK

const CLICK_RADIUS = 3.0 # Increased radius for easier drag interaction
var currently_hovered_data = null

# --- New: Variables to manage the drag-and-drop state ---
var is_dragging = false
var dragged_pin_index = -1
var dragged_pin_node: Node2D = null
var dragged_pin_mouse_pos = Vector2.ZERO
# --------------------------------------------------------
var max_score = 0
var best_path_data = []
var best_path_distance = INF # Initialize to infinity for easy comparison

# --- New: State variable to pause the max score prompt ---
var _prompt_paused = false

func _ready():
	pin_manager.initialize(pins_container, pin_scene)
	quest_manager.pin_manager = pin_manager
	hover_timer.wait_time = 1.0
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	new_trip_button.pressed.connect(_on_new_trip_button_pressed)
	easier_button.pressed.connect(_on_difficulty_chosen.bind(-1))
	same_button.pressed.connect(_on_difficulty_chosen.bind(0))
	harder_button.pressed.connect(_on_difficulty_chosen.bind(1))
	return_button.pressed.connect(_on_return_button_pressed)
	family_return_button.pressed.connect(confirmation_popup.hide)
	_update_game_state()
	hover_label.hide()
	detailed_info_box.hide()

func _update_game_state():
	var num_items = vertical_menu.menu_item_instances.size()
	ledger_manager.update_ledger_display(pin_manager, num_items)
	queue_redraw()
	quest_manager.check_all_conditions(pin_manager.dropped_pin_data, pin_manager.valid_pin_locations, num_items)
	var scores = vertical_menu.calculate_scores()
	quest_score_label.text = "Quest Score: " + str(scores["quest_score"])
	family_score_label.text = "Family Score: " + str(scores["family_score"])
	score_value_label.text = "Total Score: " + str(scores["total_score"])
	current_difficulty_label.text = "Current Difficulty: " + str(GlobalState.initial_difficulty)
	# --- New: Check if the current path is the new best path ---
	var current_path = pin_manager.dropped_pin_data
	
	# If the current score is higher, it's the new best.
	if scores.total_score > max_score:
		max_score = scores.total_score
		best_path_data = current_path.duplicate(true)
		best_path_distance = ledger_manager.calculate_total_distance(best_path_data)
		max_value_label.text = "Max Score: " + str(max_score)
	# If scores are tied, check if the new path is shorter.
	elif scores.total_score == max_score and scores.total_score > 0:
		var current_distance = ledger_manager.calculate_total_distance(current_path)
		if current_distance < best_path_distance:
			best_path_data = current_path.duplicate(true)
			best_path_distance = current_distance
			print("New best path found with same score but shorter distance.")
	# -----------------------------------------------------------
	
	var max_score = vertical_menu.get_max_possible_score()
	if max_score > 0 and scores.total_score == max_score and not _prompt_paused:
		print("Max score reached! Showing difficulty prompt.")
		difficulty_prompt.show()
	
	data_updated.emit()

# This function is called for every input event.
func _unhandled_input(event: InputEvent):
	var mouse_pos = get_global_mouse_position()

	# --- Drag-and-Drop Logic ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# Check if the click is on an existing pin to start a drag.
			for i in range(pin_manager.dropped_pin_data.size()):
				var pin_data = pin_manager.dropped_pin_data[i]
				if mouse_pos.distance_to(pin_data.position) <= CLICK_RADIUS:
					is_dragging = true
					dragged_pin_index = i
					# disable hover text
					hover_timer.stop()
					hover_label.hide()
					detailed_info_box.hide()
					# Find the actual pin node in the scene.
					for child in pins_container.get_children():
						if child.position == pin_data.position:
							dragged_pin_node = child
							break
					if dragged_pin_node:
						dragged_pin_node.hide() # Hide the real pin during drag.
					return # Stop further input processing.
			
			# If not dragging, try to place a new pin.
			if pin_manager.place_pin_at_click(mouse_pos, CLICK_RADIUS):
				_update_game_state()

		else: # Mouse button was released.
			if is_dragging:
				# Check for a valid drop target.
				var drop_target_data = pin_manager.get_hovered_location(mouse_pos, CLICK_RADIUS)
				var successful_drop = false
				
				if drop_target_data and not drop_target_data.placed:
					# If we dropped on a valid, unoccupied spot, update the pin.
					if pin_manager.update_pin_at_index(dragged_pin_index, drop_target_data):
						dragged_pin_node.position = drop_target_data.position
						successful_drop = true
				
				if not successful_drop:
					# If the drop was invalid, snap the pin back to its original position.
					var original_pos = pin_manager.dropped_pin_data[dragged_pin_index].position
					dragged_pin_node.position = original_pos
				
				dragged_pin_node.show() # Show the pin again.
				
				# Reset all drag state variables.
				is_dragging = false
				dragged_pin_index = -1
				dragged_pin_node = null
				
				# Update the entire game state after the drop.
				_update_game_state()

	# Handle right-click to remove pins (no change here).
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		if pin_manager.remove_pin_at_click(mouse_pos, CLICK_RADIUS):
			_update_game_state()

	# Handle mouse motion for dragging and hovering.
	elif event is InputEventMouseMotion:
		if is_dragging:
			# If dragging, update the mouse position for the drawer and redraw.
			dragged_pin_mouse_pos = mouse_pos
			queue_redraw()
		else:
			# Standard hover logic.
			var hovered_data = pin_manager.get_hovered_location(mouse_pos, CLICK_RADIUS)
			if hovered_data != currently_hovered_data:
				currently_hovered_data = hovered_data
				if hovered_data:
					hover_label.text = hovered_data.city
					hover_label.add_theme_color_override("font_color", Color.DARK_BLUE)
					hover_label.show()
					detailed_info_box.hide()
					hover_timer.start()
				else:
					hover_label.hide()
					detailed_info_box.hide()
					hover_timer.stop()
			
			if hovered_data:
				hover_label.position = mouse_pos + Vector2(15, -10)
				_update_detailed_box_position()

# This function is called when the node needs to be drawn.
func _draw():
	# Draw circles for valid pin locations
	for location_data in pin_manager.valid_pin_locations:
		# Don't draw a circle for the pin being dragged from its original spot.
		if is_dragging and pin_manager.dropped_pin_data[dragged_pin_index].position == location_data.position:
			continue
			
		var circle_color = Color.BLACK
		if location_data.placed:
			circle_color = Color.DARK_GRAY
		
		draw_circle(location_data.position, CLICK_RADIUS, circle_color)

	# Draw lines connecting dropped pins
	if pin_manager.dropped_pin_data.size() >= 2:
		for i in range(pin_manager.dropped_pin_data.size() - 1):
			var pin1_data = pin_manager.dropped_pin_data[i]
			var pin2_data = pin_manager.dropped_pin_data[i+1]
			
			var start_point = pin1_data.position
			var end_point = pin2_data.position
			
			# If dragging, update the line endpoints dynamically
			if is_dragging:
				if i == dragged_pin_index:
					end_point = dragged_pin_mouse_pos
				elif i + 1 == dragged_pin_index:
					start_point = dragged_pin_mouse_pos
			
			var travel_mode = pin_manager.get_travel_mode(pin1_data.index, pin2_data.index)
			var line_color = PLANE_COLOR
			match travel_mode:
				0: line_color = CAR_COLOR
				1: line_color = BOAT_COLOR
				2: line_color = TRAIN_COLOR
			
			draw_line(start_point, end_point, line_color, 2)

# --- (The rest of your script, including hover logic, is unchanged) ---
func _on_hover_timer_timeout():
	if currently_hovered_data:
		hover_label.hide()
		_populate_detailed_info(currently_hovered_data)
		_update_detailed_box_position()
		detailed_info_box.show()

func _populate_detailed_info(data):
	info_city_name.text = data.get("city", "N/A")
	info_country.text = "Country: " + data.get("country", "N/A")
	info_lat.text = "Latitude: " + str(data.get("lat"))
	info_lon.text = "Longitude: " + str(data.get("lng"))
	var pop_val = data.get("population", 0)
	info_population.text = "Population: " + str(int(pop_val / 1000)) + "k"
	var is_capital_text = "Yes" if data.get("is_capital", false) else "No"
	info_capital.text = "Capital: " + is_capital_text
	var is_eu_text = "Yes" if data.get("is_eu", false) else "No"
	info_eu.text = "EU: " + is_eu_text

func _update_detailed_box_position():
	var mouse_pos = get_global_mouse_position()
	var screen_height = get_viewport_rect().size.y
	var box_size = detailed_info_box.size
	var new_pos = Vector2()
	if mouse_pos.y > screen_height / 2:
		new_pos = mouse_pos + Vector2(15, -box_size.y - 15)
	else:
		new_pos = mouse_pos + Vector2(15, 15)
	detailed_info_box.position = new_pos

func _on_clear_all_button_pressed():
	pin_manager.clear_all_pins()
	_update_game_state()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_grid_toggle_button_toggled(button_pressed: bool):
	grid_overlay.set_visibility(button_pressed)

func _on_reverse_button_pressed():
	pin_manager.reverse_path()
	_update_game_state()
	
# This function is called when the "Load Best Path" button is pressed.
func _on_load_max_path_button_pressed():
	if not best_path_data.is_empty():
		pin_manager.load_path(best_path_data)
		# After loading the path, update the entire game state.
		_update_game_state()

# This function is called when the "Family" button is pressed.
func _on_family_button_pressed():
	confirmation_popup.show()

# This function is called when the "Info" button is pressed.
func _on_info_button_pressed():
	# --- New: Close the instructions popup first ---
	instructions_popup.hide()
	# ---------------------------------------------
	info_popup.show_popup(pin_manager.valid_pin_locations, pin_manager.dropped_pin_data)

# ... (rest of your script)

# This function is called when the "Instructions" button is pressed.
func _on_instructions_button_pressed():
	# --- New: Close the info popup first ---
	info_popup.hide()
	# -------------------------------------
	instructions_popup.show_popup()

# --- New function to show the prompt ---
func _on_new_trip_button_pressed():
	_prompt_paused = false
	difficulty_prompt.show()
	
# --- New function to handle the difficulty choice ---
func _on_difficulty_chosen(adjustment: int):
	# --- New: Check party size to determine the upper difficulty limit ---
	var num_members = GlobalState.confirmed_family.size()
	var upper_limit = 10
	
	if num_members == 2:
		upper_limit = 6
	elif num_members == 3:
		upper_limit = 8
	# -----------------------------------------------------------------
	
	# Adjust and clamp the difficulty using the new upper limit.
	var new_difficulty = GlobalState.initial_difficulty + adjustment
	GlobalState.initial_difficulty = clamp(new_difficulty, 1, upper_limit)
	
	# Clear the old quest data to force a regeneration.
	GlobalState.current_trip_quests = []
	
	# Tell the vertical menu to rebuild itself with new quests.
	vertical_menu.rebuild_menu()
	
	# After rebuilding, we need to update the game state to reflect the new quests.
	max_score = 0
	best_path_data = []
	var best_path_distance = INF
	max_value_label.text = "Max Score: " + str(max_score)
	pin_manager.clear_all_pins()
	_update_game_state()
	
	# Hide the prompt.
	difficulty_prompt.hide()
	_prompt_paused = false

# --- New: This function is called when the "Return" button is pressed ---
func _on_return_button_pressed():
	difficulty_prompt.hide()
	# Pause the prompt from showing again until a new trip is started.
	_prompt_paused = true

func _on_continue_button_pressed():
	# Hide the popup and then change the scene.
	confirmation_popup.hide()
	get_tree().change_scene_to_file("res://scenes/family_scene.tscn")

# GameScene.gd
# ... (all your existing code at the top remains the same) ...

extends Node2D

# Preload the Pin scene so we can create instances of it.
var pin_scene = preload("res://pin.tscn")

# This node will hold all the pins that are dropped on the map.
@onready var pins_container = $PinsContainer
# This node will be used to display the city name on hover.
@onready var hover_label = $HoverLabel

# Grid overlay
@onready var grid_overlay = $GridOverlay

# References to our manager scripts
@onready var pin_manager = $PinManager
@onready var ledger_manager = $LedgerPanel/LedgerManager

# --- New Node References ---
@onready var info_popup = $InfoPopup
@onready var animation_player = $AnimationPlayer
# -------------------------


var CAR_COLOR = Color.GREEN  # Green
var BOAT_COLOR = Color.BLUE  # Blue
var TRAIN_COLOR = Color.DARK_ORCHID
var PLANE_COLOR = Color.FIREBRICK # Red

# This defines how close (in pixels) the user must click to a valid spot.
const CLICK_RADIUS = 3.0

# Store the currently hovered location data to display its city.
var hovered_location_data = null

# The _ready function is called once when the node enters the scene tree.
func _ready():
	# print the scene tree for Gemini
	# _print_tree_with_types(self)
	# Initialize PinManager with the pins_container reference
	pin_manager.initialize(pins_container, pin_scene)
	
	# Load pin locations via PinManager
	pin_manager._load_pin_locations()
	
	# Request a redraw after loading locations to show the circles.
	queue_redraw()
	
	# Ensure the hover label is hidden initially.
	hover_label.hide()
	
	# Update the ledger display initially
	ledger_manager.update_ledger_display(pin_manager)

func _print_tree_with_types(node, indent=""):
	# Print the node's name and its class/type
	print(indent + "- " + node.name + " (" + node.get_class() + ")")
	# Recursively call for each child
	for child in node.get_children():
		_print_tree_with_types(child, indent + "  ")

# This function is called for every input event.
func _unhandled_input(event):
	var click_position = event.position
	
	# Handle mouse clicks for dropping/removing pins.
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Left-click to place a pin
			var placed = pin_manager.place_pin_at_click(click_position, CLICK_RADIUS)
			if placed:
				ledger_manager.update_ledger_display(pin_manager)
				queue_redraw() # Redraw to show new line
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right-click to remove a pin and its connecting lines
			var removed = pin_manager.remove_pin_at_click(click_position, CLICK_RADIUS)
			if removed:
				ledger_manager.update_ledger_display(pin_manager)
				queue_redraw() # Redraw to update lines and circle color
	
	# Handle mouse motion for hovering and displaying city names.
	if event is InputEventMouseMotion:
		var mouse_position = event.position
		var hovered_data = pin_manager.get_hovered_location(mouse_position, CLICK_RADIUS)
		
		if hovered_data:
			hover_label.text = hovered_data.city
			hover_label.set("theme_override_colors/font_color", Color.DARK_ORCHID)
			hover_label.position = mouse_position + Vector2(15, -10) # Offset label
			hover_label.show()
		else:
			hover_label.hide()

# This function is called when the node needs to be drawn.
func _draw():
	# Draw circles for valid pin locations
	for location_data in pin_manager.valid_pin_locations:
		var circle_color = Color.BLACK
		if location_data.placed:
			circle_color = Color.DARK_GRAY # Example: Make it darker when a pin is there
		
		draw_circle(location_data.position, CLICK_RADIUS, circle_color)

	# Draw lines connecting dropped pins
	if pin_manager.dropped_pin_data.size() >= 2:
		for i in range(pin_manager.dropped_pin_data.size() - 1):
			var pin1_data = pin_manager.dropped_pin_data[i]
			var pin2_data = pin_manager.dropped_pin_data[i+1]
			var start_point = pin1_data.position
			var end_point = pin2_data.position
			# Get the travel mode using the cities' indices
			var travel_mode = pin_manager.get_travel_mode(pin1_data.index, pin2_data.index)
			# Select the line color based on the travel mode
			var line_color = PLANE_COLOR # Default color
			match travel_mode:
				0: # Car
					line_color = CAR_COLOR
				1: # Boat
					line_color = BOAT_COLOR
				2: # Train
					line_color = TRAIN_COLOR
			
			draw_line(start_point, end_point, line_color, 2)

# This function is called when the "Info" button is pressed.
func _on_info_button_pressed():
	# We pass all the valid location data from PinManager to the popup.
	info_popup.show_popup(pin_manager.dropped_pin_data)

# --- Existing Signal Handlers (Make sure they are still there) ---

func _on_clear_all_button_pressed():
	print("Clear All button pressed!")
	pin_manager.clear_all_pins()
	ledger_manager.update_ledger_display(pin_manager)
	queue_redraw()

func _on_back_button_pressed():
	var result = get_tree().change_scene_to_file("res://main_menu.tscn")
	if result != OK:
		print("Error: Could not load the main menu scene.")

# This function is called when the GridToggleButton's state changes.
func _on_grid_toggle_button_toggled(button_pressed: bool):
	# Pass the button's state (true for on, false for off)
	# to the GridOverlay script.
	grid_overlay.set_visibility(button_pressed)

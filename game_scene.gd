# GameScene.gd
# This script handles the main game screen, which displays a map
# and allows the user to drop pins on it at specific, pre-determined locations.
# Attach this script to the root Node2D of your game scene.

extends Node2D

# Preload the Pin scene so we can create instances of it.
var pin_scene = preload("res://pin.tscn")

# This node will hold all the pins that are dropped on the map.
@onready var pins_container = $PinsContainer
# This node will be used to display the city name on hover.
@onready var hover_label = $HoverLabel # Assuming you have a Label node named HoverLabel

# References to our new manager scripts
@onready var pin_manager = $PinManager # Assuming PinManager is a child of GameScene
@onready var ledger_manager = $LedgerPanel/LedgerManager # Assuming LedgerManager is a child of LedgerPanel

# This defines how close (in pixels) the user must click to a valid spot.
const CLICK_RADIUS = 3.0

# Store the currently hovered location data to display its city.
var hovered_location_data = null

# The _ready function is called once when the node enters the scene tree.
func _ready():
	# Initialize PinManager with the pins_container reference
	pin_manager.initialize(pins_container, pin_scene)
	
	# Load pin locations via PinManager
	pin_manager.load_pin_locations()
	
	# Request a redraw after loading locations to show the circles.
	queue_redraw()
	
	# Ensure the hover label is hidden initially.
	hover_label.hide()
	
	# Update the ledger display initially
	ledger_manager.update_ledger_display(pin_manager.dropped_pin_data)


# This function is called for every input event.
func _unhandled_input(event):
	var click_position = event.position
	
	# Handle mouse clicks for dropping/removing pins.
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Left-click to place a pin
			var placed = pin_manager.place_pin_at_click(click_position, CLICK_RADIUS)
			if placed:
				ledger_manager.update_ledger_display(pin_manager.dropped_pin_data)
				queue_redraw() # Redraw to show new line
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right-click to remove a pin and its connecting lines
			var removed = pin_manager.remove_pin_at_click(click_position, CLICK_RADIUS)
			if removed:
				ledger_manager.update_ledger_display(pin_manager.dropped_pin_data)
				queue_redraw() # Redraw to update lines and circle color
	
	# Handle mouse motion for hovering and displaying city names.
	if event is InputEventMouseMotion:
		var mouse_position = event.position
		var hovered_data = pin_manager.get_hovered_location(mouse_position, CLICK_RADIUS)
		
		if hovered_data:
			hover_label.text = hovered_data.city
			hover_label.set("theme_override_colors/font_color", Color.DARK_ORCHID)
			hover_label.position = mouse_position + Vector2(15, 15) # Offset label
			hover_label.show()
		else:
			hover_label.hide()

# New function: Called when the "Clear All" button is pressed
func _on_clear_all_button_pressed():
	print("Clear All button pressed!")
	pin_manager.clear_all_pins() # Clear pins and data in PinManager
	ledger_manager.update_ledger_display(pin_manager.dropped_pin_data) # Update ledger
	queue_redraw() # Redraw the map to remove lines and reset circle colors


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
			var start_point = pin_manager.dropped_pin_data[i].position
			var end_point = pin_manager.dropped_pin_data[i+1].position
			# Draw a thin red line with a thickness of 2 pixels
			draw_line(start_point, end_point, Color.RED, 2)

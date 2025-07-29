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

# This array will store the valid locations loaded from the JSON file.
var valid_pin_locations = []
# This defines how close (in pixels) the user must click to a valid spot.
const CLICK_RADIUS = 3.0

# Store the currently hovered location data to display its city.
var hovered_location_data = null

# The _ready function is called once when the node enters the scene tree.
# We use it to load our database of pin locations.
func _ready():
	load_pin_locations()
	# Request a redraw after loading locations to show the circles.
	queue_redraw()
	# Ensure the hover label is hidden initially.
	hover_label.hide()

# This function loads the coordinates from our JSON "database".
func load_pin_locations():
	var file_path = "res://locations.json"
	
	# Check if the file exists before trying to open it.
	if not FileAccess.file_exists(file_path):
		print("Error: Pin locations file not found at ", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)

	# Check if the JSON was parsed correctly.
	if typeof(json_data) != TYPE_DICTIONARY or not json_data.has("locations"):
		print("Error: Invalid JSON format in ", file_path)
		return

	# Loop through the locations in the JSON and add them to our array.
	# We also add a "placed" flag to prevent dropping multiple pins in the same spot.
	for location in json_data.locations:
		var pos = Vector2(location.x, location.y)
		# Ensure 'city' key exists, default to empty string if not.
		var city_name = location.get("city", "") 
		valid_pin_locations.append({"position": pos, "placed": false, "city": city_name})
	
	print("Successfully loaded ", valid_pin_locations.size(), " pin locations.")

# This function is called for every input event.
func _unhandled_input(event):
	# Handle mouse clicks for dropping pins.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var click_position = event.position
		
		for location_data in valid_pin_locations:
			if not location_data.placed:
				var distance = click_position.distance_to(location_data.position)
				
				if distance <= CLICK_RADIUS:
					place_pin(location_data.position)
					location_data.placed = true
					# No redraw needed here if circles always stay.
					# But if you want a visual change (e.g., circle color changes), call queue_redraw().
					break
	
	# Handle mouse motion for hovering and displaying city names.
	if event is InputEventMouseMotion:
		var mouse_position = event.position
		var found_hover_location = false
		
		for location_data in valid_pin_locations:
			var distance = mouse_position.distance_to(location_data.position)
			if distance <= CLICK_RADIUS:
				hovered_location_data = location_data
				hover_label.text = location_data.city
				hover_label.set("theme_override_colors/font_color", Color.DARK_ORCHID)
				hover_label.position = mouse_position + Vector2(10, 10) # Offset label
				hover_label.show()
				found_hover_location = true
				break # Found a location to hover over, no need to check others.
		
		if not found_hover_location:
			hovered_location_data = null
			hover_label.hide()


# This function creates a new pin and places it on the map.
func place_pin(position):
	# Create a new instance of our preloaded Pin scene.
	var new_pin = pin_scene.instantiate()
	
	# Set the position of the new pin to the exact location from the database.
	new_pin.position = position
	
	# Add the new pin as a child of the PinsContainer node.
	pins_container.add_child(new_pin)
	
	print("Pin placed at valid location: ", position)

# This function is called when the node needs to be drawn.
func _draw():
	# Iterate through all valid locations and draw a circle around them.
	# Circles no longer disappear after a pin is placed.
	for location_data in valid_pin_locations:
		# You can change the circle color if a pin is placed for visual feedback
		var circle_color = Color.BLACK
		if location_data.placed:
			circle_color = Color.DARK_GRAY # Example: Make it darker when a pin is there
		
		draw_circle(location_data.position, CLICK_RADIUS, circle_color)

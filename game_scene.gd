# GameScene.gd
# This script handles the main game screen, which displays a map
# and allows the user to drop pins on it at specific, pre-determined locations.
# Attach this script to the root Node2D of your game scene.

extends Node2D

# Preload the Pin scene so we can create instances of it.
var pin_scene = preload("res://pin.tscn")

# This node will hold all the pins that are dropped on the map.
@onready var pins_container = $PinsContainer

# This array will store the valid locations loaded from the JSON file.
var valid_pin_locations = []
# This defines how close (in pixels) the user must click to a valid spot.
const CLICK_RADIUS = 10.0

# The _ready function is called once when the node enters the scene tree.
# We use it to load our database of pin locations.
func _ready():
	load_pin_locations()
	# Request a redraw after loading locations to show the circles.
	queue_redraw()

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
		valid_pin_locations.append({"position": pos, "placed": false})
	
	print("Successfully loaded ", valid_pin_locations.size(), " pin locations.")

# This function is called for every input event.
func _unhandled_input(event):
	# Check if the input event is a left mouse button click.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var click_position = event.position
		
		# Iterate through all valid locations to see if the click is close enough.
		for location_data in valid_pin_locations:
			# Only check spots that don't already have a pin.
			if not location_data.placed:
				var distance = click_position.distance_to(location_data.position)
				
				# If the click is within the radius of a valid spot...
				if distance <= CLICK_RADIUS:
					# ...place a pin there and mark it as placed.
					place_pin(location_data.position)
					location_data.placed = true
					# Request a redraw to remove the circle from the placed location.
					queue_redraw() 
					# Stop checking so we don't place multiple pins for one click.
					break

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
	# Iterate through all valid locations and draw a circle around unplaced ones.
	for location_data in valid_pin_locations:
		if not location_data.placed:
			# Draw a filled black circle.
			draw_circle(location_data.position, CLICK_RADIUS, "black")

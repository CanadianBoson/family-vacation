# PinManager.gd
# This script manages all pin-related data and node instantiation/removal.
extends Node

# Reference to the PinsContainer node in the main scene
var _pins_container: Node2D
# Preloaded Pin scene
var _pin_scene: PackedScene

# This array will store the valid locations loaded from the JSON file.
# Each item will now include 'lat' and 'lng' for distance calculations.
var valid_pin_locations = []
# Store the full data (including lat, lng, city, position) of all dropped pins
var dropped_pin_data = []

# Earth's radius in kilometers for Haversine formula (moved here for completeness, though LedgerManager uses it)
const EARTH_RADIUS_KM = 6371.0

# Initialize the PinManager with necessary scene references
func initialize(pins_container_node: Node2D, pin_packed_scene: PackedScene):
	_pins_container = pins_container_node
	_pin_scene = pin_packed_scene

# This function loads the coordinates from our JSON "database".
func load_pin_locations():
	var file_path = "res://locations.json"
	
	if not FileAccess.file_exists(file_path):
		print("Error: Pin locations file not found at ", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)

	if typeof(json_data) != TYPE_DICTIONARY or not json_data.has("locations"):
		print("Error: Invalid JSON format in ", file_path)
		return

	for location in json_data.locations:
		var pos = Vector2(location.x, location.y)
		var city_name = location.get("city", "")
		var lat_val = float(location.get("lat", 0.0)) 
		var lng_val = float(location.get("lng", 0.0)) 
		
		valid_pin_locations.append({
			"position": pos,
			"placed": false,
			"city": city_name,
			"lat": lat_val,
			"lng": lng_val,
			"country": location.get("iso2", ""),
		})
	
	print("Successfully loaded %d pin locations." % valid_pin_locations.size())

# Places a pin if the click is within a valid, unplaced location.
# Returns true if a pin was placed, false otherwise.
func place_pin_at_click(click_position: Vector2, click_radius: float) -> bool:
	for location_data in valid_pin_locations:
		if not location_data.placed:
			var distance = click_position.distance_to(location_data.position)
			
			if distance <= click_radius:
				_instantiate_pin_node(location_data.position)
				location_data.placed = true
				dropped_pin_data.append(location_data)
				print("Pin placed at valid location: %s" % location_data.position)
				return true
	return false

# Removes a pin if the click is within an already placed pin.
# Returns true if a pin was removed, false otherwise.
func remove_pin_at_click(click_position: Vector2, click_radius: float) -> bool:
	var removed_pin_index = -1
	for i in range(dropped_pin_data.size()):
		var pin_pos = dropped_pin_data[i].position
		var distance = click_position.distance_to(pin_pos)
		
		if distance <= click_radius:
			removed_pin_index = i
			break
	
	if removed_pin_index != -1:
		var removed_data = dropped_pin_data.pop_at(removed_pin_index)
		var removed_pos = removed_data.position
		
		# Mark the corresponding location in valid_pin_locations as unplaced
		for location_data in valid_pin_locations:
			if location_data.position == removed_pos:
				location_data.placed = false
				break
		
		# Remove the actual pin node from the scene
		var pin_node_to_remove = null
		for child in _pins_container.get_children():
			if child.position == removed_pos:
				pin_node_to_remove = child
				break
		
		if pin_node_to_remove:
			pin_node_to_remove.queue_free()
			print("Pin node freed at: %s" % removed_pos)
		else:
			print("Warning: Could not find pin node to free at: %s" % removed_pos)
		
		return true
	return false

# Instantiates a new Pin scene and adds it to the pins_container.
func _instantiate_pin_node(position: Vector2):
	var new_pin = _pin_scene.instantiate()
	new_pin.position = position
	_pins_container.add_child(new_pin)

# Returns the location data of a hovered pin, or null if none.
func get_hovered_location(mouse_position: Vector2, click_radius: float):
	for location_data in valid_pin_locations:
		var distance = mouse_position.distance_to(location_data.position)
		if distance <= click_radius:
			return location_data
	return null

# New function: Clears all dropped pins and resets their states
func clear_all_pins():
	# Remove all pin nodes from the scene
	for child in _pins_container.get_children():
		child.queue_free()
	
	# Clear the dropped pin data
	dropped_pin_data.clear()
	
	# Reset the 'placed' status for all valid pin locations
	for location_data in valid_pin_locations:
		location_data.placed = false
	
	print("All pins and paths cleared.")

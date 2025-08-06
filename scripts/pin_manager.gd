# pin_manager.gd
# This script now includes a function to update a pin's location.
extends Node

var _pins_container: Node2D
var _pin_scene: PackedScene

var valid_pin_locations = []
var dropped_pin_data = []
var travel_matrix = []

func initialize(pins_container_node: Node2D, pin_packed_scene: PackedScene):
	_pins_container = pins_container_node
	_pin_scene = pin_packed_scene
	_load_pin_locations()
	_load_travel_matrix()

func update_pin_at_index(index: int, new_location_data: Dictionary) -> bool:
	if index < 0 or index >= dropped_pin_data.size():
		return false

	# Get the old location data that we are moving from.
	var old_location_data = dropped_pin_data[index]

	# Find the old location in the main list and mark it as unplaced.
	for location in valid_pin_locations:
		if location.position == old_location_data.position:
			location.placed = false
			break
	
	# Find the new location in the main list and mark it as placed.
	for location in valid_pin_locations:
		if location.position == new_location_data.position:
			location.placed = true
			break

	# Replace the old data with the new data in the dropped pins array.
	dropped_pin_data[index] = new_location_data
	return true

func _load_pin_locations():
	var file_path = "res://data/locations.json"
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
		valid_pin_locations.append({
			"position": Vector2(location.x, location.y),
			"placed": false,
			"city": location.get("city", ""),
			"lat": float(location.get("lat", 0.0)),
			"lng": float(location.get("lng", 0.0)),
			"country": location.get("country"),
			"population": int(location.get("population")),
			"is_capital": bool(location.get("is_capital")),
			"is_eu": bool(location.get("is_eu")),
			"index": int(location.get("index", -1))
		})

func _load_travel_matrix():
	var file_path = "res://data/travel_matrix.json"
	if not FileAccess.file_exists(file_path):
		print("Error: Travel matrix file not found at ", file_path)
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("matrix"):
		travel_matrix = json_data.matrix

func place_pin_at_click(click_position: Vector2, click_radius: float) -> bool:
	for location_data in valid_pin_locations:
		if not location_data.placed:
			if click_position.distance_to(location_data.position) <= click_radius:
				_instantiate_pin_node(location_data.position)
				location_data.placed = true
				dropped_pin_data.append(location_data)
				return true
	return false

func remove_pin_at_click(click_position: Vector2, click_radius: float) -> bool:
	var removed_pin_index = -1
	for i in range(dropped_pin_data.size()):
		if click_position.distance_to(dropped_pin_data[i].position) <= click_radius:
			removed_pin_index = i
			break
	if removed_pin_index != -1:
		var removed_data = dropped_pin_data.pop_at(removed_pin_index)
		for location_data in valid_pin_locations:
			if location_data.position == removed_data.position:
				location_data.placed = false
				break
		for child in _pins_container.get_children():
			if child.position == removed_data.position:
				child.queue_free()
				break
		return true
	return false
	
# Clears the current path and loads a new one from a data array.
func load_path(path_data: Array):
	# Clear all existing pins and reset their 'placed' status.
	clear_all_pins()
	
	# Set the new path data. Use a deep duplicate to avoid reference issues.
	dropped_pin_data = path_data.duplicate(true)
	
	# Recreate the pin nodes and update the 'placed' status in the main list.
	for pin_data in dropped_pin_data:
		_instantiate_pin_node(pin_data.position)
		for location in valid_pin_locations:
			if location.position == pin_data.position:
				location.placed = true
				break	

func _instantiate_pin_node(position: Vector2):
	var new_pin = _pin_scene.instantiate()
	new_pin.position = position
	_pins_container.add_child(new_pin)

func get_hovered_location(mouse_position: Vector2, click_radius: float):
	for location_data in valid_pin_locations:
		if mouse_position.distance_to(location_data.position) <= click_radius:
			return location_data
	return null

func clear_all_pins():
	for child in _pins_container.get_children():
		child.queue_free()
	dropped_pin_data.clear()
	for location_data in valid_pin_locations:
		location_data.placed = false

func get_travel_mode(index1: int, index2: int) -> int:
	if travel_matrix.is_empty() or index1 < 0 or index2 < 0 or index1 >= travel_matrix.size() or index2 >= travel_matrix[index1].size():
		return 3 # Default to plane
	return travel_matrix[index1][index2]

func reverse_path():
	if dropped_pin_data.size() >= 2:
		dropped_pin_data.reverse()

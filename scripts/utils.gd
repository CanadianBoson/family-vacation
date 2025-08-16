# Utils.gd
extends Node

# Earth's radius in kilometers for Haversine formula
const EARTH_RADIUS_KM = 6371.0

# This function can now be called from anywhere in your project.
func calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var R = EARTH_RADIUS_KM
	var phi1 = deg_to_rad(lat1)
	var phi2 = deg_to_rad(lat2)
	var delta_phi = deg_to_rad(lat2 - lat1)
	var delta_lambda = deg_to_rad(lon2 - lon1)

	var a = sin(delta_phi / 2) * sin(delta_phi / 2) + \
			cos(phi1) * cos(phi2) * \
			sin(delta_lambda / 2) * sin(delta_lambda / 2)
	var c = 2 * atan2(sqrt(a), sqrt(1 - a))
	var d = R * c
	return d

func on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	return (q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and
			q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y))

func orientation(p: Vector2, q: Vector2, r: Vector2) -> int:
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	if val == 0: return 0
	return 1 if val > 0 else 2

func segments_intersect(p1: Vector2, q1: Vector2, p2: Vector2, q2: Vector2) -> bool:
	var o1 = orientation(p1, q1, p2)
	var o2 = orientation(p1, q1, q2)
	var o3 = orientation(p2, q2, p1)
	var o4 = orientation(p2, q2, q1)
	if (o1 != o2 and o3 != o4): return true
	if (o1 == 0 and on_segment(p1, p2, q1)): return true
	if (o2 == 0 and on_segment(p1, q2, q1)): return true
	if (o3 == 0 and on_segment(p2, p1, q2)): return true
	if (o4 == 0 and on_segment(p2, q1, q2)): return true
	return false

# Calculates the cost of a single leg of the journey based on a non-linear model.
# Prices are rough estimates for a European tourist season and scale with sqrt(distance).
func calculate_leg_cost(transport_type: int, distance_km: float, num_menu_items: int) -> float:
	var base_cost = 0.0
	var per_km_sqrt_coeff = 0.0 # This is the coefficient for the square root of the distance
	var family_multiplier = float(num_menu_items)

	match transport_type:
		0: # Car (Represents a rental car)
			base_cost = 120.0
			per_km_sqrt_coeff = 3.0
			family_multiplier = 1.0
		1: # Boat (Ferry)
			base_cost = 40.0
			per_km_sqrt_coeff = 5.0
		2: # Train
			base_cost = 60.0
			per_km_sqrt_coeff = 8.0
		3: # Plane (Budget Airline)
			base_cost = 150.0
			per_km_sqrt_coeff = 15.0

	# The formula now uses the square root of the distance for non-linear scaling.
	# This makes very long trips less punishingly expensive.
	return (base_cost + (sqrt(distance_km) * per_km_sqrt_coeff)) * family_multiplier

func load_family_data() -> Dictionary:
	var file_path = "res://data/families.json"
	if not FileAccess.file_exists(file_path): return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("families"):
		return json_data.families
	return {}
	
func calculate_spans(dropped_pin_data: Array) -> Dictionary:
	if dropped_pin_data.size() < 2:
		# Return zero vectors if there's no path to measure.
		return {"journey_span": Vector2.ZERO, "endpoint_span": Vector2.ZERO}

	# --- Calculate Journey Span (all points) ---
	var min_lat = 90.0
	var max_lat = -90.0
	var min_lon = 180.0
	var max_lon = -180.0

	for pin in dropped_pin_data:
		min_lat = min(min_lat, pin.lat)
		max_lat = max(max_lat, pin.lat)
		min_lon = min(min_lon, pin.lng)
		max_lon = max(max_lon, pin.lng)

	var journey_lat_span = max_lat - min_lat
	var journey_lon_span = max_lon - min_lon
	var journey_span = Vector2(journey_lat_span, journey_lon_span)

	# --- Calculate Endpoint Span (start and end only) ---
	var start_pin = dropped_pin_data.front()
	var end_pin = dropped_pin_data.back()
	var endpoint_lat_span = abs(start_pin.lat - end_pin.lat)
	var endpoint_lon_span = abs(start_pin.lng - end_pin.lng)
	var endpoint_span = Vector2(endpoint_lat_span, endpoint_lon_span)

	return {"journey_span": journey_span, "endpoint_span": endpoint_span}	

# Converts an array of pin data (containing Vector2) into a clean JSON string.
func stringify_path_data(path_data: Array) -> String:
	var serializable_path = []
	for pin_data in path_data:
		var serializable_pin = pin_data.duplicate()
		
		if serializable_pin.has("position") and serializable_pin.position is Vector2:
			var pos_vec = serializable_pin.position
			serializable_pin.position = {"x": pos_vec.x, "y": pos_vec.y}
		
		serializable_path.append(serializable_pin)
		
	return JSON.stringify(serializable_path)


# Converts a JSON string from Firebase back into a usable Godot array with Vector2.
func load_path_from_string(json_string: String) -> Array:
	var parsed_data = JSON.parse_string(json_string)
	
	if not parsed_data is Array:
		return []

	var reconstructed_path = []
	for serializable_pin in parsed_data:
		var pin_data = serializable_pin.duplicate()
		
		if pin_data.has("position") and pin_data.position is Dictionary:
			var pos_dict = pin_data.position
			pin_data.position = Vector2(pos_dict.get("x", 0), pos_dict.get("y", 0))
			
		reconstructed_path.append(pin_data)
		
	return reconstructed_path

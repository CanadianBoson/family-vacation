# quest_manager.gd
# This node now only checks for and stores the completion status of game objectives.
extends Node

var pin_manager: Node

# --- This dictionary is now refactored to avoid the bind() bug with Arrays ---
var quest_checkers = {}

var quest_statuses = {}

func _ready():
	# Populate the dictionary in _ready() using a more robust structure.
	# Each value is a dictionary containing the function, expected result, and extra args.
	quest_checkers = {
		"ThreeLetter": {"func": _check_three_same_letter, "expected": true},
		"NoThreeLetter": {"func": _check_three_same_letter, "expected": false},
		"CarFree": {"func": _check_no_transport, "expected": true, "args": [0]},
		"NoCarFree": {"func": _check_no_transport, "expected": false, "args": [0]},
		"SailFree": {"func": _check_no_transport, "expected": true, "args": [1]},
		"NoSailFree": {"func": _check_no_transport, "expected": false, "args": [1]},
		"TrainFree": {"func": _check_no_transport, "expected": true, "args": [2]},
		"NoTrainFree": {"func": _check_no_transport, "expected": false, "args": [2]},
		"PlaneFree": {"func": _check_no_transport, "expected": true, "args": [3]},
		"NoPlaneFree": {"func": _check_no_transport, "expected": false, "args": [3]},
		"NoCapitals": {"func": _check_no_capitals, "expected": true},
		"SomeCapitals": {"func": _check_no_capitals, "expected": false},
		"PathsCrossing": {"func": _check_paths_crossing, "expected": true},
		"NoPathsCrossing": {"func": _check_paths_crossing, "expected": false},
		"MinPopulation": {"func": _check_min_population, "expected": true},
		"SomeSmallPopulation": {"func": _check_min_population, "expected": false},
		"StayInEU": {"func": _check_stay_in_eu, "expected": true},
		"LeaveEU": {"func": _check_stay_in_eu, "expected": false},
		"CrossThree": {"func": _check_cross_three, "expected": true},
		"NoCrossThree": {"func": _check_cross_three, "expected": false},
		"StayAwayDE": {"func": _check_stay_away, "expected": true, "args": ["Germany"]},
		"StayAwayFR": {"func": _check_stay_away, "expected": true, "args": ["France"]},
		"StayAwayUK": {"func": _check_stay_away, "expected": true, "args": ["United Kingdom"]},
		"StayAwayIT": {"func": _check_stay_away, "expected": true, "args": ["Italy"]},
		"StayAwayRU": {"func": _check_stay_away, "expected": true, "args": ["Russia"]},
		"UniqueCityLetters": {"func": _check_unique_city_letters, "expected": true},
		"UniqueCountryLetters": {"func": _check_unique_country_letters, "expected": true},
	}
	
	for quest_key in quest_checkers.keys():
		quest_statuses[quest_key] = false

# This is the main function called when pin data changes.
func check_all_conditions(dropped_pin_data: Array, all_locations_data: Array):
	print("--- Checking Conditions ---")
	for quest_key in quest_checkers.keys():
		var info = quest_checkers[quest_key]
		var checker_func = info["func"]
		var expected_result = info["expected"]
		# Get extra arguments if they exist (for quests like StayAway).
		var extra_args = info.get("args", [])
		
		# Build the full argument list for the function call.
		var args_for_call = extra_args + [dropped_pin_data, all_locations_data]
		
		# Use callv() to call the function with an array of arguments.
		var result = checker_func.callv(args_for_call)
		var is_satisfied = (result == expected_result)
		
		if quest_statuses.get(quest_key) != is_satisfied:
			quest_statuses[quest_key] = is_satisfied
			print("Status for '%s' changed to: %s" % [quest_key, is_satisfied])

func is_quest_satisfied(quest_key: String) -> bool:
	return quest_statuses.get(quest_key, false)


# --- Condition Checking Functions (Signatures are now consistent) ---

func _check_three_same_letter(dropped_pin_data: Array, _all_locations_data: Array) -> bool:
	if dropped_pin_data.size() < 3: return false
	var letter_counts = {}
	for pin_data in dropped_pin_data:
		var city_name = pin_data.get("city", "")
		if city_name.is_empty(): continue
		var first_letter = city_name[0].to_upper()
		if not letter_counts.has(first_letter): letter_counts[first_letter] = 0
		letter_counts[first_letter] += 1
	for letter in letter_counts.keys():
		if letter_counts[letter] >= 3: return true
	return false

func _check_no_transport(transport_type: int, dropped_pin_data: Array, _all_locations_data: Array) -> bool:
	if dropped_pin_data.size() < 2: return false
	if not is_instance_valid(pin_manager): return false
	for i in range(dropped_pin_data.size() - 1):
		var pin1_data = dropped_pin_data[i]
		var pin2_data = dropped_pin_data[i+1]
		if pin_manager.get_travel_mode(pin1_data.index, pin2_data.index) == transport_type:
			return false
	return true

func _check_no_capitals(dropped_pin_data: Array, _all_locations_data: Array) -> bool:
	if dropped_pin_data.is_empty(): return true
	for pin_data in dropped_pin_data:
		if pin_data.get("is_capital", false):
			return false
	return true

func _check_min_population(dropped_pin_data: Array, _all_locations_data: Array) -> bool:
	if dropped_pin_data.is_empty(): return true
	for pin_data in dropped_pin_data:
		var population = pin_data.get("population", 0)
		if population < 500000:
			return false
	return true

func _check_paths_crossing(dropped_pin_data: Array, _all_locations_data: Array) -> bool:
	if dropped_pin_data.size() < 4: return false
	for i in range(dropped_pin_data.size() - 1):
		var p1 = dropped_pin_data[i].position
		var q1 = dropped_pin_data[i+1].position
		for j in range(i + 2, dropped_pin_data.size() - 1):
			var p2 = dropped_pin_data[j].position
			var q2 = dropped_pin_data[j+1].position
			if _segments_intersect(p1, q1, p2, q2):
				return true
	return false

# --- New function to check if all cities are in the EU ---
func _check_stay_in_eu(dropped_pin_data: Array, all_locations_data: Array) -> bool:
	# If no pins are dropped, the condition is met by default.
	if dropped_pin_data.is_empty():
		return true
		
	# Iterate through each visited city.
	for pin_data in dropped_pin_data:
		# If any city's country is not in our EU list, the condition fails.
		if not pin_data.get("is_eu", false):
			return false
	return true
	
# Checks if the first letter of every city in the path is unique.
func _check_unique_city_letters(dropped_pin_data: Array, _all_locations_data: Array) -> bool:
	if dropped_pin_data.size() < 2:
		return true # A single city or no cities have unique letters by default.

	var seen_letters = []
	for pin_data in dropped_pin_data:
		var city_name = pin_data.get("city", "")
		if city_name.is_empty(): continue
		
		var first_letter = city_name[0].to_upper()
		
		if seen_letters.has(first_letter):
			return false # Found a duplicate letter.
		
		seen_letters.append(first_letter)
			
	return true # All letters were unique.

# Checks if the first letter of every country code in the path is unique.
func _check_unique_country_letters(dropped_pin_data: Array, _all_locations_data: Array) -> bool:
	if dropped_pin_data.size() < 2:
		return true

	var seen_letters = []
	for pin_data in dropped_pin_data:
		var country_code = pin_data.get("country", "")
		if country_code.is_empty(): continue
		
		var first_letter = country_code[0].to_upper()
		
		if seen_letters.has(first_letter):
			return false # Found a duplicate letter.
			
		seen_letters.append(first_letter)
			
	return true # All letters were unique.	

func _check_cross_three(dropped_pin_data: Array, _all_locations_data: Array) -> bool:
	if dropped_pin_data.size() < 2: return false
	var crossings = 0
	for i in range(dropped_pin_data.size() - 1):
		var is_first_city_in_eu = dropped_pin_data[i].get("is_eu", "")
		var is_second_city_in_eu = dropped_pin_data[i+1].get("is_eu", "")
		if is_first_city_in_eu != is_second_city_in_eu:
			crossings += 1
	return crossings >= 3

# The signature for this function is now consistent with the others.
func _check_stay_away(country: String, dropped_pin_data: Array, all_locations_data: Array) -> bool:
	if dropped_pin_data.is_empty():
		return true

	var target_cities = []
	for location in all_locations_data:
		if location.get("country") == country:
			target_cities.append(location)

	if target_cities.is_empty():
		return true

	for i in range(dropped_pin_data.size() - 1):
		var p1_data = dropped_pin_data[i]
		var p2_data = dropped_pin_data[i+1]
		
		for k in range(11):
			var t = float(k) / 10.0
			var current_lat = lerp(p1_data.lat, p2_data.lat, t)
			var current_lng = lerp(p1_data.lng, p2_data.lng, t)
			
			for target_city in target_cities:
				var distance = _haversine_distance(current_lat, current_lng, target_city.lat, target_city.lng)
				if distance < 200.0:
					return false

	return true

# --- Helper functions ---

func _haversine_distance(lat1, lon1, lat2, lon2) -> float:
	var R = 6371.0 # Earth radius in km
	var dLat = deg_to_rad(lat2 - lat1)
	var dLon = deg_to_rad(lon2 - lon1)
	var a = sin(dLat / 2) * sin(dLat / 2) + \
			cos(deg_to_rad(lat1)) * cos(deg_to_rad(lat2)) * \
			sin(dLon / 2) * sin(dLon / 2)
	var c = 2 * atan2(sqrt(a), sqrt(1 - a))
	return R * c

func _on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	return (q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and
			q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y))

func _orientation(p: Vector2, q: Vector2, r: Vector2) -> int:
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	if val == 0: return 0
	return 1 if val > 0 else 2

func _segments_intersect(p1: Vector2, q1: Vector2, p2: Vector2, q2: Vector2) -> bool:
	var o1 = _orientation(p1, q1, p2)
	var o2 = _orientation(p1, q1, q2)
	var o3 = _orientation(p2, q2, p1)
	var o4 = _orientation(p2, q2, q1)
	if (o1 != o2 and o3 != o4): return true
	if (o1 == 0 and _on_segment(p1, p2, q1)): return true
	if (o2 == 0 and _on_segment(p1, q2, q1)): return true
	if (o3 == 0 and _on_segment(p2, p1, q2)): return true
	if (o4 == 0 and _on_segment(p2, q1, q2)): return true
	return false

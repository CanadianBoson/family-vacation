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
		# linguistic
		"ThreeLetter": {"func": _check_three_same_letter, "expected": true},
		"NoThreeLetter": {"func": _check_three_same_letter, "expected": false},
		"UniqueCityLetters": {"func": _check_unique_city_letters, "expected": true},
		"UniqueCountryLetters": {"func": _check_unique_country_letters, "expected": true},
		"MaxLettersCity": {"func": _check_city_name_length, "expected": true, "args": [10, "max"]},
		"MinLettersCity": {"func": _check_city_name_length, "expected": true, "args": [5, "min"]},
		"MaxLettersCountry": {"func": _check_country_code_length, "expected": true, "args": [10, "max"]},
		"MinLettersCountry": {"func": _check_country_code_length, "expected": true, "args": [6, "min"]},
		"CityStartsWithB": {"func": _check_city_starting_with, "expected": true, "args": ["B"]},
		"CityStartsWithF": {"func": _check_city_starting_with, "expected": true, "args": ["F"]},
		"CityStartsWithS": {"func": _check_city_starting_with, "expected": true, "args": ["S"]},
		"CityStartsWithL": {"func": _check_city_starting_with, "expected": true, "args": ["L"]},
		"CityStartsWithN": {"func": _check_city_starting_with, "expected": true, "args": ["N"]},
		"CityStartsWithP": {"func": _check_city_starting_with, "expected": true, "args": ["P"]},
		"CountryStartsWithB": {"func": _check_country_starting_with, "expected": true, "args": ["B"]},
		"CountryStartsWithF": {"func": _check_country_starting_with, "expected": true, "args": ["F"]},
		"CountryStartsWithI": {"func": _check_country_starting_with, "expected": true, "args": ["I"]},
		"CountryStartsWithL": {"func": _check_country_starting_with, "expected": true, "args": ["L"]},
		"CountryStartsWithN": {"func": _check_country_starting_with, "expected": true, "args": ["N"]},
		"CountryStartsWithP": {"func": _check_country_starting_with, "expected": true, "args": ["P"]},
		# transport
		"CarFree":    {"func": _check_transport_usage, "expected": true, "args": [0, "avoid"]},
		"MustUseCar": {"func": _check_transport_usage, "expected": true, "args": [0, "require"]},
		"SailFree":   {"func": _check_transport_usage, "expected": true, "args": [1, "avoid"]},
		"MustUseSail":{"func": _check_transport_usage, "expected": true, "args": [1, "require"]},
		"TrainFree":  {"func": _check_transport_usage, "expected": true, "args": [2, "avoid"]},
		"MustUseTrain":{"func": _check_transport_usage, "expected": true, "args": [2, "require"]},
		"PlaneFree":  {"func": _check_transport_usage, "expected": true, "args": [3, "avoid"]},
		"MustUsePlane":{"func": _check_transport_usage, "expected": true, "args": [3, "require"]},
		"MostlyCar":   {"func": _check_mostly_transport, "expected": true, "args": [0]}, # 0 is Car
		"MostlyBoat":  {"func": _check_mostly_transport, "expected": true, "args": [1]}, # 1 is Boat
		"MostlyTrain": {"func": _check_mostly_transport, "expected": true, "args": [2]}, # 2 is Train
		"MostlyPlane": {"func": _check_mostly_transport, "expected": true, "args": [3]}, # 3 is Plane
		"AllTransport": {"func": _check_all_transport, "expected": true},
		# geometry
		"PathsCrossing": {"func": _check_paths_crossing, "expected": true},
		"NoPathsCrossing": {"func": _check_paths_crossing, "expected": false},
		"CrossThree": {"func": _check_cross_three, "expected": true},
		"NoCrossThree": {"func": _check_cross_three, "expected": false},
		"OnlyObtuse": {"func": _check_path_angles, "expected": true, "args": ["obtuse"]},
		"OnlyAcute": {"func": _check_path_angles, "expected": true, "args": ["acute"]},
		"TrainsWE": {"func": _check_journey_direction, "expected": true, "args": [2, "WE"]},
		"TrainsNS": {"func": _check_journey_direction, "expected": true, "args": [2, "NS"]},
		"PlanesWE": {"func": _check_journey_direction, "expected": true, "args": [3, "WE"]},
		"PlanesNS": {"func": _check_journey_direction, "expected": true, "args": [3, "NS"]},
		"CarsWE": {"func": _check_journey_direction, "expected": true, "args": [0, "WE"]},
		"CarsNS": {"func": _check_journey_direction, "expected": true, "args": [0, "NS"]},		
		# stats				
		"NoCapitals": {"func": _check_no_capitals, "expected": true},
		"SomeCapitals": {"func": _check_no_capitals, "expected": false},
		"AllCapitals": {"func": _check_all_capitals, "expected": true},
		"MinPopulation": {"func": _check_min_population, "expected": true},
		"SomeSmallPopulation": {"func": _check_min_population, "expected": false},
		"StayInEU": {"func": _check_stay_in_eu, "expected": true},
		"LeaveEU": {"func": _check_stay_in_eu, "expected": false},
		"MaxLat": {"func": _check_coordinate_spread, "expected": true, "args": ["lat", "all", 10.0, "max"]},
		"MinLat": {"func": _check_coordinate_spread, "expected": true, "args": ["lat", "all", 20.0, "min"]},
		"StartEndMaxLat": {"func": _check_coordinate_spread, "expected": true, "args": ["lat", "start_end", 10.0, "max"]},
		"StartEndMinLat": {"func": _check_coordinate_spread, "expected": true, "args": ["lat", "start_end", 20.0, "min"]},
		"MaxLon": {"func": _check_coordinate_spread, "expected": true, "args": ["lon", "all", 15.0, "max"]},
		"MinLon": {"func": _check_coordinate_spread, "expected": true, "args": ["lon", "all", 25.0, "min"]},
		"StartEndMaxLon": {"func": _check_coordinate_spread, "expected": true, "args": ["lon", "start_end", 15.0, "max"]},
		"StartEndMinLon": {"func": _check_coordinate_spread, "expected": true, "args": ["lon", "start_end", 25.0, "min"]},
		# avoider
		"StayAwayDE": {"func": _check_stay_away, "expected": true, "args": ["Germany", "avoid"]},
		"StayAwayFR": {"func": _check_stay_away, "expected": true, "args": ["France", "avoid"]},
		"StayAwayUK": {"func": _check_stay_away, "expected": true, "args": ["United Kingdom", "avoid"]},
		"StayAwayIT": {"func": _check_stay_away, "expected": true, "args": ["Italy", "avoid"]},
		"StayAwayPL": {"func": _check_stay_away, "expected": true, "args": ["Poland", "avoid"]},
		"StayAwayRU": {"func": _check_stay_away, "expected": true, "args": ["Russia", "avoid"]},
		"StayAwayES": {"func": _check_stay_away, "expected": true, "args": ["Spain", "avoid"]},
		"StayAwayTR": {"func": _check_stay_away, "expected": true, "args": ["Turkey", "avoid"]},
		"PassThroughDE": {"func": _check_stay_away, "expected": true, "args": ["Germany", "pass"]},
		"PassThroughFR": {"func": _check_stay_away, "expected": true, "args": ["France", "pass"]},
		"PassThroughUK": {"func": _check_stay_away, "expected": true, "args": ["United Kingdom", "pass"]},
		"PassThroughIT": {"func": _check_stay_away, "expected": true, "args": ["Italy", "pass"]},
		"PassThroughPL": {"func": _check_stay_away, "expected": true, "args": ["Poland", "pass"]},
		"PassThroughRU": {"func": _check_stay_away, "expected": true, "args": ["Russia", "pass"]},
		"PassThroughES": {"func": _check_stay_away, "expected": true, "args": ["Spain", "pass"]},
		"PassThroughTR": {"func": _check_stay_away, "expected": true, "args": ["Turkey", "pass"]},
		# party_pooper
		"MaxOverallCost": {"func": _check_overall_cost, "expected": true, "args": [2000.0, "max"]},	
		"MaxLegCost": {"func": _check_leg_cost, "expected": true, "args": [300.0, "max"]},
		"MaxCities": {"func": _check_city_count, "expected": true, "args": [5, "max"]},
		"MaxLegDistance": {"func": _check_leg_distance, "expected": true, "args": [500.0, "max"]},
		"MaxJourneyDistance": {"func": _check_journey_distance, "expected": true, "args": [5000.0, "max"]},
		"MaxCountries": {"func": _check_country_count, "expected": true, "args": [3, "max"]},
		"MaxEndpointDistance": {"func": _check_endpoint_distance, "expected": true, "args": [1000.0, "max"]},
		# spoiled
		"MinOverallCost": {"func": _check_overall_cost, "expected": true, "args": [3000.0, "min"]},
		"MinLegCost": {"func": _check_leg_cost, "expected": true, "args": [100.0, "min"]},
		"MinCities": {"func": _check_city_count, "expected": true, "args": [10, "min"]},
		"MinLegDistance": {"func": _check_leg_distance, "expected": true, "args": [200.0, "min"]},
		"MinJourneyDistance": {"func": _check_journey_distance, "expected": true, "args": [10000.0, "min"]},
		"MinCountries": {"func": _check_country_count, "expected": true, "args": [10, "min"]},
		"MinEndpointDistance": {"func": _check_endpoint_distance, "expected": true, "args": [3000.0, "min"]}
	}
	
	for quest_key in quest_checkers.keys():
		quest_statuses[quest_key] = false

# This is the main function called when pin data changes.
func check_all_conditions(dropped_pin_data: Array, all_locations_data: Array, num_menu_items: int):
	print("--- Checking Conditions ---")
	for quest_key in quest_checkers.keys():
		var info = quest_checkers[quest_key]
		var checker_func = info["func"]
		var expected_result = info["expected"]
		# Get extra arguments if they exist (for quests like StayAway).
		var extra_args = info.get("args", [])
		
		# Build the full argument list for the function call.
		var args_for_call = extra_args + [dropped_pin_data, all_locations_data, num_menu_items]
		
		# Use callv() to call the function with an array of arguments.
		var result = false
		var is_satisfied = false
		if dropped_pin_data.size() > 1:
			result = checker_func.callv(args_for_call)
			is_satisfied = (result == expected_result)
		
		if quest_statuses.get(quest_key) != is_satisfied:
			quest_statuses[quest_key] = is_satisfied
			print("Status for '%s' changed to: %s" % [quest_key, is_satisfied])

func is_quest_satisfied(quest_key: String) -> bool:
	return quest_statuses.get(quest_key, false)

# --- Condition Checking Functions (Signatures are now consistent) ---

# Checks if the total number of visited cities meets a requirement.
func _check_city_count(limit: int, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var city_count = dropped_pin_data.size()
	if check_type == "max":
		return city_count <= limit
	elif check_type == "min":
		return city_count >= limit
	return false

# Checks if the total number of unique countries visited meets a requirement.
func _check_country_count(limit: int, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var unique_countries = []
	for pin_data in dropped_pin_data:
		var country = pin_data.get("country", "")
		if not country.is_empty() and not unique_countries.has(country):
			unique_countries.append(country)
			
	var country_count = unique_countries.size()
	if check_type == "max":
		return country_count <= limit
	elif check_type == "min":
		return country_count >= limit
	return false

# Checks if three cities in the path start with the same letter
func _check_three_same_letter(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
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

# Checks if a specific transport type is avoided or required in the path.
func _check_transport_usage(transport_type: int, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	if not is_instance_valid(pin_manager): return false
	var found_transport = false
	for i in range(dropped_pin_data.size() - 1):
		var pin1_data = dropped_pin_data[i]
		var pin2_data = dropped_pin_data[i+1]
		if pin_manager.get_travel_mode(pin1_data.index, pin2_data.index) == transport_type:
			found_transport = true
			break # No need to check further if we found it.
	
	if check_type == "avoid":
		# The condition is met if we did NOT find the transport.
		return not found_transport
	elif check_type == "require":
		# The condition is met if we DID find the transport.
		return found_transport
		
	return false

# Check that all visited cities are capitals
func _check_all_capitals(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for pin_data in dropped_pin_data:
		if not pin_data.get("is_capital", false):
			return false
	return true

# Checks if any visited city starts with a specific letter.
func _check_city_starting_with(letter: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for pin_data in dropped_pin_data:
		var city_name = pin_data.get("city", "")
		if not city_name.is_empty() and city_name[0].to_upper() == letter:
			return true
			
	return false

# Checks if any visited country starts with a specific letter.
func _check_country_starting_with(letter: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for pin_data in dropped_pin_data:
		var country_code = pin_data.get("country", "")
		if not country_code.is_empty() and country_code[0].to_upper() == letter:
			return true # Found a matching country.
			
	return false # No country started with the required letter.

# Checks that no visited cities are capitals
func _check_no_capitals(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for pin_data in dropped_pin_data:
		if pin_data.get("is_capital", false):
			return false
	return true

# Checks that the minimum population in all cities is 500k
func _check_min_population(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for pin_data in dropped_pin_data:
		var population = pin_data.get("population", 0)
		if population < 500000:
			return false
	return true

# Checks whether paths cross
func _check_paths_crossing(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for i in range(dropped_pin_data.size() - 1):
		var p1 = dropped_pin_data[i].position
		var q1 = dropped_pin_data[i+1].position
		for j in range(i + 2, dropped_pin_data.size() - 1):
			var p2 = dropped_pin_data[j].position
			var q2 = dropped_pin_data[j+1].position
			if Utils.segments_intersect(p1, q1, p2, q2):
				return true
	return false

# Checks if every individual leg of the journey meets a distance requirement.
func _check_leg_distance(limit: float, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for i in range(dropped_pin_data.size() - 1):
		var p1 = dropped_pin_data[i]
		var p2 = dropped_pin_data[i+1]
		var leg_distance = Utils.calculate_haversine_distance(p1.lat, p1.lng, p2.lat, p2.lng)
		
		if check_type == "max":
			if leg_distance > limit:
				return false # Found a leg that is too long.
		elif check_type == "min":
			if leg_distance < limit:
				return false # Found a leg that is too short.
				
	return true # All legs passed the check.

# Checks if the total distance of the journey meets a requirement.
func _check_journey_distance(limit: float, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var total_distance = 0.0

	for i in range(dropped_pin_data.size() - 1):
		var p1 = dropped_pin_data[i]
		var p2 = dropped_pin_data[i+1]
		total_distance += Utils.calculate_haversine_distance(p1.lat, p1.lng, p2.lat, p2.lng)
	
	if check_type == "max":
		return total_distance <= limit
	elif check_type == "min":
		return total_distance >= limit
	
	return false
	
# Checks if all cities are in the EU
func _check_stay_in_eu(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for pin_data in dropped_pin_data:
		if not pin_data.get("is_eu", false):
			return false
	return true
	
# Checks if the first letter of every city in the path is unique.
func _check_unique_city_letters(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var seen_letters = []
	for pin_data in dropped_pin_data:
		var city_name = pin_data.get("city", "")
		if city_name.is_empty(): continue
		
		var first_letter = city_name[0].to_upper()
		
		if seen_letters.has(first_letter):
			return false
		
		seen_letters.append(first_letter)
			
	return true

# Checks if the first letter of every unique country in the path is unique.
func _check_unique_country_letters(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var unique_countries = []
	for pin_data in dropped_pin_data:
		var country = pin_data.get("country", "")
		if not country.is_empty() and not unique_countries.has(country):
			unique_countries.append(country)
	# ---------------------------------------------------------

	# Now, check the first letters of the unique countries
	var seen_letters = []
	for country_code in unique_countries:
		var first_letter = country_code[0].to_upper()
		
		if seen_letters.has(first_letter):
			return false
			
		seen_letters.append(first_letter)
			
	return true

# Checks through cities to see if the EU/non-EU border has been crossed at least three times
func _check_cross_three(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var crossings = 0
	for i in range(dropped_pin_data.size() - 1):
		var is_first_city_in_eu = dropped_pin_data[i].get("is_eu", "")
		var is_second_city_in_eu = dropped_pin_data[i+1].get("is_eu", "")
		if is_first_city_in_eu != is_second_city_in_eu:
			crossings += 1
	return crossings >= 3

# Checks if all journeys of a specific transport type follow a WE or NS direction.
func _check_journey_direction(transport_type: int, direction_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for i in range(dropped_pin_data.size() - 1):
		var p1 = dropped_pin_data[i]
		var p2 = dropped_pin_data[i+1]
		
		var travel_mode = pin_manager.get_travel_mode(p1.index, p2.index)
		
		# We only care about legs that match the required transport type.
		if travel_mode == transport_type:
			var travel_vector = p2.position - p1.position
			
			if direction_type == "WE":
				# For a West-East journey, the horizontal movement must be greater than the vertical.
				if abs(travel_vector.x) < abs(travel_vector.y):
					return false
			elif direction_type == "NS":
				# For a North-South journey, the vertical movement must be greater than the horizontal.
				if abs(travel_vector.y) < abs(travel_vector.x):
					return false

	return true
	
# Checks if the path avoids or passes through a country.
func _check_stay_away(country: String, check_type: String, dropped_pin_data: Array, all_locations_data: Array, _num_menu_items: int) -> bool:
	# Get a list of all cities in the target country.
	var target_cities = []
	for location in all_locations_data:
		if location.get("country") == country:
			target_cities.append(location)

	if target_cities.is_empty():
		return true

	# Use the helper function to determine if the path gets close.
	var path_is_near = _is_path_near_country(dropped_pin_data, target_cities)

	# Apply the specific quest logic.
	if check_type == "avoid":
		return not path_is_near
		
	elif check_type == "pass":
		# For "pass", the path MUST be near and must NOT have any stops in the country.
		if not path_is_near:
			return false
		
		for pin_data in dropped_pin_data:
			if pin_data.get("country") == country:
				return false
		
		return true

	return false

# Checks the spread of latitude or longitude for all or just start/end points.
func _check_coordinate_spread(coord_type: String, check_mode: String, limit: float, comparison: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var points_to_check = []
	if check_mode == "all":
		points_to_check = dropped_pin_data
	elif check_mode == "start_end":
		points_to_check.append(dropped_pin_data.front())
		points_to_check.append(dropped_pin_data.back())

	# Extract the relevant coordinate (lat or lon) from the points.
	var coords = []
	var key = "lat" if coord_type == "lat" else "lng"
	for point in points_to_check:
		coords.append(point.get(key, 0.0))
		
	if coords.is_empty():
		return comparison == "max"

	# Calculate the spread.
	var min_coord = coords.min()
	var max_coord = coords.max()
	var spread = max_coord - min_coord
	
	# Compare the spread to the limit.
	if comparison == "max":
		return spread <= limit
	elif comparison == "min":
		return spread >= limit
		
	return false

# Verify every method of transport is used
func _check_all_transport(dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	# A path needs at least 3 segments to potentially use all 4 transport types.
	if dropped_pin_data.size() < 4:
		return false

	# A dictionary to track which transport modes have been seen.
	var seen_transport_modes = {
		0: false, # Land/Car
		1: false, # Boat
		2: false, # Train
		3: false  # Plane
	}

	# Iterate through each segment of the journey.
	for i in range(dropped_pin_data.size() - 1):
		var pin1_data = dropped_pin_data[i]
		var pin2_data = dropped_pin_data[i+1]
		
		var travel_mode = pin_manager.get_travel_mode(pin1_data.index, pin2_data.index)
		
		# Mark this transport mode as seen.
		if seen_transport_modes.has(travel_mode):
			seen_transport_modes[travel_mode] = true
			
	# Check if all values in the dictionary are true.
	for mode in seen_transport_modes.keys():
		if not seen_transport_modes[mode]:
			return false # A transport mode was missed.
			
	return true # All transport modes were used.
	
# Checks if all angles in the path are of a specific type
func _check_path_angles(angle_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	# A path needs at least 3 pins to form an angle.
	if dropped_pin_data.size() < 3:
		return false # Need path size three.

	# Iterate through each vertex of the path.
	for i in range(1, dropped_pin_data.size() - 1):
		var p_prev = dropped_pin_data[i-1].position
		var p_current = dropped_pin_data[i].position
		var p_next = dropped_pin_data[i+1].position
		
		# Create vectors pointing away from the current vertex.
		var vec1 = p_prev - p_current
		var vec2 = p_next - p_current
		
		# Get the base angle (0-180 degrees).
		var angle_deg = rad_to_deg(vec1.angle_to(vec2))

		# Check the angle against the required type.
		if angle_type == "obtuse":
			if abs(angle_deg) < 90.0:
				return false 
		elif angle_type == "acute":
			if abs(angle_deg) > 90.0:
				return false
				
	return true
	
# Checks if every visited city name meets a length requirement.
func _check_city_name_length(limit: int, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for pin_data in dropped_pin_data:
		var city_name_length = pin_data.get("city", "").length()
		
		if check_type == "max":
			if city_name_length > limit:
				return false
		elif check_type == "min":
			if city_name_length < limit:
				return false
				
	return true

# Checks if every visited country code meets a length requirement.
func _check_country_code_length(limit: int, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	for pin_data in dropped_pin_data:
		var country_code_length = pin_data.get("country", "").length()
		
		if check_type == "max":
			if country_code_length > limit:
				return false
		elif check_type == "min":
			if country_code_length < limit:
				return false
				
	return true	

# Checks the overall cost of the trip
func _check_overall_cost(limit: float, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, num_menu_items: int) -> bool:
	var overall_cost = 0.0

	for i in range(dropped_pin_data.size() - 1):
		var p1 = dropped_pin_data[i]
		var p2 = dropped_pin_data[i+1]
		var distance = Utils.calculate_haversine_distance(p1.lat, p1.lng, p2.lat, p2.lng)
		var transport_mode = pin_manager.get_travel_mode(p1.index, p2.index)
		overall_cost += _calculate_leg_cost(transport_mode, distance, num_menu_items)
	
	if check_type == "max":
		return overall_cost <= limit * num_menu_items
	elif check_type == "min":
		return overall_cost >= limit * num_menu_items
	
	return false

# Checks the cost of each leg is below a certain limit
func _check_leg_cost(limit: float, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, num_menu_items: int) -> bool:
	for i in range(dropped_pin_data.size() - 1):
		var p1 = dropped_pin_data[i]
		var p2 = dropped_pin_data[i+1]
		var distance = Utils.calculate_haversine_distance(p1.lat, p1.lng, p2.lat, p2.lng)
		var transport_mode = pin_manager.get_travel_mode(p1.index, p2.index)
		var leg_cost = _calculate_leg_cost(transport_mode, distance, num_menu_items)
		
		if check_type == "max":
			if leg_cost > limit * num_menu_items:
				return false
		elif check_type == "min":
			if leg_cost < limit * num_menu_items:
				return false
				
	return true

# Checks if a specific transport type is used for more legs than any other type.
func _check_mostly_transport(transport_type: int, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var leg_count = dropped_pin_data.size() - 1

	var specific_transport_legs = 0

	# Iterate through each segment of the journey to count the transport types.
	for i in range(leg_count):
		var p1 = dropped_pin_data[i]
		var p2 = dropped_pin_data[i+1]
		
		var travel_mode = pin_manager.get_travel_mode(p1.index, p2.index)
		
		if travel_mode == transport_type:
			specific_transport_legs += 1
			
	# The condition is met if the specific transport legs are 50% or more of the total legs.
	return (float(specific_transport_legs) / float(leg_count)) >= 0.5

# Checks if the straight-line distance between the start and end points meets a requirement.
func _check_endpoint_distance(limit: float, check_type: String, dropped_pin_data: Array, _all_locations_data: Array, _num_menu_items: int) -> bool:
	var start_pin = dropped_pin_data.front()
	var end_pin = dropped_pin_data.back()
	
	var endpoint_distance = Utils.calculate_haversine_distance(start_pin.lat, start_pin.lng, end_pin.lat, end_pin.lng)
	
	if check_type == "max":
		return endpoint_distance <= limit
	elif check_type == "min":
		return endpoint_distance >= limit
		
	return false

# --- Helper functions ---

# Calculates the cost of a given leg of the journey
func _calculate_leg_cost(transport_type: int, distance_km: float, num_menu_items: int) -> float:
	var base_cost = 0.0
	var per_km_cost = 0.0
	var family_multiplier = num_menu_items
	
	match transport_type:
		0: # Land/Car
			base_cost = 50.0
			per_km_cost = 0.5
			family_multiplier = 1.0
		1: # Boat
			base_cost = 50.0
			per_km_cost = 0.2
		2: # Train
			base_cost = 50.0
			per_km_cost = 0.4
		3: # Plane
			base_cost = 30.0
			per_km_cost = 0.8
	
	return (base_cost + (distance_km * per_km_cost)) * family_multiplier

# Returns true if any segment of the path is within 100km of any target city.
func _is_path_near_country(dropped_pin_data: Array, target_cities: Array) -> bool:
	for i in range(dropped_pin_data.size() - 1):
		var p1_data = dropped_pin_data[i]
		var p2_data = dropped_pin_data[i+1]
		
		# Interpolate points along the path segment for accuracy.
		for k in range(21):
			var t = float(k) / 20.0
			var current_lat = lerp(p1_data.lat, p2_data.lat, t)
			var current_lng = lerp(p1_data.lng, p2_data.lng, t)
			
			# Check distance from the interpolated point to all target cities.
			for target_city in target_cities:
				if Utils.calculate_haversine_distance(current_lat, current_lng, target_city.lat, target_city.lng) < 100.0:
					return true # Path is too close, so we can stop checking.

	return false # The entire path was checked and was never too close.

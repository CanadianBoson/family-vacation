# quest_manager.gd
# This node now only checks for and stores the completion status of game objectives.
extends Node

var pin_manager: Node

# This dictionary maps a quest key to its checking function and expected result.
var quest_checkers = {
	"ThreeLetter": [_check_three_same_letter, true],
	"NoThreeLetter": [_check_three_same_letter, false],
	"SailFree": [_check_no_boats, true],
	"NoSailFree": [_check_no_boats, false],
	"NoCapitals": [_check_no_capitals, true],
	"SomeCapitals": [_check_no_capitals, false],
	"PathsCrossing": [_check_paths_crossing, true],
	"NoPathsCrossing": [_check_paths_crossing, false],
	"MinPopulation": [_check_min_population, true],
	"SomeSmallPopulation": [_check_min_population, false]
}

var quest_statuses = {}

func _ready():
	for quest_key in quest_checkers.keys():
		quest_statuses[quest_key] = false

# This is the main function called when pin data changes.
func check_all_conditions(dropped_pin_data: Array):
	print("--- Checking Conditions ---")
	for quest_key in quest_checkers.keys():
		var checker_func = quest_checkers[quest_key][0]
		var expected_result = quest_checkers[quest_key][1]
		var is_satisfied = (checker_func.call(dropped_pin_data) == expected_result)
		
		if quest_statuses.get(quest_key) != is_satisfied:
			quest_statuses[quest_key] = is_satisfied
			print("Status for '%s' changed to: %s" % [quest_key, is_satisfied])

# This function allows other nodes to check if a specific quest is done.
func is_quest_satisfied(quest_key: String) -> bool:
	return quest_statuses.get(quest_key, false)


# --- Condition Checking Functions (all unchanged) ---

func _check_three_same_letter(dropped_pin_data: Array) -> bool:
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

func _check_no_boats(dropped_pin_data: Array) -> bool:
	if dropped_pin_data.size() < 2: return false
	if not is_instance_valid(pin_manager): return false
	for i in range(dropped_pin_data.size() - 1):
		var pin1_data = dropped_pin_data[i]
		var pin2_data = dropped_pin_data[i+1]
		if pin_manager.get_travel_mode(pin1_data.index, pin2_data.index) == 1:
			return false
	return true

func _check_no_capitals(dropped_pin_data: Array) -> bool:
	if dropped_pin_data.is_empty(): return true
	for pin_data in dropped_pin_data:
		if pin_data.get("is_capital", false):
			return false
	return true

func _check_min_population(dropped_pin_data: Array) -> bool:
	if dropped_pin_data.is_empty(): return true
	for pin_data in dropped_pin_data:
		var population = pin_data.get("population", 0)
		if population < 500000:
			return false
	return true

func _check_paths_crossing(dropped_pin_data: Array) -> bool:
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

# --- Helper functions for line intersection (unchanged) ---
func _on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	if (q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and
		q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y)):
		return true
	return false

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

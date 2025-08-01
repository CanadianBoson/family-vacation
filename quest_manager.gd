# quest_manager.gd
# This node checks for and stores the completion status of game objectives.
extends Node

# --- New: This will hold a reference to the PinManager ---
var pin_manager: Node

# This dictionary maps a quest key to its checking function.
var quest_checkers = {
	"ThreeLetter": _check_three_same_letter,
	"SailFree": _check_no_boats,
	"NoCapitals": _check_no_capitals
}

var quest_statuses = {}

func _ready():
	for quest_key in quest_checkers.keys():
		quest_statuses[quest_key] = false

# This is the main function called when pin data changes.
func check_all_conditions(dropped_pin_data: Array):
	print("--- Checking Conditions ---")
	for quest_key in quest_checkers.keys():
		var checker_func = quest_checkers[quest_key]
		# Pass the pin data to the checker function.
		var is_satisfied = checker_func.call(dropped_pin_data)
		
		if quest_statuses[quest_key] != is_satisfied:
			quest_statuses[quest_key] = is_satisfied
			print("Status for '%s' changed to: %s" % [quest_key, is_satisfied])

func is_quest_satisfied(quest_key: String) -> bool:
	return quest_statuses.get(quest_key, false)


# --- Condition Checking Functions ---

func _check_three_same_letter(dropped_pin_data: Array) -> bool:
	if dropped_pin_data.size() < 3:
		return false

	var letter_counts = {}
	for pin_data in dropped_pin_data:
		var city_name = pin_data.get("city", "")
		if city_name.is_empty(): continue
		var first_letter = city_name[0].to_upper()
		
		if not letter_counts.has(first_letter):
			letter_counts[first_letter] = 0
		letter_counts[first_letter] += 1

	for letter in letter_counts.keys():
		if letter_counts[letter] >= 3:
			return true
			
	return false

# --- New function to check for boat travel ---
func _check_no_boats(dropped_pin_data: Array) -> bool:
	# A valid path requires at least two pins.
	if dropped_pin_data.size() < 2:
		return false
	
	# The pin_manager reference must be set.
	if not is_instance_valid(pin_manager):
		print("Error: PinManager reference not set in QuestManager.")
		return false

	# Iterate through each segment of the journey.
	for i in range(dropped_pin_data.size() - 1):
		var pin1_data = dropped_pin_data[i]
		var pin2_data = dropped_pin_data[i+1]
		
		# Get the travel mode for this segment.
		var travel_mode = pin_manager.get_travel_mode(pin1_data.index, pin2_data.index)
		
		# If any segment is a boat (mode 1), the condition is not met.
		if travel_mode == 1:
			return false
			
	# If the loop completes without finding any boats, the condition is met.
	return true

# Checks if any visited city is a capital.
func _check_no_capitals(dropped_pin_data: Array) -> bool:
	# If no pins are dropped, the condition is met by default.
	if dropped_pin_data.is_empty():
		return true

	# Iterate through each visited city.
	for pin_data in dropped_pin_data:
		# Check the 'is_capital' flag you added.
		if pin_data.get("is_capital", false):
			# If any city is a capital, the condition fails immediately.
			return false
			
	# If the loop completes without finding any capitals, the condition is met.
	return true

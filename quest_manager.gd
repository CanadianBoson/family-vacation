# quest_manager.gd
# This node checks for the completion of specific game objectives.
extends Node

# This dictionary maps a quest key (from dropdown_data.json) to a function.
# This makes it easy to add new condition checks in the future.
var quest_checkers = {
	"three_letter": _check_three_same_letter,
	# "Scout": _check_scout_condition, # Example for a future quest
	# "Analyze": _check_analyze_condition # Example for a future quest
}

# This is the main function called from other scripts.
# It checks all known conditions against the current pin data.
func check_all_conditions(dropped_pin_data: Array):
	print("--- Checking Conditions ---")
	for quest_key in quest_checkers.keys():
		var checker_func = quest_checkers[quest_key]
		# Call the function associated with the key.
		var is_satisfied = checker_func.call(dropped_pin_data)
		
		if is_satisfied:
			print("Condition '%s' has been met!" % quest_key)
		else:
			print("Condition '%s' has not been met." % quest_key)


# --- Condition Checking Functions ---

# Checks if three cities starting with the same letter have been visited.
# Corresponds to the "Gather" key in our dictionary.
func _check_three_same_letter(dropped_pin_data: Array) -> bool:
	if dropped_pin_data.size() < 3:
		return false

	# Use a dictionary to count the occurrences of each starting letter.
	var letter_counts = {}
	
	for pin_data in dropped_pin_data:
		var city_name = pin_data.get("city", "")
		if city_name.is_empty():
			continue
			
		var first_letter = city_name[0].to_upper()
		
		# Increment the count for this letter.
		if not letter_counts.has(first_letter):
			letter_counts[first_letter] = 0
		letter_counts[first_letter] += 1

	# Check if any letter has a count of 3 or more.
	for letter in letter_counts.keys():
		if letter_counts[letter] >= 3:
			return true
			
	return false

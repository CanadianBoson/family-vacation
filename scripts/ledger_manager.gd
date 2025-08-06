# ledger_manager.gd
# This script handles calculating distances and costs, and updating the ledger UI.
extends Node

@onready var _ledger_entries_vbox: VBoxContainer = $"../LedgerScrollContainer/LedgerEntriesVBox"
@onready var _overall_distance_label: Label = $"../LedgerHeaderVBox/OverallDistanceLabel"
@onready var _overall_cost_label: Label = $"../LedgerHeaderVBox/OverallCostLabel"

# A public function to calculate the total distance of a given path array.
func calculate_total_distance(path_data: Array) -> float:
	var cumulative_distances = _calculate_cumulative_distances_km(path_data)
	if cumulative_distances.is_empty():
		return 0.0
	return cumulative_distances.back()

func _calculate_cumulative_distances_km(dropped_pin_data: Array) -> Array:
	var cumulative_distances_km = []
	if dropped_pin_data.size() > 0:
		cumulative_distances_km.append(0.0)
		for i in range(1, dropped_pin_data.size()):
			var prev_pin_data = dropped_pin_data[i-1]
			var current_pin_data = dropped_pin_data[i]
			var segment_distance_km = Utils.calculate_haversine_distance(prev_pin_data.lat, prev_pin_data.lng, current_pin_data.lat, current_pin_data.lng)
			cumulative_distances_km.append(cumulative_distances_km[i-1] + segment_distance_km)
	return cumulative_distances_km

func update_ledger_display(pin_manager: Node, num_menu_items: int):
	var dropped_pin_data = pin_manager.dropped_pin_data

	for child in _ledger_entries_vbox.get_children():
		child.queue_free()

	var cumulative_distances_km = _calculate_cumulative_distances_km(dropped_pin_data)
	var overall_distance_km = cumulative_distances_km.back() if not cumulative_distances_km.is_empty() else 0.0
	
	var overall_cost = 0.0

	_overall_distance_label.text = "Overall Distance: %.2f km" % overall_distance_km
	_overall_distance_label.add_theme_color_override("font_color", Color.DARK_BLUE)

	if dropped_pin_data.is_empty():
		var no_pins_label = Label.new()
		no_pins_label.text = "No pins dropped yet."
		_ledger_entries_vbox.add_child(no_pins_label)
		_overall_cost_label.text = "Overall Cost: $0.00"
		_overall_cost_label.add_theme_color_override("font_color", Color.DARK_GREEN)
		return

	# Add entries for each dropped pin
	for i in range(dropped_pin_data.size()):
		var pin_number = i + 1
		var city_name = dropped_pin_data[i].city
		var entry_text = ""

		if i == 0:
			entry_text = "%d. %s (Start)" % [pin_number, city_name]
		else:
			var prev_pin_data = dropped_pin_data[i-1]
			var current_pin_data = dropped_pin_data[i]
			var segment_distance_km = Utils.calculate_haversine_distance(prev_pin_data.lat, prev_pin_data.lng, current_pin_data.lat, current_pin_data.lng)
			
			var travel_mode_int = pin_manager.get_travel_mode(prev_pin_data.index, current_pin_data.index)
			var travel_mode_str = "Plane"
			match travel_mode_int:
				0: travel_mode_str = "Car"
				1: travel_mode_str = "Boat"
				2: travel_mode_str = "Train"

			var leg_cost = Utils.calculate_leg_cost(travel_mode_int, segment_distance_km, num_menu_items)
			overall_cost += leg_cost

			entry_text = "%d. %s (%.1f km by %s, %.2f€" % [pin_number, city_name, segment_distance_km, travel_mode_str, leg_cost]

		var entry_label = Label.new()
		entry_label.text = entry_text
		entry_label.add_theme_color_override("font_color", Color.DARK_BLUE)
		entry_label.add_theme_font_size_override("font_size", 14)
		_ledger_entries_vbox.add_child(entry_label)
		
		var spacer_entry = Control.new()
		spacer_entry.set_custom_minimum_size(Vector2(0, 5))
		_ledger_entries_vbox.add_child(spacer_entry)

	_overall_cost_label.text = "Overall Cost: %.2f€" % overall_cost
	_overall_cost_label.add_theme_color_override("font_color", Color.DARK_GREEN)

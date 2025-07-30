# LedgerManager.gd
# This script handles calculating distances and updating the ledger UI.
extends Node

# Reference to the VBoxContainer that holds ledger entries (inside the ScrollContainer)
@onready var _ledger_entries_vbox: VBoxContainer = $"../LedgerScrollContainer/LedgerEntriesVBox" 
# Reference to the VBoxContainer that holds the title and overall distance
@onready var _ledger_header_vbox: VBoxContainer = $"../LedgerHeaderVBox"
# Reference to the Label that displays the overall distance
@onready var _overall_distance_label: Label = $"../LedgerHeaderVBox/OverallDistanceLabel" # Adjust path if label name differs

# Earth's radius in kilometers for Haversine formula
const EARTH_RADIUS_KM = 6371.0

# Calculates distance between two lat/lng points using Haversine formula
func _calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	# Convert degrees to radians
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

# Calculates cumulative distances in kilometers between dropped pins
func _calculate_cumulative_distances_km(dropped_pin_data: Array) -> Array:
	var cumulative_distances_km = []
	var current_total_dist_km = 0.0
	if dropped_pin_data.size() > 0:
		cumulative_distances_km.append(0.0) # The first pin has 0 distance from the start of the path
		for i in range(1, dropped_pin_data.size()):
			var prev_pin_data = dropped_pin_data[i-1]
			var current_pin_data = dropped_pin_data[i]
			
			var lat1 = prev_pin_data.lat
			var lon1 = prev_pin_data.lng
			var lat2 = current_pin_data.lat
			var lon2 = current_pin_data.lng
			
			var segment_distance_km = _calculate_haversine_distance(lat1, lon1, lat2, lon2)
			current_total_dist_km += segment_distance_km
			cumulative_distances_km.append(current_total_dist_km)
	return cumulative_distances_km

# Updates the ledger display on the right-hand side
func update_ledger_display(dropped_pin_data: Array):
	# Clear only the dynamically added entries within the scrollable VBoxContainer
	for child in _ledger_entries_vbox.get_children():
		child.queue_free()

	var cumulative_distances_km = _calculate_cumulative_distances_km(dropped_pin_data)
	var overall_distance_km = cumulative_distances_km.back() if not cumulative_distances_km.is_empty() else 0.0

	# Update the existing overall distance label
	_overall_distance_label.text = "Overall Distance: %.2f km" % overall_distance_km
	_overall_distance_label.add_theme_color_override("font_color", Color.DARK_BLUE)

	if dropped_pin_data.is_empty():
		var no_pins_label = Label.new()
		no_pins_label.text = "No pins dropped yet."
		_ledger_entries_vbox.add_child(no_pins_label)
		return

	# Add entries for each dropped pin to the scrollable VBoxContainer
	for i in range(dropped_pin_data.size()):
		var pin_number = i + 1
		var city_name = dropped_pin_data[i].city
		var total_dist_at_this_pin_km = max(0.0, cumulative_distances_km[i] - cumulative_distances_km[i-1])

		var entry_text = "%d. %s (%.2f km away)" % [pin_number, city_name, total_dist_at_this_pin_km]
		var entry_label = Label.new()
		entry_label.text = entry_text
		entry_label.add_theme_color_override("font_color", Color.DARK_BLUE)
		entry_label.add_theme_font_size_override("font_size", 14) # Smaller font for entries
		_ledger_entries_vbox.add_child(entry_label)
		
		var spacer_entry = Control.new()
		spacer_entry.set_custom_minimum_size(Vector2(0, 5))
		_ledger_entries_vbox.add_child(spacer_entry)

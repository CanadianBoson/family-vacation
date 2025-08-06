# info_popup.gd
# Manages the content and visibility of the city information popup.
extends PanelContainer

@onready var info_grid: GridContainer = $"VBoxContainer/ScrollContainer/InfoGrid"
@onready var close_button: Button = $"VBoxContainer/HBoxContainer/CloseButton"
@onready var view_toggle_button: CheckButton = $"VBoxContainer/HBoxContainer/ViewToggleButton"
@onready var animation_player: AnimationPlayer = get_node("/root/GameScene/AnimationPlayer")

const COLUMN_WIDTHS = [180, 100, 120, 120, 120, 80] # City, Country, Lat, Lng, Pop, Capital

var _all_locations_data = []
var _dropped_pin_data = []

# --- New: Variables to track sorting state ---
var _sort_key = "city"
var _sort_ascending = true

func _ready():
	hide()
	modulate.a = 0.0
	close_button.pressed.connect(_on_close_button_pressed)
	view_toggle_button.toggled.connect(_on_view_toggle_toggled)

func show_popup(all_locations: Array, dropped_pins: Array):
	_all_locations_data = all_locations
	_dropped_pin_data = dropped_pins
	
	# Sort the data by the default key before showing
	_sort_data_list(_all_locations_data)
	_sort_data_list(_dropped_pin_data)
	
	view_toggle_button.button_pressed = false
	_update_content(_all_locations_data)
	
	show()
	animation_player.play("popup_info")

func _update_content(data_to_display: Array):
	for child in info_grid.get_children():
		child.queue_free()

	# Add the table headers.
	_add_header_label("City", COLUMN_WIDTHS[0], "city")
	_add_header_label("Country", COLUMN_WIDTHS[1], "country")
	_add_header_label("Latitude", COLUMN_WIDTHS[2], "lat")
	_add_header_label("Longitude", COLUMN_WIDTHS[3], "lng")
	_add_header_label("Population", COLUMN_WIDTHS[4], "population")
	_add_header_label("Capital", COLUMN_WIDTHS[5], "is_capital")
	_add_header_label("EU", COLUMN_WIDTHS[5], "is_eu")

	# Add a row for each city from the loaded data.
	for location in data_to_display:
		_add_cell_label(location.city)
		_add_cell_label(location.country)
		_add_cell_label("%.2f" % location.lat)
		_add_cell_label("%.2f" % location.lng)
		_add_cell_label("%.0fk" % float(location.population / 1000))
		_add_cell_label("Yes" if location.get("is_capital") else "No")
		_add_cell_label("Yes" if location.get("is_eu") else "No")
		for i in range(7):
			var separator = HSeparator.new()
			info_grid.add_child(separator)

# This function now creates a clickable Button for the header.
func _add_header_label(text: String, min_width: int, sort_key: String):
	var header_button = Button.new()
	header_button.text = text
	header_button.custom_minimum_size.x = min_width
	header_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Make the button flat to look like a label, but remain clickable.
	header_button.flat = true
	header_button.add_theme_font_size_override("font_size", 18)
	
	# Connect the button's pressed signal to the sorting function.
	# We bind the 'sort_key' so the function knows which column was clicked.
	header_button.pressed.connect(_on_header_clicked.bind(sort_key))
	
	info_grid.add_child(header_button)

func _add_cell_label(text: String):
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_grid.add_child(label)

# --- New: This function is called when a header button is clicked ---
func _on_header_clicked(new_sort_key: String):
	if new_sort_key == _sort_key:
		# If clicking the same column, reverse the sort direction.
		_sort_ascending = not _sort_ascending
	else:
		# If clicking a new column, set it as the key and default to ascending.
		_sort_key = new_sort_key
		_sort_ascending = true
	
	# Sort both of our data lists.
	_sort_data_list(_all_locations_data)
	_sort_data_list(_dropped_pin_data)
	
	# Refresh the grid to show the newly sorted data.
	_on_view_toggle_toggled(view_toggle_button.button_pressed)

# --- New: Helper function to sort a list of dictionaries ---
func _sort_data_list(data_list: Array):
	data_list.sort_custom(func(a, b):
		var val_a = a.get(_sort_key)
		var val_b = b.get(_sort_key)
		
		# Handle cases where data might be missing.
		if val_a == null: return false if _sort_ascending else true
		if val_b == null: return true if _sort_ascending else false

		if _sort_ascending:
			return val_a < val_b
		else:
			return val_a > val_b
	)

func _on_close_button_pressed():
	animation_player.play("popout_info")
	await animation_player.animation_finished
	hide()

func _on_view_toggle_toggled(button_pressed: bool):
	if button_pressed:
		_update_content(_dropped_pin_data)
	else:
		_update_content(_all_locations_data)

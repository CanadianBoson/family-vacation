# info_popup.gd
# Manages the content and visibility of the city information popup.
extends PanelContainer

# Use node paths, which are reliable.
@onready var info_grid: GridContainer = $"VBoxContainer/ScrollContainer/InfoGrid"
@onready var close_button: Button = $"VBoxContainer/HBoxContainer/CloseButton"
@onready var animation_player: AnimationPlayer = get_node("/root/GameScene/AnimationPlayer")

func _ready():
	# Start hidden and ready for animation.
	hide()
	modulate.a = 0.0
	# Connect the close button's signal to our close function.
	close_button.pressed.connect(_on_close_button_pressed)

# This is the main function to call from the game scene.
func show_popup(all_locations_data: Array):
	_update_content(all_locations_data)
	show()
	animation_player.play("popup_info")

# Fills the grid with data about all available cities.
func _update_content(all_locations_data: Array):
	# Clear any old data from the grid.
	for child in info_grid.get_children():
		child.queue_free()

	# Add the table headers.
	_add_header_label("City")
	_add_header_label("Country")
	_add_header_label("Latitude")
	_add_header_label("Longitude")
	_add_header_label("Population")
	_add_header_label("Capital")

	# Add a row for each city from the loaded data.
	for location in all_locations_data:
		_add_cell_label(location.city)
		_add_cell_label(location.get("country", "N/A"))
		_add_cell_label("%.2f" % location.lat)
		_add_cell_label("%.2f" % location.lng)
		_add_cell_label("%.0fK" % float(location.population / 1000))
		_add_cell_label("Yes" if location.get("is_capital") else "No")
		for i in range(6):
			var separator = HSeparator.new()
			info_grid.add_child(separator)

# Helper function to create and add a styled header label.
func _add_header_label(text: String):
	var label = Label.new()
	label.text = text
	# Tell the label to expand to fill the cell's width.
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_grid.add_child(label)

# Helper function to create and add a standard data cell label.
func _add_cell_label(text: String):
	var label = Label.new()
	label.text = text
	# Tell the label to expand to fill the cell's width.
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Center the cell text for a cleaner look.
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_grid.add_child(label)

# Plays the fade-out animation when the close button is pressed.
func _on_close_button_pressed():
	animation_player.play("popout_info")
	# Wait for the animation to finish before hiding the node.
	await animation_player.animation_finished
	hide()

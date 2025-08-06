# family_item.gd
# This script represents a single confirmed entry in the right-hand list.
extends PanelContainer

# This signal will be emitted when the item is middle-clicked.
signal delete_requested

func _ready():
	# Connect to the input signal to detect mouse clicks.
	gui_input.connect(_on_gui_input)

# This function allows the main scene to set the display text.
func set_info(text: String):
	$InfoLabel.text = text

# In confirmed_family_item.gd

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.is_pressed():
		delete_requested.emit()

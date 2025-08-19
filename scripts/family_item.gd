# family_item.gd
# This script represents a single confirmed entry in the right-hand list.
extends PanelContainer

@onready var button_sound = $ButtonSound

# This signal will be emitted when the item is right-clicked.
signal delete_requested

func _ready():
	gui_input.connect(_on_gui_input)

func set_info(text: String):
	$InfoLabel.text = text

# In confirmed_family_item.gd

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():	
		delete_requested.emit()
		if GlobalState.is_sound_enabled:
			button_sound.play()

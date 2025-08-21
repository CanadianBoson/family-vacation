# leaderboard.gd
# Manages the content and visibility of the city information popup.
extends PanelContainer

@onready var info_grid: GridContainer = $"VBoxContainer/ScrollContainer/InfoGrid"
@onready var close_button: Button = $"VBoxContainer/HBoxContainer/CloseButton"
@onready var animation_player: AnimationPlayer = get_tree().get_root().get_node("MainMenu/AnimationPlayer")
@onready var button_sound = get_tree().get_root().get_node("MainMenu/MainMenu/ButtonSound")

const COLUMN_WIDTHS = [150, 250, 130, 80]

func _ready():
	hide()
	modulate.a = 0.0
	close_button.pressed.connect(_on_close_leaderboard_button_pressed)

func show_popup():
	show()
	animation_player.play("popup_info")
	_update_content()

func _update_content():
	for child in info_grid.get_children():
		child.queue_free()

	# Add the table headers.
	_add_header_label("Family Size", COLUMN_WIDTHS[0])
	_add_header_label("Family Members", COLUMN_WIDTHS[1])
	_add_header_label("Completion", COLUMN_WIDTHS[2])
	_add_header_label("Score", COLUMN_WIDTHS[3])

	# Add a row for each leader from the loaded data.
	for l in GlobalState.leaders:
		_add_cell_label(str(l[0]))
		_add_cell_label(str(l[1]))
		_add_cell_label(str(int(l[2] * 100)) + "%")
		_add_cell_label(str(l[3]))
		for i in range(4):
			var separator = HSeparator.new()
			info_grid.add_child(separator)

func _add_header_label(text: String, min_width: int):
	var header_label = Label.new()
	header_label.text = text
	header_label.custom_minimum_size.x = min_width
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_grid.add_child(header_label)

func _add_cell_label(text: String):
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_grid.add_child(label)

func _on_close_leaderboard_button_pressed():
	if GlobalState.is_sound_enabled:
		button_sound.play()
	animation_player.play("popout_info")
	await animation_player.animation_finished
	hide()
	
		

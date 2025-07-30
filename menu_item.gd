# menu_item.gd
# This script controls a single item in our vertical menu, including a dropdown.
# The root node is now a VBoxContainer to handle automatic resizing.
extends VBoxContainer

@onready var header: PanelContainer = $Header
@onready var label: Label = $Header/HBoxContainer/ItemLabel
@onready var circle_image: TextureRect = $Header/HBoxContainer/CircleImage
@onready var dropdown_container: VBoxContainer = $DropdownContainer
@onready var dropdown_animator: AnimationPlayer = $DropdownAnimator

var dropdown_data = []
var is_open = false
var is_animating = false

func _ready():
	_load_dropdown_data()
	header.gui_input.connect(_on_header_gui_input)
	# Start with the dropdown hidden. Its size will not be part of the layout.
	dropdown_container.hide()

func setup(item_text: String, background_color: Color, image_path: String):
	label.text = item_text
	
	if not image_path.is_empty():
		circle_image.texture = load(image_path)

	var new_stylebox = header.get("theme_override_styles/panel").duplicate()
	new_stylebox.bg_color = background_color
	header.add_theme_stylebox_override("panel", new_stylebox)

func _load_dropdown_data():
	var file_path = "res://dropdown_data.json"
	if not FileAccess.file_exists(file_path): return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)
	if typeof(json_data) == TYPE_DICTIONARY and json_data.has("details"):
		dropdown_data = json_data.details

func _on_header_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if not is_animating:
			toggle_dropdown()

func toggle_dropdown():
	is_animating = true
	is_open = not is_open
	
	if is_open:
		_populate_dropdown()
		# Make the dropdown visible. The parent VBoxContainer will now
		# automatically account for its size and push other items down.
		dropdown_container.show()
		dropdown_animator.play("open")
		await dropdown_animator.animation_finished
	else:
		dropdown_animator.play("close")
		await dropdown_animator.animation_finished
		# Hide the dropdown. The parent VBoxContainer will automatically
		# reclaim the space, moving other items up.
		dropdown_container.hide()
		_clear_dropdown()
	
	is_animating = false

func _populate_dropdown():
	_clear_dropdown()
	if dropdown_data.is_empty(): return

	var num_to_show = randi_range(1,3)
	dropdown_data.shuffle()

	for i in range(min(num_to_show, dropdown_data.size())):
		var bullet_point = Label.new()
		bullet_point.text = "• " + dropdown_data[i]
		
		# --- FIX: Enable text wrapping for bullet points ---
		# 1. Tell the label to fill the available horizontal space.
		bullet_point.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# 2. Set the autowrap mode to break text into new lines.
		# The constant is now part of the TextServer class in Godot 4.
		bullet_point.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# ----------------------------------------------------
		
		# Add a smaller font size for the bullet points.
		bullet_point.add_theme_font_size_override("font_size", 12)
		bullet_point.set("theme_override_colors/font_color", Color.DARK_ORCHID)
		dropdown_container.add_child(bullet_point)

func _clear_dropdown():
	for child in dropdown_container.get_children():
		child.queue_free()

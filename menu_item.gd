# menu_item.gd
# This script controls a single item in our vertical menu, including a dropdown.
# The root node is now a VBoxContainer to handle automatic resizing.
extends VBoxContainer

@onready var header: PanelContainer = $Header
@onready var label: Label = $Header/HBoxContainer/ItemLabel
@onready var circle_image: TextureRect = $Header/HBoxContainer/CircleImage
@onready var dropdown_container: VBoxContainer = $DropdownContainer
@onready var dropdown_animator: AnimationPlayer = $DropdownAnimator

var is_open = false
var is_animating = false

# This array is now set by the parent menu and contains dictionaries.
var bullet_points_to_display = []

func _ready():
	header.gui_input.connect(_on_header_gui_input)
	dropdown_container.hide()

# The setup function now accepts the pre-generated list of bullet point dictionaries.
func setup(item_text: String, background_color: Color, image_path: String, bullet_points: Array):
	label.text = item_text
	bullet_points_to_display = bullet_points # Store the unique list of dictionaries
	
	if not image_path.is_empty():
		circle_image.texture = load(image_path)

	var new_stylebox = header.get("theme_override_styles/panel").duplicate()
	new_stylebox.bg_color = background_color
	header.add_theme_stylebox_override("panel", new_stylebox)

func _on_header_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if not is_animating:
			toggle_dropdown()

func toggle_dropdown():
	is_animating = true
	is_open = not is_open
	
	if is_open:
		_populate_dropdown()
		dropdown_container.show()
		dropdown_animator.play("open")
		await dropdown_animator.animation_finished
	else:
		dropdown_animator.play("close")
		await dropdown_animator.animation_finished
		dropdown_container.hide()
		_clear_dropdown_nodes()
	
	is_animating = false

# This function now creates the UI from the pre-generated list of dictionaries.
func _populate_dropdown():
	_clear_dropdown_nodes()

	for item_data in bullet_points_to_display:
		var bullet_point = Label.new()
		
		# Get the text and difficulty from the dictionary.
		var item_text = item_data.get("text", "N/A")
		var item_difficulty = item_data.get("difficulty", 0)
		
		# Format the string to include the difficulty.
		bullet_point.text = "• %s (%d)" % [item_text, item_difficulty]
		
		bullet_point.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bullet_point.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		bullet_point.add_theme_font_size_override("font_size", 12)
		bullet_point.set("theme_override_colors/font_color", Color.DARK_ORCHID)
		dropdown_container.add_child(bullet_point)

func _clear_dropdown_nodes():
	for child in dropdown_container.get_children():
		child.queue_free()

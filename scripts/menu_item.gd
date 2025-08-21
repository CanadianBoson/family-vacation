# menu_item.gd
# This script now handles dynamic font sizing for its label.
extends VBoxContainer

@onready var header: PanelContainer = $Header
@onready var label: Label = $Header/HBoxContainer/ItemLabel
@onready var circle_image: TextureRect = $Header/HBoxContainer/CircleImage
@onready var dropdown_container: VBoxContainer = $DropdownContainer
@onready var dropdown_animator: AnimationPlayer = $DropdownAnimator
@onready var dropdown_sound: AudioStreamPlayer2D = $DropdownSound

var is_open = false
var is_animating = false
var bullet_points_to_display = []

var _quest_manager: Node
var _background_color: Color

func _ready():
	header.gui_input.connect(_on_header_gui_input)
	dropdown_container.hide()
	
	var game_scene = get_tree().get_root().get_node("GameScene")
	if game_scene:
		game_scene.data_updated.connect(_on_game_data_updated)

# The setup function now includes the font size logic.
func setup(item_text: String, background_color: Color, image_path: String, bullet_points: Array, quest_manager_ref: Node):
	label.text = item_text
	bullet_points_to_display = bullet_points
	_quest_manager = quest_manager_ref
	_background_color = background_color
	
	var text_length = item_text.length()
	var new_font_size = 16 # Default font size
	while label.get_theme_font("font").get_string_size(label.text, label.horizontal_alignment, -1, new_font_size).x > 50:
		new_font_size -= 1
		
	# Apply the calculated font size as an override.
	label.add_theme_font_size_override("font_size", new_font_size)
	
	if not image_path.is_empty():
		circle_image.texture = load(image_path)

	var new_stylebox = header.get("theme_override_styles/panel").duplicate()
	new_stylebox.bg_color = background_color
	header.add_theme_stylebox_override("panel", new_stylebox)
	
	_update_completion_border()

func _on_game_data_updated():
	_update_completion_border()
	if is_open:
		_populate_dropdown()

func _update_completion_border():
	if not is_instance_valid(_quest_manager): return

	var all_satisfied = true
	if bullet_points_to_display.is_empty():
		all_satisfied = false
	
	for quest_data in bullet_points_to_display:
		var quest_key = quest_data.get("key")
		if not _quest_manager.is_quest_satisfied(quest_key):
			all_satisfied = false
			break
	
	var stylebox: StyleBoxFlat = header.get("theme_override_styles/panel").duplicate()
	
	if all_satisfied:
		stylebox.border_width_left = 4
		stylebox.border_width_right = 4
		stylebox.border_width_top = 4
		stylebox.border_width_bottom = 4
		stylebox.border_color = _background_color.darkened(0.3)
	else:
		stylebox.border_width_left = 0
		stylebox.border_width_right = 0
		stylebox.border_width_top = 0
		stylebox.border_width_bottom = 0
	
	header.add_theme_stylebox_override("panel", stylebox)

func _on_header_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if not is_animating:
			toggle_dropdown()

func toggle_dropdown():
	if GlobalState.is_sound_enabled:
		dropdown_sound.play()
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

func _populate_dropdown():
	_clear_dropdown_nodes()
	for item_data in bullet_points_to_display:
		var bullet_point = Label.new()
		var icon = "✗"
		bullet_point.set("theme_override_colors/font_color", Color.DARK_ORCHID)
		if _quest_manager.is_quest_satisfied(item_data.get("key")):
			icon = "✓"
			bullet_point.set("theme_override_colors/font_color", Color.DARK_SLATE_GRAY)
		bullet_point.text = "%s %s (%d)" % [icon, item_data.get("text", "N/A"), item_data.get("difficulty", "N/A")]
		bullet_point.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bullet_point.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bullet_point.add_theme_font_size_override("font_size", 10)
		dropdown_container.add_child(bullet_point)

func _clear_dropdown_nodes():
	for child in dropdown_container.get_children():
		child.queue_free()

# instructions_popup.gd
# This script controls the visibility and content of the instructions popup.
extends PanelContainer

@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton
@onready var instructions_text: RichTextLabel = $VBoxContainer/InstructionsText
@onready var animation_player: AnimationPlayer = get_tree().get_root().get_node("GameScene/AnimationPlayer")

# --- You can edit the instructions text here ---
const INSTRUCTIONS = """
Welcome to the Journey Planner!

- **Objective:** Plan routes by clicking on the black circles on the map. Each route will be assigned quests, shown in the dropdown menus on the left.

- **Scoring:** Completing a quest adds its difficulty to your score. Completing all quests for a single traveler grants a bonus.

- **Controls:**
  - **Left-Click:** Place a pin on an available city.
  - **Right-Click:** Remove a pin from the map.
  - **Drag-and-Drop:** Move an existing pin to a new, unoccupied city.
  - **Middle-Click:** In the Family scene, middle-click a confirmed member to remove them.

- **UI:**
  - Use the **Info** button to see a sortable list of all available cities.
  - Use the **Ledger** on the right to track your current path's distance and cost.
"""

func _ready():
	# Hide the popup at the start and connect the close button.
	hide()
	modulate.a = 0.0 # Start transparent for animations
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Set the text for the RichTextLabel.
	instructions_text.text = INSTRUCTIONS

# This function is called from the main scene to show the popup.
func show_popup():
	show()
	# Note: You will need to add animation tracks for "InstructionsPopup"
	# to your AnimationPlayer for this to work visually.
	animation_player.play("popup_in")
	instructions_text.text = INSTRUCTIONS

func _on_close_button_pressed():
	animation_player.play("popup_out")
	await animation_player.animation_finished
	hide()

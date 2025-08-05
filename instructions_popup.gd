# instructions_popup.gd
# This script controls the visibility and content of the instructions popup.
extends PanelContainer

@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton
@onready var instructions_text: RichTextLabel = $VBoxContainer/InstructionsText
@onready var animation_player: AnimationPlayer = get_tree().get_root().get_node("GameScene/AnimationPlayer")

# --- You can edit the instructions text here ---
const INSTRUCTIONS = """
[center][b]Welcome to Family Vacation![/b][/center]

[b]Objective:[/b]
Design a route which satisfies as many family members as possible. Every family member has demands of various difficulties, and your score is the sum of these values along with bonuses for satisfying every demand.

[b]Family Controls:[/b]
Click on a name to expand or contract the demands of family members. Demands that are met appear with a checkmark. Family members with all demands met show up with a border.

[b]Map Controls:[/b]
[ul]
[b]Left-Click:[/b] Place a pin on an available city.
[b]Right-Click:[/b] Remove a pin from the map.
[b]Drag-and-Drop:[/b] Move an existing pin to a new, unoccupied city.
[b]Hover:[/b] Hover over a city briefly to see the name, and for one second to get more details.
[/ul]

[b]Buttons:[/b]
[ul]
[b]Back[/b] gets you back to the main menu.
[b]Family[/b] gets you back to the family menu.
[b]Clear All[/b] clears the route and all pins.
[b]Stats[/b] gives tabular data for cities and dropped pins.
[b]Reverse[/b] switches the direction of the trip.
[b]Load Max[/b] reloads the route that had the highest score so far.
[b]Info[/b] loads this tooltip.
[b]Grid[/b] toggles a grid for aesthetic purposes.
[/ul]

[ul]
Use the [b]Ledger[/b] on the left to track your current path's distance and cost.
[/ul]
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

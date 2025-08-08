# instructions_popup.gd
# This script controls the visibility and content of the instructions popup.
extends PanelContainer

@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton
@onready var instructions_text: RichTextLabel = $VBoxContainer/InstructionsText
@onready var animation_player: AnimationPlayer = get_tree().get_root().get_node("FamilyScene/AnimationPlayer")
@onready var button_sound = get_tree().get_root().get_node("FamilyScene/ButtonSound")

const INSTRUCTIONS = """
[center][b]Welcome to Family Vacation![/b][/center]

[b]Info:[/b]
Start by choosing some members to join your family. You can choose between two
pictures and personalize their names, and when ready click 'Add to Family'. You can remove
family members by middle clicking them in the right panel. Once you've added at least
two family members (maximum of six) you can start the game.

[b]Initial Difficulty:[/b]
Adjust the slider to set the initial difficulty in the game. Note that having more
family members tends to make the game more difficult due to competing demands. Note
that demands are randomized and it may be impossible to satisfy everyone, let alone
a single family member.

[b]UI:[/b]
[ul]
Use the [b]Back[/b] button to return to the main screen.
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
	if GlobalState.is_sound_enabled:
		button_sound.play()
	animation_player.play("popup_out")
	await animation_player.animation_finished
	hide()

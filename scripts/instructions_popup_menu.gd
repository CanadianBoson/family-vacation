# instructions_popup_menu.gd
# This script controls the visibility and content of the instructions popup.
extends PanelContainer

@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton
@onready var instructions_text: RichTextLabel = $VBoxContainer/InstructionsText
@onready var animation_player: AnimationPlayer = get_tree().get_root().get_node("MainMenu/AnimationPlayer")
@onready var button_sound = get_tree().get_root().get_node("MainMenu/MainMenu/ButtonSound")

const INSTRUCTIONS = """
[center][bfont]Welcome to Family Vacation![/bfont][/center]

Click the [bfont]New Family[/bfont] button to make a family that will travel around Europe, all with competing demands. Work your hardest to satisfy everyone, but be aware due to randomness that it might be impossible to make everyone happy!

Click the [bfont]Casual Mode[/bfont] button to play with a randomized family. You have the option to play entirely new trips with the [bfont]Brand New[/bfont] button, play trips others have successfully completed with [bfont]Completion Mode[/bfont] , or try where others have failed with [bfont]Frustration Mode[/bfont].

Click the [bfont]Leaderboard[/bfont] button to see other families that have made it to the top. The leaderboard is live so come back once you've had a good run to see if you're on it -- your trips are automatically saved when starting a new trip in Family mode! It loads from the cloud so refresh it if it appears blank.
"""

func _ready():
	# Hide the popup at the start and connect the close button.
	hide()
	modulate.a = 0.0 # Start transparent for animations
	close_button.pressed.connect(_on_close_button_pressed)

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

# instructions_popup.gd
# This script controls the visibility and content of the instructions popup.
extends PanelContainer

@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton
@onready var instructions_text: RichTextLabel = $VBoxContainer/InstructionsText
@onready var animation_player: AnimationPlayer = get_tree().get_root().get_node("GameScene/AnimationPlayer")
@onready var button_sound = get_tree().get_root().get_node("GameScene/ButtonSound")

const INSTRUCTIONS = """
[center][bfont]Welcome to Family Vacation![/bfont][/center]

Objective:
Design a route which satisfies as many family members as possible. Every family member has demands of various difficulties, and your score is the sum of these values along with bonuses for satisfying all a family member's demands.

Mode:
[ul]
[bfont]Family Mode[/bfont]: The default mode. New quests for the same family members.
[bfont]Completion Mode[/bfont]: Randomly play a family/quests combination that another player has previously succeeded with.
[bfont]Frustration Mode[/bfont]: Randomly play a family/quests combination that another player has ALMOST succeeded with.
[/ul]

Family Controls:
Click on a name to expand or contract the demands of family members. Demands that are met appear with a checkmark. Family members with all demands met show up with a border.

Map Controls:
[ul]
Left-Click: Place a pin on an available city.
Right-Click: Remove a pin from the map.
Drag-and-Drop: Move an existing pin to a new, unoccupied city.
Hover: Hover over a city briefly to see the name, and for one second to get more details.
[/ul]

Info:
[ul]
Use the [bfont]Info[/bfont] button to show comprehensive statistics for all locations along with the overall and endpoint latitude and longitude values.
Clicking on a header for a given column will sort the values in order.
[/ul]

Transport Options:
Different methods of transport are generated automatically depending on the distance and terrain between two cities.

The calculation and cost of different methods is shown below:
[ul]
Car (Green): [ul]
	Distance under 300km and 60% of points between two cities are land
	Cost is 120 + 3 * sqrt(num_kms) [/ul]
Boat (Blue): [ul]
	Distance under 800km and 60% of points between two cities are water
	Cost is (40 + 5 * sqrt(num_kms)) * num_family [/ul]
Train (Purple): [ul]
	Distance between 300km and 1000km and 60% of points between two cities are land
	Cost is (60 + 8 * sqrt(num_kms)) * num_family [/ul]
Plane (Red): [ul]
	All other cases
	Cost is (150 + 15 * sqrt(num_kms)) * num_family [/ul][/ul]

Buttons:
[ul]
[bfont]Back[/bfont] gets you back to the main menu.
[bfont]Family[/bfont] gets you back to the family menu.
[bfont]Info[/bfont] loads this tooltip.
[bfont]New Trip[/bfont] gives the option to start a new trip.
[ul]
In 'Family Mode' you will be prompted to adjust the difficulty for the same family.
In 'Completion' or 'Frustration' modes, a random trip will be generated.
[/ul]
[bfont]Clear All[/bfont] clears the route and all pins.
[bfont]Reverse[/bfont] switches the direction of the trip.
[bfont]Load Max[/bfont] reloads the route that had the highest score so far.
[bfont]Stats[/bfont] gives tabular data for cities and dropped pins.
[/ul]

Toggles:
[ul]
[bfont]Grid[/bfont] toggles a grid for aesthetic purposes.
[bfont]Sound[/bfont] toggles the sound game-wide.
[bfont]Boats[/bfont] shows possible lines that boats can take.
[/ul]

Scoring:
[ul]
Use the [bfont]Ledger[/bfont] on the left to track your current path's distance and cost.
The bottom left corner shows the current difficulty along with the scores from demands and from family members.
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

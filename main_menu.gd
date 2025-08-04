# main_menu.gd
# Script for the main menu screen.

extends Control

# This function is called when the 'Start' button is pressed.
func _on_start_button_pressed():
	var result = get_tree().change_scene_to_file("res://game_scene.tscn")
	if result != OK:
		print("Error: Could not load the game scene.")

# This function is called when the 'Instructions' button is pressed.
func _on_instructions_button_pressed():
	var result = get_tree().change_scene_to_file("res://instructions.tscn")
	if result != OK:
		print("Error: Could not load the instructions scene.")

# This function is called when the 'Exit' button is pressed.
func _on_exit_button_pressed():
	# This line quits the application.
	get_tree().quit()
	
func _on_button_family_pressed():
	get_tree().change_scene_to_file("res://family_scene.tscn")	

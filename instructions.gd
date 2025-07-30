# instructions.gd
# Script for the instructions screen.

extends Node2D

# This function is called when the 'Back' button is pressed.
func _on_back_button_pressed():
	var result = get_tree().change_scene_to_file("res://main_menu.tscn")
	if result != OK:
		print("Error: Could not load the main menu scene.")

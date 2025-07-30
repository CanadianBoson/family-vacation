# grid_overlay.gd
# This script draws a grid over a specified area.
extends Node2D

# Set to true to make the grid visible by default.
var is_grid_visible = false

# --- Grid Customization ---
# The spacing between grid lines in pixels.
var grid_spacing = 100
# The color of the grid lines. A low alpha makes it subtle.
var grid_color = Color(0, 0, 0, 0.2)
# The dimensions of the area to draw the grid over.
# This should match your map's size.
var map_size = Vector2(1000, 1000)


# The _draw function is called by the engine whenever the node needs to be redrawn.
func _draw():
	# If the grid is not supposed to be visible, do nothing.
	if not is_grid_visible:
		return

	# Draw all the vertical lines.
	for x in range(0, int(map_size.x) + 1, grid_spacing):
		var start_point = Vector2(x, 0)
		var end_point = Vector2(x, map_size.y)
		draw_line(start_point, end_point, grid_color, 1)

	# Draw all the horizontal lines.
	for y in range(0, int(map_size.y) + 1, grid_spacing):
		var start_point = Vector2(0, y)
		var end_point = Vector2(map_size.x, y)
		draw_line(start_point, end_point, grid_color, 1)


# This public function is called from other scripts to turn the grid on or off.
func set_visibility(visible: bool):
	is_grid_visible = visible
	# queue_redraw() forces the _draw() function to be called on the next frame,
	# updating the visual state of the grid.
	queue_redraw()

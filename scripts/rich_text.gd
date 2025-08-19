# rich_text.gd
class_name RichTextBoldFont
extends RichTextEffect

# This string is the name of your custom BBCode tag.
var bbcode = "bfont"

# This function is called for every character inside your custom tag.
func _process_custom_fx(char_fx: CharFXTransform) -> bool:

	var speed = char_fx.env.get("freq", 2.5)
	var span = char_fx.env.get("span", 10.0)
	var wave_value = sin(char_fx.elapsed_time * speed + (char_fx.range.x / span)) * 0.5 + 0.5
	var new_color = Color.GRAY.lerp(Color.WHITE, wave_value)
	char_fx.color = new_color
	
	return true

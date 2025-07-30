// This is a Godot 4 shader for a CanvasItem (like TextureRect)
shader_type canvas_item;

// The solid color you want to apply to the texture.
// You can change this in the Inspector.
uniform vec4 solid_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Control the start and end points of the gradient (0.0 to 1.0)
// A smaller range makes the gradient sharper.
uniform float gradient_start : hint_range(0.0, 1.0) = 0.0;
uniform float gradient_end : hint_range(0.0, 1.0) = 1.0;


void fragment() {
    // Get the original color and alpha from the texture at this pixel
    vec4 original_color = texture(TEXTURE, UV);

    // Calculate the gradient factor.
    // 'UV.y' gives the vertical position (0.0 at top, 1.0 at bottom).
    // 'smoothstep' creates a smooth transition between the start and end points.
    float gradient_alpha = smoothstep(gradient_start, gradient_end, UV.x);

    // To make the gradient horizontal instead, use UV.x:
    // float gradient_alpha = smoothstep(gradient_start, gradient_end, UV.x);

    // Set the final color.
    // Use the RGB from your chosen 'solid_color'.
    COLOR.rgb = solid_color.rgb;

    // Set the final alpha.
    // This multiplies the texture's original alpha with your new gradient alpha.
    // This ensures that if your original texture already has transparent parts,
    // they remain transparent.
    COLOR.a = original_color.a * gradient_alpha;
}
// circle_with_image.gdshader
// This shader draws an image inside a solid white circular frame.
shader_type canvas_item;

void fragment() {
	// Sample the image texture provided to the TextureRect.
	vec4 image_color = texture(TEXTURE, UV);

	// Calculate the distance of the current pixel from the center.
	float distance_from_center = distance(UV, vec2(0.5));

	// Check if the pixel is inside the circle's radius.
	if (distance_from_center < 0.5) {
		// Inside the circle.
		// Start with a solid white background.
		vec3 final_rgb = vec3(1.0, 1.0, 1.0);

		// Blend the image color onto the white background.
		// The amount of blending is controlled by the image's own alpha.
		// This correctly layers the image "on top" of the white circle.
		final_rgb = mix(final_rgb, image_color.rgb, image_color.a);

		// Set the final color and make it fully opaque.
		COLOR = vec4(final_rgb, 1.0);
	} else {
		// Outside the circle, so make the pixel fully transparent.
		COLOR.a = 0.0;
	}
}

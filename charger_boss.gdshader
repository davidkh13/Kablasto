shader_type canvas_item;

uniform bool glow_enabled = true;
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float base_strength = .4;
uniform float pulse_strength = .8;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	float pulse = sin(TIME * 3.0) * 0.5 + 0.5; // Range [0.0, 1.0]
    float strength = base_strength + pulse * pulse_strength;
    
    if (glow_enabled) {
        // Blend the glow color into the original texture color
        COLOR = tex_color + glow_color * strength * tex_color.a;
    } else {
        COLOR = tex_color;
    }
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

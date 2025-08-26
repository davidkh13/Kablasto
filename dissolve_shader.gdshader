shader_type canvas_item;

uniform bool glow_enabled = true;
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float base_strength = 0.4;
uniform float pulse_strength = 0.8;

// Dissolve uniforms
uniform bool use_dissolve = false;
uniform sampler2D noise_texture;
uniform float dissolve_amount : hint_range(0.0, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float edge_width = 0.05;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Handle dissolve effect if enabled
    if (use_dissolve) {
        float noise = texture(noise_texture, UV).r;

        // Discard pixels below threshold
        if (noise < dissolve_amount) {
            discard;
        }

        // Edge glow on dissolve boundary
        if (noise < dissolve_amount + edge_width) {
            COLOR = edge_color;
        }
    }

    if (glow_enabled) {
		float pulse = sin(TIME * 3.0) * 0.5 + 0.5; // range 0 to 1
    	float strength = base_strength + pulse * pulse_strength;
        COLOR = tex_color + glow_color * strength * tex_color.a;
    } else {
        COLOR = tex_color;
    }
}
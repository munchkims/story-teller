shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D base_texture;
uniform sampler2D overlay_texture;
uniform vec2 overlay_uv_scale = vec2(1.0, 1.0);
uniform vec2 overlay_uv_offset = vec2(0.0, 0.0);
uniform float alpha_scissor_threshold = 0.1;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    vec4 base = texture(base_texture, UV);
    vec4 overlay = texture(overlay_texture, UV);

    // Rebuild transparency cutoff
    if (base.a < alpha_scissor_threshold) {
        discard;
    }

    ALBEDO = mix(base.rgb, overlay.rgb, overlay.a);
    ALPHA = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

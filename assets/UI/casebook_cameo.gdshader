shader_type canvas_item;
render_mode unshaded;

// Circular portrait clipping in local control space, independent of atlas UVs.
uniform vec2 frame_size = vec2(76.0, 76.0);
varying vec2 frame_uv;
varying vec4 item_tint;

void vertex() {
	frame_uv = VERTEX / frame_size;
	item_tint = COLOR;
}

void fragment() {
	vec4 tint = item_tint;
	float distance_from_center = length(frame_uv - vec2(0.5));
	vec4 portrait = texture(TEXTURE, UV);
	vec3 paper = vec3(0.87, 0.82, 0.71);
	vec3 result = mix(paper, portrait.rgb, portrait.a);
	float border = smoothstep(0.444, 0.452, distance_from_center);
	result = mix(result, vec3(0.33, 0.28, 0.22), border);
	float edge = 1.0 - smoothstep(0.475, 0.495, distance_from_center);
	COLOR = vec4(result * tint.rgb, edge * tint.a);
}

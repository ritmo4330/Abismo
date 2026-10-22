shader_type canvas_item;
uniform float dream_strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 original = COLOR;
	float luminance = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	vec3 dream = mix(vec3(luminance), original.rgb, 0.72) * vec3(0.82, 0.89, 1.07);
	float edge = smoothstep(0.18, 0.8, distance(UV, vec2(0.5)));
	dream = dream * (1.0 - edge * 0.17) + vec3(0.035, 0.02, 0.065);
	COLOR = vec4(mix(original.rgb, dream, dream_strength), original.a);
}

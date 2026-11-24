shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.52;
uniform vec4 vignette_color : source_color = vec4(0.015, 0.02, 0.045, 1.0);
uniform float fog_strength : hint_range(0.0, 0.5) = 0.14;
uniform vec4 fog_color : source_color = vec4(0.08, 0.16, 0.26, 1.0);
uniform float time_scale = 0.045;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered * vec2(1.15, 1.0));
	float vig = smoothstep(0.32, 0.78, dist) * vignette_strength;

	vec2 fog_uv = UV * vec2(5.5, 3.2);
	float n1 = value_noise(fog_uv + vec2(TIME * time_scale, TIME * time_scale * 0.4));
	float n2 = value_noise(fog_uv * 2.1 - vec2(TIME * time_scale * 0.7, -TIME * time_scale * 0.5));
	float mist = clamp((n1 * 0.65 + n2 * 0.35 - 0.35) * 1.6, 0.0, 1.0);
	float edge_weight = smoothstep(0.15, 0.65, dist);
	float fog_alpha = mist * fog_strength * (0.45 + 0.55 * edge_weight);

	vec3 col = mix(fog_color.rgb, vignette_color.rgb, clamp(vig / max(vig + fog_alpha, 0.001), 0.0, 1.0));
	float out_alpha = clamp(max(vig, fog_alpha), 0.0, 0.88);
	COLOR = vec4(col, out_alpha);
}

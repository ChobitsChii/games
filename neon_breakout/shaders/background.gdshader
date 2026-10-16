shader_type canvas_item;
// Animierter Neon-Hintergrund: Farbverlauf, langsam wandernde Farbwolken,
// sanft scrollendes Gitter, Sterne in zwei Ebenen (Parallax) und Vignette.
// Reine Mathematik, keine Texturen.

uniform vec4 color_top : source_color = vec4(0.075, 0.055, 0.2, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.02, 0.028, 0.085, 1.0);
uniform vec4 cloud_a : source_color = vec4(1.0, 0.17, 0.84, 1.0);
uniform vec4 cloud_b : source_color = vec4(0.0, 0.9, 1.0, 1.0);
uniform float grid_size = 90.0;
uniform float grid_alpha = 0.05;
uniform float star_density = 0.985;
uniform float vignette = 0.5;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float star_layer(vec2 uv, float cells, float speed, float seed) {
	vec2 g = uv * vec2(cells * 1.78, cells) + vec2(0.0, TIME * speed);
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id + seed);
	float twinkle = 0.55 + 0.45 * sin(TIME * 2.0 + h * 40.0);
	return step(star_density, h) * smoothstep(0.22, 0.0, length(f)) * twinkle;
}

void fragment() {
	vec2 uv = UV;
	vec2 aspect = vec2(1.78, 1.0);
	vec3 col = mix(color_top.rgb, color_bottom.rgb, uv.y);

	float t = TIME * 0.06;
	vec2 p1 = vec2(0.22 + 0.15 * sin(t * 1.3), 0.30 + 0.10 * cos(t * 0.9));
	vec2 p2 = vec2(0.80 + 0.12 * cos(t * 1.1), 0.72 + 0.12 * sin(t * 0.7));
	col += cloud_a.rgb * 0.22 * smoothstep(0.6, 0.0, distance(uv * aspect, p1 * aspect));
	col += cloud_b.rgb * 0.16 * smoothstep(0.65, 0.0, distance(uv * aspect, p2 * aspect));

	vec2 g = vec2(uv.x * 1920.0, uv.y * 1080.0 + TIME * 10.0) / grid_size;
	vec2 f = abs(fract(g) - 0.5);
	float line = max(smoothstep(0.47, 0.5, f.x), smoothstep(0.47, 0.5, f.y));
	col += cloud_b.rgb * line * grid_alpha * (0.4 + 0.6 * uv.y);

	float stars = star_layer(uv, 70.0, 1.2, 0.0) * 0.5 + star_layer(uv, 40.0, 2.8, 17.0) * 0.8;
	col += vec3(0.75, 0.85, 1.0) * stars;

	float v = length((uv - 0.5) * vec2(1.0, 0.9)) * 1.25;
	col *= 1.0 - vignette * v * v;

	COLOR = vec4(col, 1.0);
}

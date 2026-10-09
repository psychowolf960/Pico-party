shader_type canvas_item;

uniform float progress = 2.5;

void fragment() {
	vec2 g = UV * 8.0;
	float p = progress - (floor(g.x) + floor(g.y)) / 10.0;
	vec2 d = abs(fract(g) - 0.5) * 2.0;
	COLOR.a = step(p, max(d.x, d.y));
}

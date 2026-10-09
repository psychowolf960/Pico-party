shader_type canvas_item;
render_mode unshaded;


uniform sampler2D tile : filter_nearest, repeat_enable;
uniform vec3 surface_color : source_color = vec3(0.72, 0.96, 1.0);
uniform float surface_glow : hint_range(0.0, 1.0) = 0.82;
uniform float wave_px = 1.0;
uniform float wave_freq = 0.6;
uniform float wave_speed = 2.4;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 p = floor(local);
	float surface = wave_px + floor(sin(p.x * wave_freq + TIME * wave_speed) * wave_px + 0.5);
	vec4 w = texture(tile, (p + 0.5) / vec2(textureSize(tile, 0)));
	if (p.y < surface + 1.0) {
		w.rgb = mix(w.rgb, surface_color, surface_glow + 0.12 * sin(TIME * 3.1 + p.x * 0.48));
	}
	COLOR = p.y < surface ? vec4(0.0) : w;
}

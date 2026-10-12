shader_type canvas_item;

void fragment() {
	COLOR.rgb = vec3(dot(COLOR.rgb, vec3(0.3, 0.59, 0.11)));
}

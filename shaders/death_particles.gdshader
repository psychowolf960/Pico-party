shader_type particles;
render_mode disable_velocity;

uniform float speed_min = 10.0;
uniform float speed_max = 35.0;
uniform float damping = 15.0;
uniform sampler2D sprite : repeat_disable;
uniform int sprite_frame = 0;
uniform int sprite_hframes = 1;

float rand(uint n, uint i) {
	uint x = n * 7919u + i * 104729u;
	x = ((x >> 16u) ^ x) * 73244475u;
	x = ((x >> 16u) ^ x) * 73244475u;
	return float(((x >> 16u) ^ x) % 65536u) / 65535.0;
}

void start() {
	ivec2 size = textureSize(sprite, 0) / ivec2(sprite_hframes, 1);
	ivec2 pixel = ivec2(int(INDEX) % size.x, int(INDEX) / size.x);
	vec2 pos = vec2(pixel) + 0.5 - vec2(size) / 2.0;
	COLOR = texture(sprite, vec2((float(sprite_frame) + pos.x / float(size.x) + 0.5) / float(sprite_hframes), pos.y / float(size.y) + 0.5));
	ACTIVE = COLOR.a > 0.0 && pixel.y < size.y;
	float a = (rand(NUMBER + RANDOM_SEED, 0u) * 2.0 - 1.0) * PI;
	vec2 dir = (length(pos) > 0.0 ? normalize(pos) : vec2(0.0)) + vec2(sin(a), cos(a)) * 0.4;
	TRANSFORM = EMISSION_TRANSFORM;
	TRANSFORM[3].xy += (EMISSION_TRANSFORM * vec4(pos, 0.0, 0.0)).xy;
	VELOCITY = (EMISSION_TRANSFORM * vec4(dir * mix(speed_min, speed_max, rand(NUMBER + RANDOM_SEED, 1u)), 0.0, 0.0)).xyz;
	CUSTOM = vec4(0.0);
}

void process() {
	CUSTOM.y += DELTA / LIFETIME;
	if (CUSTOM.y > 1.0) {
		ACTIVE = false;
	}
	float v = max(length(VELOCITY) - damping * DELTA, 0.0);
	VELOCITY = v > 0.0 ? normalize(VELOCITY) * v : vec3(0.0);
	TRANSFORM[3].xy += VELOCITY.xy * DELTA;
	COLOR.a = 1.0 - smoothstep(0.5, 1.0, CUSTOM.y);
}

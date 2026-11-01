shader_type spatial;
render_mode cull_disabled, unshaded;

// Dragon Realms - şelale shader'ı
// Dikey kayan beyaz su dokusu + altta köpük. Şeffaf kenarlar.

uniform float flow_speed = 1.6;
uniform float intensity = 1.0;
uniform sampler2D streak_tex : filter_linear, repeat_enable;
uniform sampler2D foam_tex : filter_linear, repeat_enable;
uniform vec3 water_color : source_color = vec3(0.75, 0.85, 0.90);

void fragment() {
	vec2 uv = UV;
	float n1 = texture(streak_tex, vec2(uv.x * 3.0, uv.y * 1.5 - TIME * 0.9 * flow_speed)).r;
	float n2 = texture(streak_tex, vec2(uv.x * 7.0 + 0.37, uv.y * 2.5 - TIME * 1.4 * flow_speed)).r;
	float water = clamp(n1 * 0.6 + n2 * 0.4, 0.0, 1.0);
	// altta köpük, üstte ince akış
	float foam = texture(foam_tex, vec2(uv.x * 2.0, uv.y * 0.5 + TIME * 0.2)).r;
	float bottom_foam = (1.0 - uv.y) * smoothstep(0.6, 0.2, foam);
	vec3 col = water_color * (0.55 + water * 0.45) + vec3(1.0) * bottom_foam * 0.8;
	float a = clamp(water * 0.85 + bottom_foam, 0.0, 1.0) * intensity;
	// kenarlarda yumuşak geçiş
	a *= smoothstep(0.0, 0.12, uv.x) * smoothstep(1.0, 0.88, uv.x);
	ALBEDO = col;
	ALPHA = a;
}

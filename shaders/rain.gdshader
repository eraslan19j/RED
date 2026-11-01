shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_never, fog_disabled;

// Dragon Realms - yağmur shader'ı
// Kamerayı saran silindir üzerinde kayan çizgi (streak) dokusu.
// Yoğunluk uniform'u ile damla sayısı kontrol edilir.

uniform float intensity = 0.6;        // 0..1
uniform float fall_speed = 1.0;
uniform vec3 rain_color : source_color = vec3(0.62, 0.68, 0.75);
uniform float lightning = 0.0;
uniform sampler2D streak_tex : filter_linear, repeat_enable;

void vertex() {
	// dikey eksende kamerayı takip etmesi için world ekseni kaydırılır
	VERTEX.y += 0.0;
}

void fragment() {
	// silindir yan yüzeyi: uv.xEnvironment -> açı, uv.y -> yükseklik
	vec2 suv = vec2(UV.x * 24.0, UV.y * 3.0 - TIME * (2.2 + fall_speed));
	float s = texture(streak_tex, suv).r;
	// ince çizgiler: eşik
	float streak = smoothstep(0.72 - intensity * 0.35, 0.95, s);
	float a = streak * intensity * 0.55;
	// şimşek yağmuru aydınlatır
	vec3 col = rain_color * (0.7 + lightning * 1.6);
	ALBEDO = col;
	ALPHA = a;
}

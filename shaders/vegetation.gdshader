shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Dragon Realms - bitki shader'ı (rüzgar salınımı + çoklu örnek rengi)
// MultiMeshInstance3D üzerinde kullanılır:
//  - COLOR (vertex)        : parça rengi (gövde/ yaprak) + alfa = yükseklik maskesi
//  - INSTANCE_COLOR        : örnek başına renk varyasyonu
//  - ALBEDO alpha dokusu   : çim kartları için kesme (discard)

uniform float wind_strength = 0.35;
uniform float wind_speed = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform bool use_alpha_card = false;
uniform sampler2D albedo_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float mask = COLOR.a; // 0 = zemin, 1 = tepe
	if (mask > 0.001) {
		float ph = v_world.x * 0.35 + v_world.z * 0.27 + TIME * wind_speed * 1.6;
		float gust = sin(TIME * 0.7 + v_world.x * 0.05) * 0.5 + 0.5;
		vec2 sway = wind_direction * (sin(ph) * 0.6 + gust * 0.4) * wind_strength * mask;
		VERTEX.x += sway.x * (v_world.y * 0.12);
		VERTEX.z += sway.y * (v_world.y * 0.12);
	}
}

void fragment() {
	vec4 tex = vec4(1.0);
	if (use_alpha_card) {
		tex = texture(albedo_tex, UV);
		if (tex.a < 0.45) {
			discard;
		}
	}
	vec3 instance_tint = INSTANCE_CUSTOM.rgb; // MultiMesh use_custom_data ile gelir
	ALBEDO = COLOR.rgb * instance_tint * tint * tex.rgb;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
	SPECULAR = 0.2;
}

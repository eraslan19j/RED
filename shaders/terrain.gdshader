shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Dragon Realms - arazi shader'ı
// Yükseklik + eğim + gürültü tabanlı splat (kum/çim/kaya/kar),
// 4 katmanlı detay albedo + detay normal haritaları, ıslaklık (yağmur) desteği.

uniform sampler2D tex_sand : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_grass : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_rock : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_snow : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_noise : filter_linear_mipmap, repeat_enable;     // biyom gürültüsü
uniform sampler2D normal_detail : filter_linear_mipmap, repeat_enable;

uniform float wetness = 0.0;          // 0..1 yağmurda yüzey parlaklığı
uniform float detail_scale = 0.35;    // dünya birimi başına doku tekrarı
uniform float snow_line = 150.0;
uniform float rock_slope = 0.72;      // eğim eşiği (radyan yakl.)

varying vec3 v_world;
varying float v_height;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_height = v_world.y;
}

void fragment() {
	vec3 base_n = normalize(NORMAL);
	float slope = 1.0 - base_n.y; // 0 = düz, 1 = dik

	float h = v_height;
	float biome = texture(tex_noise, v_world.xz * 0.0016).r;

	// splat ağırlıkları
	float sand_w = smoothstep(1.5, 3.5, h) * (1.0 - smoothstep(5.0, 9.0, h));
	float snow_w = smoothstep(snow_line - 40.0, snow_line + 10.0, h + biome * 30.0);
	float rock_w = smoothstep(rock_slope - 0.12, rock_slope + 0.10, slope) + smoothstep(60.0, 110.0, h) * 0.6;
	rock_w = clamp(rock_w, 0.0, 1.0);
	float grass_w = clamp(1.0 - sand_w - snow_w - rock_w, 0.0, 1.0);
	// biyom gürültüsü ile çim/ kaya geçişlerini yumuşat
	grass_w *= 0.75 + 0.5 * biome;
	rock_w = max(rock_w, (1.0 - grass_w - sand_w - snow_w) * 0.5);

	vec2 duv = v_world.xz * detail_scale * 0.05;
	vec3 sand = texture(tex_sand, duv).rgb;
	vec3 grass = texture(tex_grass, duv).rgb;
	vec3 rock = texture(tex_rock, duv).rgb;
	vec3 snow = texture(tex_snow, duv).rgb;

	vec3 albedo = sand * sand_w + grass * grass_w + rock * rock_w + snow * snow_w;
	// ıslak zemin: koyulaşır ve parlar
	albedo *= 1.0 - wetness * 0.35;

	// detay normal (tangent uzayı)
	vec3 dn = texture(normal_detail, duv * 3.0).xyz * 2.0 - 1.0;
	NORMAL_MAP = dn;
	NORMAL_MAP_DEPTH = 1.2;

	ALBEDO = albedo;
	ROUGHNESS = mix(0.85, 0.35, wetness) * (0.4 + 0.6 * clamp(snow_w + rock_w, 0.0, 1.0)) + 0.35;
	ROUGHNESS = clamp(ROUGHNESS, 0.05, 1.0);
	METALLIC = 0.0;
	SPECULAR = mix(0.5, 0.9, wetness);
}

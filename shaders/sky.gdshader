shader_type sky;

// Dragon Realms - fırtına gökyüzü shader'ı (özel sky modu)
// Güneş, atmosferik degrade, çok katmanlı hareketli fırtına bulutları,
// gece yıldızları ve şimşek parlaması içerir.

uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.9, 0.75, 1.0);
uniform float sun_intensity = 1.0;
uniform float sun_disk_size = 600.0;

uniform vec3 zenith_color_day : source_color = vec3(0.10, 0.22, 0.45);
uniform vec3 horizon_color_day : source_color = vec3(0.55, 0.62, 0.70);
uniform vec3 zenith_color_storm : source_color = vec3(0.05, 0.07, 0.10);
uniform vec3 horizon_color_storm : source_color = vec3(0.23, 0.26, 0.30);
uniform vec3 fog_color : source_color = vec3(0.30, 0.33, 0.38);

uniform float cloud_coverage = 0.65;   // 0..1 (hava durumuna göre)
uniform float cloud_darkness = 0.55;   // 0..1 (bulut alt katmanının koyuluğu)
uniform float cloud_speed = 1.0;
uniform float lightning = 0.0;         // 0..1 anlık şimşek parlaklığı
uniform float night = 0.0;             // 0..1 gece faktörü

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = texture(noise_tex, i / 64.0).r;
	float b = texture(noise_tex, (i + vec2(1.0, 0.0)) / 64.0).r;
	float c = texture(noise_tex, (i + vec2(0.0, 1.0)) / 64.0).r;
	float d = texture(noise_tex, (i + vec2(1.0, 1.0)) / 64.0).r;
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.3, 9.1);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = dir.y;

	// Gündüz/fırtına renkleri hava durumuna göre karıştırılır
	vec3 zenith = mix(zenith_color_day, zenith_color_storm, cloud_darkness * 0.85);
	vec3 horizon = mix(horizon_color_day, horizon_color_storm, cloud_darkness * 0.85);

	float t = pow(clamp(h, 0.0, 1.0), 0.55);
	vec3 col = mix(horizon, zenith, t);

	// Ufuk altında: sis / deniz buğusu rengi
	if (h < 0.0) {
		col = mix(col, fog_color, clamp(-h * 5.0, 0.0, 1.0));
	}

	// Güneş diski + parıltı
	float s = max(dot(dir, sun_direction), 0.0);
	col += sun_color.rgb * sun_intensity * (pow(s, sun_disk_size) * 6.0 + pow(s, 16.0) * 0.22);

	// Bulutlar: iki katman, perspektif düzlem projeksiyonu
	if (h > 0.015) {
		float fade = smoothstep(0.015, 0.10, h);
		vec2 cuv1 = dir.xz / max(h, 0.06) * 0.55 + vec2(TIME * 0.006, TIME * 0.0028) * cloud_speed;
		float c1 = fbm(cuv1 * 1.4);
		vec2 cuv2 = dir.xz / max(h, 0.12) * 1.15 + vec2(-TIME * 0.010, TIME * 0.007) * cloud_speed;
		float c2 = fbm(cuv2 * 2.1 + c1 * 1.5);
		float combined = c1 * 0.62 + c2 * 0.38;
		float cov = clamp(cloud_coverage, 0.0, 0.97);
		float cl = smoothstep(1.0 - cov, 1.0 - cov + 0.28, combined);
		// Bulut rengi: üstten güneş alan, alttan koyu gölgeli
		float light_from_top = clamp(h * 3.0, 0.0, 1.0);
		vec3 cloud_lit = mix(vec3(0.85, 0.88, 0.92), vec3(1.05, 1.02, 0.98), light_from_top);
		vec3 cloud_shadow = mix(vec3(0.30, 0.33, 0.38), vec3(0.06, 0.07, 0.09), cloud_darkness);
		vec3 cloud_col = mix(cloud_shadow, cloud_lit, light_from_top * 0.75 + 0.25);
		// Şimşek bulutları aydınlatır
		cloud_col += vec3(0.9, 0.95, 1.0) * lightning * 1.6;
		col = mix(col, cloud_col, cl * fade);
	}

	// Şimşek tüm gökyüzünü aydınlatır
	col += vec3(0.75, 0.82, 1.0) * lightning * (0.35 + 0.65 * pow(max(h, 0.0), 0.5));

	// Gece: karart + yıldızlar
	if (night > 0.0) {
		vec3 night_sky = mix(vec3(0.012, 0.02, 0.045), col, 0.12);
		vec3 cell = floor(dir * 220.0);
		float star = step(0.9985, hash21(cell.xy + cell.z * 7.7));
		night_sky += vec3(0.9, 0.95, 1.0) * star * smoothstep(0.05, 0.4, h) * 0.8;
		col = mix(col, night_sky, night);
		col += sun_color.rgb * sun_intensity * pow(s, sun_disk_size) * 3.0; // ay diski
	}

	COLOR = col;
}

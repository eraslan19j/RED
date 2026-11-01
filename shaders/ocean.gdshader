shader_type spatial;
render_mode cull_disabled, specular_disabled, diffuse_burley;

// Dragon Realms - okyanus shader'ı
// Gerstner dalgaları (vertex), analitik normal, detay normal, fresnel,
// kıyı köpüğü (yükseklik haritası örnekleme), derinlik rengi ve güneş parıltısı.

uniform vec4 wave_a = vec4(1.0, 0.2, 26.0, 0.16);   // dir.xy, dalga boyu, diklik
uniform vec4 wave_b = vec4(-0.6, 0.8, 13.0, 0.22);
uniform vec4 wave_c = vec4(0.3, -0.95, 7.0, 0.28);
uniform vec4 wave_d = vec4(-0.9, -0.4, 3.4, 0.30);
uniform float wave_speed = 1.0;
uniform vec2 grid_center = vec2(0.0);              // kamera takibi (shader içinde world'a eklenir)
uniform float far_field = 0.0;                     // 1 = uzak ufuk alanı (az dalga)

uniform vec3 deep_color : source_color = vec3(0.012, 0.075, 0.115);
uniform vec3 shallow_color : source_color = vec3(0.05, 0.28, 0.30);
uniform vec3 sky_reflect_color : source_color = vec3(0.35, 0.40, 0.46);
uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform vec3 sun_color : source_color = vec3(1.0, 0.9, 0.75);
uniform float sun_intensity = 1.0;
uniform float lightning = 0.0;
uniform float wetness = 0.0;                       // yağmur sonrası parlaklık

uniform sampler2D heightmap_tex : filter_linear, repeat_disable; // dünya yükseklik haritası (RF)
uniform vec2 heightmap_uv_scale = vec2(1.0 / 6000.0);            // world -> uv
uniform vec2 heightmap_uv_offset = vec2(0.5);
uniform float heightmap_min = -60.0;
uniform float heightmap_range = 500.0;

uniform sampler2D detail_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D foam_tex : filter_linear_mipmap, repeat_enable;

varying vec3 v_world;
varying vec3 v_normal;
varying float v_crest;

vec3 gerstner(vec2 xz, vec4 w, float t, out vec3 nrm, out float crest) {
	vec2 dir = normalize(w.xy);
	float len = w.z;
	float steep = w.w;
	float k = TAU / len;
	float c = sqrt(9.8 / k) * wave_speed;
	float f = k * (dot(dir, xz) - c * t);
	float a = steep / k;
	vec3 p = vec3(0.0);
	p.x += dir.x * a * cos(f);
	p.z += dir.y * a * cos(f);
	p.y += a * sin(f);
	// normal katkısı
	vec3 dn = vec3(-dir.x * k * a * cos(f), 0.0, -dir.y * k * a * cos(f));
	float jac = 1.0 - steep * sin(f);
	nrm += dn;
	crest += jac;
	return p;
}

void vertex() {
	vec3 wp = VERTEX;
	wp.xz += grid_center;
	float t = TIME;
	vec3 n = vec3(0.0, 1.0, 0.0);
	float crest = 0.0;
	float amp = mix(1.0, 0.25, far_field); // uzak alanda dalgalar yumuşar
	vec3 p = vec3(0.0);
	vec3 tmp_n = vec3(0.0);
	vec3 r;
	r = gerstner(wp.xz, vec4(wave_a.xy, wave_a.z, wave_a.w * amp), t, tmp_n, crest); p += r; n += tmp_n;
	r = gerstner(wp.xz, vec4(wave_b.xy, wave_b.z, wave_b.w * amp), t * 1.13, tmp_n, crest); p += r; n += tmp_n;
	r = gerstner(wp.xz, vec4(wave_c.xy, wave_c.z, wave_c.w * amp), t * 0.87, tmp_n, crest); p += r; n += tmp_n;
	r = gerstner(wp.xz, vec4(wave_d.xy, wave_d.z, wave_d.w * amp), t * 1.31, tmp_n, crest); p += r; n += tmp_n;
	wp += p;
	v_world = wp;
	v_normal = normalize(n);
	v_crest = crest;
	VERTEX = wp; // düğüm kimlik dönüşümünde: model uzayı == dünya uzayı
}

void fragment() {
	vec3 n = normalize(v_normal);
	// iki kayan detay normal katmanı
	vec2 uv1 = v_world.xz * 0.045 + vec2(TIME * 0.018, TIME * 0.011);
	vec2 uv2 = v_world.xz * 0.11 - vec2(TIME * 0.026, -TIME * 0.019);
	vec3 d1 = texture(detail_noise, uv1).rgb * 2.0 - 1.0;
	vec3 d2 = texture(detail_noise, uv2).rgb * 2.0 - 1.0;
	vec3 detail = normalize(vec3(d1.xy + d2.xy, d1.z * 0.6 + d2.z * 0.6 + 2.2));
	n = normalize(vec3(n.x + detail.x * 0.35, n.y, n.z + detail.y * 0.35));
	NORMAL = n;

	// sahil derinliği: yükseklik haritasından arazi yüksekliği
	vec2 huv = v_world.xz * heightmap_uv_scale + heightmap_uv_offset;
	float th = texture(heightmap_tex, huv).r * heightmap_range + heightmap_min;
	float depth = max(0.0, -th); // su yüzeyi y=0 varsayımı
	float depth_t = clamp(depth / 14.0, 0.0, 1.0);
	vec3 water_col = mix(shallow_color, deep_color, depth_t);

	// görünüm açısı
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - v_world);
	float fres = pow(1.0 - max(dot(view_dir, n), 0.0), 5.0);
	fres = mix(0.04, 1.0, fres);

	// gökyüzü yansıması (yaklaşık atmosfer rengi + şimşek)
	vec3 refl = sky_reflect_color + vec3(0.7, 0.78, 1.0) * lightning * 0.8;
	vec3 col = mix(water_col, refl, fres * 0.85);

	// güneş speküler parıltısı
	vec3 hv = normalize(view_dir + sun_direction);
	float spec = pow(max(dot(n, hv), 0.0), 240.0) * 3.0 + pow(max(dot(n, hv), 0.0), 24.0) * 0.12;
	col += sun_color * sun_intensity * spec * (1.0 + wetness);

	// dalga tepelerinde köpük
	float crest_foam = smoothstep(2.6, 3.6, v_crest) * 0.5;
	// kıyıda köpük (foam dokusu ile)
	vec2 fuv = v_world.xz * 0.06 + vec2(TIME * 0.03, -TIME * 0.021);
	float foam_n = texture(foam_tex, fuv).r;
	float shore_foam = (1.0 - depth_t) * smoothstep(0.75, 0.35, foam_n + depth * 0.05);
	float foam = clamp(crest_foam + shore_foam, 0.0, 1.0);
	col = mix(col, vec3(0.92, 0.95, 0.96), foam * 0.75);

	ALBEDO = col;
	ROUGHNESS = mix(0.08, 0.32, foam) - wetness * 0.05;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}

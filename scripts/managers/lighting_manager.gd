class_name LightingManager
extends Node3D
## LightingManager - dünya ışığı: WorldEnvironment, güneş (yönlü ışık + gölge),
## ay ışığı, ortam ışığı, sis rengi ve gün döngüsü senkronizasyonu.
## Gölge: PSSM 4 split (cascade) mobil Vulkan üzerinde çalışır.

var world_manager: WorldManager
var world_env: WorldEnvironment
var env: Environment
var sun: DirectionalLight3D
var day_night: DayNightCycle

# Paletler
var _sun_color_day := Color(1.0, 0.95, 0.86)
var _sun_color_low := Color(1.0, 0.52, 0.26)
var _moon_color := Color(0.38, 0.48, 0.68)
var _zenith_day := Color(0.22, 0.42, 0.72)
var _horizon_day := Color(0.62, 0.70, 0.78)
var _zenith_low := Color(0.30, 0.20, 0.24)
var _horizon_low := Color(0.95, 0.55, 0.30)
var _fog_day := Color(0.62, 0.68, 0.74)
var _fog_low := Color(0.85, 0.55, 0.38)
var _fog_night := Color(0.03, 0.045, 0.08)

var sun_energy_day := 1.25
var sun_energy_low := 0.55
var moon_energy := 0.14

var weather_sun_dim := 1.0
var weather_fog_density := 0.0  # WeatherManager ekler

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	_make_environment()
	_make_sun()
	day_night = DayNightCycle.new()
	add_child(day_night)
	day_night.time_changed.connect(func(_h): apply_time())
	apply_time()

func _make_environment() -> void:
	world_env = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.65
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_strength = 0.9
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_density = 0.00035
	env.fog_light_color = _fog_day
	env.fog_light_energy = 0.6
	env.fog_sun_scatter = 0.35
	env.fog_aerial_perspective = 0.35
	env.fog_height = 2.0
	env.fog_height_density = 0.012
	env.fog_sky_affect = 0.55
	world_env.environment = env
	add_child(world_env)

func _make_sun() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Gunes"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 1600.0
	sun.directional_shadow_split_1 = 0.08
	sun.directional_shadow_split_2 = 0.22
	sun.directional_shadow_split_3 = 0.45
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_pancake_size = 24.0
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 1.6
	sun.light_energy = sun_energy_day
	sun.light_color = _sun_color_day
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	add_child(sun)

## Kalite presetine göre gölge ayarları
func apply_quality(shadows_on: bool, quality: int) -> void:
	if sun == null:
		return
	sun.shadow_enabled = shadows_on
	match quality:
		0: # LOW
			sun.directional_shadow_max_distance = 0.0
		1: # MEDIUM
			sun.directional_shadow_max_distance = 700.0
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		2: # HIGH
			sun.directional_shadow_max_distance = 1600.0
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		3: # ULTRA
			sun.directional_shadow_max_distance = 2600.0
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if env:
		env.glow_enabled = quality >= 2
		get_viewport().msaa_3d = DRSettings.get_instance().msaa

func set_weather_modulation(sun_dim: float, extra_fog: float) -> void:
	weather_sun_dim = sun_dim
	weather_fog_density = extra_fog
	apply_time()

func apply_time() -> void:
	if env == null or sun == null:
		return
	var h := day_night.hour
	var t := (h - 6.0) / 12.0  # 0..1 gündüz
	var elev := 0.0
	if t >= 0.0 and t <= 1.0:
		elev = sin(t * PI)
	var sun_dir: Vector3
	var light_color: Color
	var energy: float
	var night: float
	var zenith: Color
	var horizon: Color
	var fog_col: Color

	if elev > 0.0:
		# gündüz / şafak / gün batımı
		sun_dir = Vector3(cos(t * PI) * 0.9, maxf(elev, 0.02), 0.28).normalized()
		var low := 1.0 - smoothstep(0.0, 0.35, elev)  # ufka yakınlık
		light_color = _sun_color_day.lerp(_sun_color_low, low)
		energy = lerpf(sun_energy_low, sun_energy_day, smoothstep(0.0, 0.5, elev))
		zenith = _zenith_day.lerp(_zenith_low, low)
		horizon = _horizon_day.lerp(_horizon_low, low)
		fog_col = _fog_day.lerp(_fog_low, low)
		night = 0.0
		sun.shadow_enabled = DRSettings.get_instance().shadows_enabled and elev > 0.03
	else:
		# gece: ay
		var tn := fposmod(h + 12.0 - 6.0, 24.0) / 12.0
		var melev := sin(clampf(tn, 0.0, 1.0) * PI)
		sun_dir = Vector3(-cos(clampf(tn, 0.0, 1.0) * PI) * 0.9, max(melev, 0.05), -0.28).normalized()
		light_color = _moon_color
		energy = moon_energy
		zenith = Color(0.012, 0.02, 0.045)
		horizon = Color(0.05, 0.07, 0.11)
		fog_col = _fog_night
		night = 1.0
		sun.shadow_enabled = false

	energy *= weather_sun_dim
	sun.light_color = light_color
	sun.light_energy = energy
	sun.global_transform.basis = Basis.looking_at(-sun_dir, Vector3.UP)

	env.fog_light_color = fog_col
	env.fog_density = 0.00035 + weather_fog_density
	env.ambient_light_energy = lerpf(0.25, 1.0, 1.0 - night) * weather_sun_dim

	var sky_sys = world_manager.get_manager("SkySystem")
	if sky_sys and sky_sys.sky_mat != null:
		sky_sys.set_sun(sun_dir, light_color, energy / sun_energy_day * 1.2, night)
		sky_sys.set_horizon(horizon, zenith, fog_col)
	var ocean = world_manager.get_manager("Ocean")
	if ocean:
		ocean.set_sun(sun_dir, light_color, energy / sun_energy_day, 0.0)
		ocean.set_sky_reflect(horizon.lerp(Color.WHITE, 0.15))

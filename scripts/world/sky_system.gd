class_name SkySystem
extends Node3D
## SkySystem - özel sky shader'lı gökyüzü (Sky kaynağı). Fırtına bulutları,
## güneş/ay, gece yıldızları ve şimşek parlaması burada üretilir.
## Bulut kaplama/koyuluk hava durumu ile WeatherManager tarafından sürülür.

var world_manager: WorldManager
var sky: Sky
var sky_mat: ShaderMaterial
var noise_tex: ImageTexture

var cloud_coverage := 0.55
var cloud_darkness := 0.35
var cloud_speed := 1.0
var lightning := 0.0

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	var noise_img := TextureFactory.make_tileable_noise(256, 606, 5, 4)
	noise_tex = ImageTexture.create_from_image(noise_img)
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky_mat.set_shader_parameter("noise_tex", noise_tex)
	sky = Sky.new()
	sky.sky_material = sky_mat
	var lighting: LightingManager = p_wm.get_manager("LightingManager")
	if lighting and lighting.env:
		lighting.env.sky = sky
		lighting.env.background_mode = Environment.BG_SKY

func set_sun(dir: Vector3, color: Color, intensity: float, night: float) -> void:
	if sky_mat == null:
		return
	sky_mat.set_shader_parameter("sun_direction", dir)
	sky_mat.set_shader_parameter("sun_color", color)
	sky_mat.set_shader_parameter("sun_intensity", intensity)
	sky_mat.set_shader_parameter("night", night)

func set_horizon(horizon: Color, zenith: Color, fog: Color) -> void:
	if sky_mat == null:
		return
	sky_mat.set_shader_parameter("horizon_color_day", horizon)
	sky_mat.set_shader_parameter("zenith_color_day", zenith)
	sky_mat.set_shader_parameter("fog_color", fog)

func set_weather(coverage: float, darkness: float, speed: float) -> void:
	cloud_coverage = coverage
	cloud_darkness = darkness
	cloud_speed = speed
	if sky_mat == null:
		return
	sky_mat.set_shader_parameter("cloud_coverage", coverage)
	sky_mat.set_shader_parameter("cloud_darkness", darkness)
	sky_mat.set_shader_parameter("cloud_speed", speed)

func set_lightning(v: float) -> void:
	lightning = v
	if sky_mat == null:
		return
	sky_mat.set_shader_parameter("lightning", v)

func _process(delta: float) -> void:
	if lightning > 0.0:
		lightning = maxf(0.0, lightning - delta * 3.5)
		sky_mat.set_shader_parameter("lightning", lightning)

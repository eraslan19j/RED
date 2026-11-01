class_name WeatherManager
extends Node3D
## WeatherManager - hava durumu makinesi: Açık, Bulutlu, Yoğun Bulutlu,
## Yağmurlu, Gök Gürültülü Fırtına, Sisli, Fırtına.
## Hedef duruma yumuşak geçiş (lerp) yapar; gökyüzü, sis, güneş, yağmur ve
## rüzgarı senkronize eder. Otomatik döngü + HUD üzerinden manuel seçim destekler.

enum Weather { CLEAR, CLOUDY, HEAVY_CLOUDS, RAIN, THUNDERSTORM, FOG, STORM }
const WEATHER_NAMES := ["Açık", "Bulutlu", "Yoğun Bulutlu", "Yağmurlu", "Gök Gürültülü Fırtına", "Sisli", "Fırtına"]

signal weather_changed(w: int)

# Her hava durumu için parametreler: coverage, darkness, fog, rain, wind, sun_dim, lightning_freq, wave_scale
const PARAMS := {
	Weather.CLEAR:        {"coverage": 0.18, "darkness": 0.10, "fog": 0.00000, "rain": 0.0, "wind": 0.25, "sun_dim": 1.00, "bolt": 0.0, "wave": 0.55},
	Weather.CLOUDY:       {"coverage": 0.45, "darkness": 0.25, "fog": 0.00010, "rain": 0.0, "wind": 0.45, "sun_dim": 0.85, "bolt": 0.0, "wave": 0.75},
	Weather.HEAVY_CLOUDS: {"coverage": 0.72, "darkness": 0.50, "fog": 0.00025, "rain": 0.0, "wind": 0.70, "sun_dim": 0.62, "bolt": 0.02, "wave": 1.0},
	Weather.RAIN:         {"coverage": 0.80, "darkness": 0.62, "fog": 0.00060, "rain": 0.7, "wind": 0.90, "sun_dim": 0.45, "bolt": 0.03, "wave": 1.25},
	Weather.THUNDERSTORM: {"coverage": 0.90, "darkness": 0.78, "fog": 0.00090, "rain": 1.0, "wind": 1.40, "sun_dim": 0.30, "bolt": 0.35, "wave": 1.7},
	Weather.FOG:          {"coverage": 0.35, "darkness": 0.20, "fog": 0.00350, "rain": 0.0, "wind": 0.15, "sun_dim": 0.55, "bolt": 0.0, "wave": 0.4},
	Weather.STORM:        {"coverage": 0.95, "darkness": 0.88, "fog": 0.00120, "rain": 1.0, "wind": 2.20, "sun_dim": 0.22, "bolt": 0.8, "wave": 2.1},
}

var current: int = Weather.CLOUDY
var target: int = Weather.CLOUDY
var blend := 1.0  # geçiş ilerlemesi 0..1
var params := {}
var auto_timer := 75.0
var auto_change := true
var rain_quality := 1.0

var world_manager: WorldManager

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	current = Weather.STORM  # milestone görseli: fırtınalı okyanus
	target = Weather.STORM
	blend = 1.0
	params = PARAMS[target].duplicate()
	weather_changed.emit(current)
	_apply()

func _process(delta: float) -> void:
	if blend < 1.0:
		blend = minf(1.0, blend + delta / 6.0)
		var from: Dictionary = PARAMS[current]
		var to: Dictionary = PARAMS[target]
		params = {}
		for k in to.keys():
			params[k] = lerpf(from[k], to[k], ease(blend, 0.6))
		_apply()
	if auto_change:
		auto_timer -= delta
		if auto_timer <= 0.0:
			auto_timer = randf_range(60.0, 140.0)
			set_weather(randi_range(0, Weather.STORM))

func set_weather(w: int) -> void:
	if w == target and blend >= 1.0:
		return
	current = target if blend >= 1.0 else current
	target = clampi(w, 0, Weather.STORM)
	blend = 0.0
	weather_changed.emit(target)

func cycle() -> void:
	set_weather((target + 1) % (Weather.STORM + 1))

func get_weather_name() -> String:
	return WEATHER_NAMES[target]

func apply_quality(q: float) -> void:
	rain_quality = q
	_apply()

func _apply() -> void:
	if world_manager == null:
		return
	var sky: SkySystem = world_manager.get_manager("SkySystem")
	var lighting: LightingManager = world_manager.get_manager("LightingManager")
	var ocean: Ocean = world_manager.get_manager("Ocean")
	var veg = world_manager.get_manager("VegetationSystem")
	var rain = world_manager.get_manager("RainSystem")
	var bolt = world_manager.get_manager("LightningSystem")
	if sky:
		sky.set_weather(params["coverage"], params["darkness"], 0.6 + params["wind"])
	if lighting:
		lighting.set_weather_modulation(params["sun_dim"], params["fog"])
	if ocean:
		ocean.set_weather_waves(params["wave"], 0.7 + params["wind"] * 0.4)
		ocean.set_wetness(params["rain"])
	if veg:
		veg.set_wind(0.12 + params["wind"] * 0.35)
	if rain:
		rain.set_intensity(params["rain"] * rain_quality)
	if bolt:
		bolt.set_frequency(params["bolt"])

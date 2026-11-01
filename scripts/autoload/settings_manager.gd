extends Node
## SettingsManager (autoload) - grafik kalitesi presetleri, çözünürlük ölçeği,
## gölgeler, MSAA, bitki yoğunluğu, titreşim ve ayarların kalıcı saklanması.
## Tüm kullanıcıya dönük metinler Türkçedir.

signal settings_changed

enum Quality { LOW, MEDIUM, HIGH, ULTRA }
const QUALITY_NAMES := ["Düşük", "Orta", "Yüksek", "Ultra"]

var quality: int = Quality.HIGH
var resolution_scale := 0.85       # 0.5 .. 1.0 (dinamik çözünürlük)
var shadows_enabled := true
var msaa := 1                       # Viewport.MSAA: 0 kapalı, 1=2x, 2=4x
var vegetation_density := 1.0       # 0..1+
var rain_quality := 1.0             # yağmur yoğunluk çarpanı
var vibration := true
var adaptive_resolution := true     # FPS'e göre otomatik çözünürlük ölçekleme

var _adaptive_scale := 1.0
var _fps_accum := 0.0
var _fps_frames := 0
var _fps_timer := 0.0

func _ready() -> void:
	load_settings()
	apply()

func set_quality(q: int) -> void:
	quality = clampi(q, 0, 3)
	match quality:
		Quality.LOW:
			resolution_scale = 0.60
			shadows_enabled = false
			msaa = 0
			vegetation_density = 0.35
			rain_quality = 0.5
		Quality.MEDIUM:
			resolution_scale = 0.75
			shadows_enabled = true
			msaa = 1
			vegetation_density = 0.6
			rain_quality = 0.7
		Quality.HIGH:
			resolution_scale = 0.85
			shadows_enabled = true
			msaa = 1
			vegetation_density = 1.0
			rain_quality = 1.0
		Quality.ULTRA:
			resolution_scale = 1.0
			shadows_enabled = true
			msaa = 2
			vegetation_density = 1.0
			rain_quality = 1.0
	_adaptive_scale = resolution_scale
	apply()
	save_settings()

func apply() -> void:
	var vp := get_viewport()
	if vp:
		vp.msaa_3d = msaa
		vp.scaling_3d_scale = _adaptive_scale
	if OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	settings_changed.emit()

## Dinamik çözünürlük: WorldManager her saniye FPS ortalaması ile çağırır.
func tick_fps(delta: float) -> void:
	if not adaptive_resolution:
		return
	_fps_accum += delta
	_fps_frames += 1
	_fps_timer += delta
	if _fps_timer >= 2.0:
		var fps := float(_fps_frames) / max(_fps_accum, 0.001)
		_fps_accum = 0.0
		_fps_frames = 0
		_fps_timer = 0.0
		# Hedef 60 FPS: altında ise ölçeği düşür, üzerinde ise preset değerine yaklaş
		if fps < 50.0 and _adaptive_scale > 0.5:
			_adaptive_scale = max(0.5, _adaptive_scale - 0.05)
			get_viewport().scaling_3d_scale = _adaptive_scale
		elif fps > 58.0 and _adaptive_scale < resolution_scale:
			_adaptive_scale = min(resolution_scale, _adaptive_scale + 0.05)
			get_viewport().scaling_3d_scale = _adaptive_scale

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("grafik", "kalite", quality)
	cfg.set_value("grafik", "cozunurluk", resolution_scale)
	cfg.set_value("grafik", "golgeler", shadows_enabled)
	cfg.set_value("grafik", "msaa", msaa)
	cfg.set_value("grafik", "bitki_yogunlugu", vegetation_density)
	cfg.set_value("grafik", "yagmur", rain_quality)
	cfg.set_value("oyun", "titresim", vibration)
	cfg.set_value("grafik", "adaptif", adaptive_resolution)
	cfg.save(GameConstants.SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(GameConstants.SETTINGS_PATH) != OK:
		return
	quality = clampi(int(cfg.get_value("grafik", "kalite", Quality.HIGH)), 0, 3)
	resolution_scale = clampf(float(cfg.get_value("grafik", "cozunurluk", 0.85)), 0.5, 1.0)
	shadows_enabled = bool(cfg.get_value("grafik", "golgeler", true))
	msaa = clampi(int(cfg.get_value("grafik", "msaa", 1)), 0, 2)
	vegetation_density = clampf(float(cfg.get_value("grafik", "bitki_yogunlugu", 1.0)), 0.2, 1.5)
	rain_quality = clampf(float(cfg.get_value("grafik", "yagmur", 1.0)), 0.3, 1.0)
	vibration = bool(cfg.get_value("oyun", "titresim", true))
	adaptive_resolution = bool(cfg.get_value("grafik", "adaptif", true))
	_adaptive_scale = resolution_scale

func vibrate(ms: int = 40) -> void:
	if vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)

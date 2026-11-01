class_name WorldManager
extends Node3D
## WorldManager - dünya sahnesinin kökü. Tüm alt sistemleri (manager) kurar,
## birbirine bağlar ve tek noktadan erişim sağlar. İleride ejderha sistemleri
## (DragonController vb.) bu yöneticiye entegre edilecek.

signal world_ready

const MANAGER_NAMES := ["TerrainManager", "BiomeManager", "StreamingManager", "LightingManager", "SkySystem", "Ocean", "VegetationSystem", "WeatherManager", "EnvironmentManager", "RainSystem", "LightningSystem"]

var managers := {}

func initialize() -> void:
	# 1) Işık ve gökyüzü önce kurulur (diğer sistemler bunlara bağlanır)
	managers["LightingManager"] = preload("res://scripts/managers/lighting_manager.gd").new()
	managers["SkySystem"] = preload("res://scripts/world/sky_system.gd").new()
	managers["TerrainManager"] = preload("res://scripts/managers/terrain_manager.gd").new()
	managers["BiomeManager"] = preload("res://scripts/managers/biome_manager.gd").new()
	managers["StreamingManager"] = preload("res://scripts/managers/streaming_manager.gd").new()
	managers["Ocean"] = preload("res://scripts/world/ocean.gd").new()
	managers["VegetationSystem"] = preload("res://scripts/world/vegetation_system.gd").new()
	managers["WeatherManager"] = preload("res://scripts/managers/weather_manager.gd").new()
	managers["EnvironmentManager"] = preload("res://scripts/managers/environment_manager.gd").new()
	managers["RainSystem"] = preload("res://scripts/weather/rain_system.gd").new()
	managers["LightningSystem"] = preload("res://scripts/weather/lightning_system.gd").new()

	for name in MANAGER_NAMES:
		add_child(managers[name])

	# Başlatma sırası matters: önce arazi (yükseklik), sonra diğerleri
	managers["TerrainManager"].initialize(self)
	managers["BiomeManager"].initialize(self)
	managers["LightingManager"].initialize(self)
	managers["SkySystem"].initialize(self)
	managers["Ocean"].initialize(self)
	managers["VegetationSystem"].initialize(self)
	managers["WeatherManager"].initialize(self)
	managers["EnvironmentManager"].initialize(self)
	managers["StreamingManager"].initialize(self)

	DRSettings.get_instance().settings_changed.connect(_on_settings_changed)
	_on_settings_changed()
	world_ready.emit()

func get_manager(p_name: String) -> Node:
	return managers.get(p_name)

## Ejderha iniş / uçuş sistemleri için arazi yüksekliği sorgusu (gelecek milestone).
func get_terrain_height(x: float, z: float) -> float:
	return managers["TerrainManager"].get_height(x, z)

func get_weather() -> int:
	return managers["WeatherManager"].current

func set_weather(w: int) -> void:
	managers["WeatherManager"].set_weather(w)

func get_time_of_day() -> float:
	return managers["LightingManager"].day_night.hour

func set_time_of_day(h: float) -> void:
	managers["LightingManager"].day_night.hour = h
	managers["LightingManager"].apply_time()

func _on_settings_changed() -> void:
	var lighting: LightingManager = managers.get("LightingManager")
	var veg = managers.get("VegetationSystem")
	var weather = managers.get("WeatherManager")
	if lighting:
		lighting.apply_quality(DRSettings.get_instance().shadows_enabled, DRSettings.get_instance().quality)
	if veg:
		veg.set_density(DRSettings.get_instance().vegetation_density)
	if weather:
		weather.apply_quality(DRSettings.get_instance().rain_quality)

func _process(delta: float) -> void:
	DRSettings.get_instance().tick_fps(delta)

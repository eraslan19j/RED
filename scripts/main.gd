extends Node3D
## Main - oyun giriş noktası. Dünya (WorldManager), serbest kamera ve
## Türkçe arayüzü kurar, sinyalleri bağlar.

var world: WorldManager
var camera_ctrl: FreeCamera
var ui: UIRoot
var _hud_timer := 0.0

func _ready() -> void:
	world = WorldManager.new()
	world.name = "World"
	add_child(world)
	world.initialize()

	camera_ctrl = FreeCamera.new()
	camera_ctrl.name = "FreeCamera"
	add_child(camera_ctrl)
	camera_ctrl.initialize(world)
	# Sahil kenarındanSpawn: kita + okyanus + adalar manzarası
	var spawn := Vector3(0.0, 0.0, 1500.0)
	spawn.y = world.get_terrain_height(spawn.x, spawn.z) + 38.0
	camera_ctrl.position = spawn
	camera_ctrl.yaw = 0.0      # -Z yönüne (kuzeye) bakar
	camera_ctrl.pitch = -0.10

	ui = UIRoot.new()
	ui.name = "UIRoot"
	add_child(ui)
	ui.play_pressed.connect(_on_play)
	ui.quit_pressed.connect(func(): get_tree().quit())
	ui.menu_requested.connect(func():
		ui.show_menu()
		camera_ctrl.enabled = false)
	ui.weather_cycle_pressed.connect(func(): world.get_manager("WeatherManager").cycle())
	ui.time_plus_pressed.connect(func(): world.set_time_of_day(world.get_time_of_day() + 1.0))
	ui.time_minus_pressed.connect(func(): world.set_time_of_day(world.get_time_of_day() - 1.0))
	ui.show_menu()
	camera_ctrl.enabled = false

func _on_play() -> void:
	ui.show_game()
	camera_ctrl.enabled = true
	SettingsManager.vibrate(30)

func _process(delta: float) -> void:
	camera_ctrl.fly_input = ui.get_fly_input()
	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.25
		if ui.hud.visible and world:
			ui.update_hud(
				Engine.get_frames_per_second(),
				camera_ctrl.position,
				world.get_time_of_day(),
				world.get_manager("WeatherManager").get_weather_name(),
				world.get_manager("TerrainManager").get_chunk_count(),
				camera_ctrl.joystick)

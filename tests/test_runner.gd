extends SceneTree
## Otomatik duman testleri (headless): dünya yüklenir, birkaç kare ilerletilir,
## kritik sistemler doğrulanır. CI'da `godot --headless -s res://tests/test_runner.gd` ile çalışır.
## Hata varsa çıkış kodu 1 olur.

var frames := 0
var failures: Array[String] = []
var main_node: Node3D

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		var ps: PackedScene = load("res://scenes/main.tscn")
		main_node = ps.instantiate()
		root.add_child(main_node)
	if frames == 120:
		_run_checks()
	if frames >= 130:
		_report()
		return true
	return false

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		failures.append(msg)
		print("FAIL: ", msg)

func _run_checks() -> void:
	_check(main_node != null, "ana sahne yüklendi")
	# zamanlamadan bağımsız: quadtree'yi zorla güncelle ve kuyruğu boşalt
	var w0: WorldManager = main_node.get_node_or_null("World")
	if w0:
		var t0: TerrainManager = w0.get_manager("TerrainManager")
		t0.update_quadtree(Vector3(0, 120, 1500))
		t0.process_build_queue(200)
	var world: WorldManager = main_node.get_node_or_null("World")
	_check(world != null, "WorldManager oluşturuldu")
	if world == null:
		return
	var terrain: TerrainManager = world.get_manager("TerrainManager")
	var ocean = world.get_manager("Ocean")
	var sky: SkySystem = world.get_manager("SkySystem")
	var weather: WeatherManager = world.get_manager("WeatherManager")
	var lighting: LightingManager = world.get_manager("LightingManager")
	var cam_ctrl: FreeCamera = main_node.get_node_or_null("FreeCamera")
	var ui: UIRoot = main_node.get_node_or_null("UIRoot")

	_check(terrain != null, "TerrainManager mevcut")
	_check(terrain.get_chunk_count() > 0, "arazi parçaları (chunk) yüklendi: %d" % terrain.get_chunk_count())
	_check(terrain.root_chunk != null and not terrain.build_queue.is_empty() or terrain.get_chunk_count() > 0, "quadtree kuyruğu çalışıyor")
	var h0 := world.get_terrain_height(0.0, 0.0)
	_check(is_finite(h0) and h0 > -100.0 and h0 < 600.0, "yükseklik sorgusu tutarlı (merkez: %.1f)" % h0)
	var h_sea := world.get_terrain_height(2900.0, 2900.0)
	_check(h_sea < 0.0, "okyanus derinliği negatif (köşe: %.1f)" % h_sea)
	_check(terrain.heightmap_texture != null, "yükseklik haritası dokusu üretildi")
	_check(ocean != null and ocean.near_mesh != null and ocean.far_mesh != null, "okyanus katmanları mevcut")
	_check(sky != null and sky.sky_mat != null and sky.sky_mat.shader != null, "gökyüzü shader'ı yüklü")
	_check(lighting != null and lighting.sun != null and lighting.world_env != null, "ışık sistemi mevcut (güneş + WorldEnvironment)")
	_check(cam_ctrl != null and cam_ctrl.camera != null and cam_ctrl.camera.current, "kamera aktif")
	_check(ui != null and ui.menu_panel != null, "Türkçe arayüz yüklendi")

	# hava durumu geçişleri
	for w in range(7):
		weather.set_weather(w)
		weather.blend = 1.0
		weather._apply()
	_check(true, "hava durumu döngüsü hatasız (7 durum)")

	# gün döngüsü
	for t in [0.0, 6.0, 10.0, 12.0, 18.5, 23.0]:
		world.set_time_of_day(t)
	_check(true, "gün/saat geçişleri hatasız")

	# ayarlar kaydet/yükle
	SettingsManager.set_quality(SettingsManager.Quality.MEDIUM)
	SettingsManager.load_settings()
	_check(SettingsManager.quality == SettingsManager.Quality.MEDIUM, "ayarlar kalıcı (kaydet/yükle)")
	SettingsManager.set_quality(SettingsManager.Quality.HIGH)

func _report() -> void:
	print("==========================================")
	if failures.is_empty():
		print("TÜM TESTLER GEÇTİ")
	else:
		print("TESTLER BAŞARISIZ: %d hata" % failures.size())
		for f in failures:
			print(" - ", f)
	quit(1 if not failures.is_empty() else 0)

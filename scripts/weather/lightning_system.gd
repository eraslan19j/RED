class_name LightningSystem
extends Node3D
## LightningSystem - gök gürültülü fırtınada şimşek: jagged civalı çizgisi +
## gökyüzü/okyanus/yağmur aydınlatma flaşı. Ses geri bildirimi sonraki
## milestone'da eklenecek (ses assetleri M2).

var frequency := 0.0  # saniyede ortalama şimşek sayısı (0 = yok)
var _timer := 3.0
var world_manager: WorldManager
var bolts: Array[MeshInstance3D] = []
var bolt_life := 0.12
var flash := 0.0

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm

func set_frequency(f: float) -> void:
	frequency = f

func _process(delta: float) -> void:
	# flash sönümlenir ve tüm sistemlere yansıtılır
	flash = maxf(0.0, flash - delta * 2.8)
	var sky: SkySystem = world_manager.get_manager("SkySystem")
	var ocean: Ocean = world_manager.get_manager("Ocean")
	var rain: RainSystem = world_manager.get_manager("RainSystem")
	if sky:
		sky.set_lightning(flash)
	if ocean:
		ocean.set_lightning(flash)
	if rain:
		rain.set_lightning_flash(flash)
	# şimşek üretimi
	if frequency > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			_timer = randf_range(1.0, 4.0) / maxf(frequency, 0.05)
			_strike()
	# eski cıvatları temizle
	for i in range(bolts.size() - 1, -1, -1):
		var b: MeshInstance3D = bolts[i]
		if not is_instance_valid(b):
			bolts.remove_at(i)
			continue
		b.set_meta("life", b.get_meta("life") - delta)
		if b.get_meta("life") <= 0.0:
			bolts.remove_at(i)
			b.queue_free()

func _strike() -> void:
	flash = randf_range(0.7, 1.0)
	DRSettings.get_instance().vibrate(60)
	var cam := get_viewport().get_camera_3d()
	var base: Vector3 = cam.global_position if cam else Vector3.ZERO
	# gökyüzünde rastgele bir noktadan yere
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(700.0, 2200.0)
	var from := base + Vector3(cos(angle) * dist, randf_range(280.0, 520.0), sin(angle) * dist)
	var terrain: TerrainManager = world_manager.get_manager("TerrainManager")
	var to := Vector3(from.x, terrain.get_height(from.x, from.z) + 1.0, from.z)
	var pts := ProceduralMeshUtil.make_lightning_points(from, to, 16, randi())
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(pts.size() - 1):
		im.surface_add_vertex(pts[i])
		im.surface_add_vertex(pts[i + 1])
	im.surface_end()
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.75, 0.82, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.7, 1.0)
	mat.emission_energy_multiplier = 4.0
	mi.mesh = im
	mi.material_override = mat
	mi.set_meta("life", bolt_life)
	add_child(mi)
	bolts.append(mi)

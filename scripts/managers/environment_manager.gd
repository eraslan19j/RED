class_name EnvironmentManager
extends Node3D
## EnvironmentManager - çevresel yapılar ve su ögeleri:
## nehir şeritleri, göller, şelaleler, antik kalıntılar, uzak kale ve mağaralar.
## Tüm konumlar arazi yüksekliğinden (TerrainManager.get_height) hesaplanır.

var world_manager: WorldManager
var terrain: TerrainManager
var water_mat: ShaderMaterial  # nehir/göl için sakin su materyali
var structure_mat: StandardMaterial3D
var window_mat: StandardMaterial3D
var root: Node3D

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	terrain = p_wm.get_manager("TerrainManager")
	root = Node3D.new()
	root.name = "CevreYapilari"
	add_child(root)
	_make_materials()
	_build_rivers()
	_build_lakes()
	_build_waterfalls()
	_build_ruins()
	_build_castles()
	_build_caves()

func _make_materials() -> void:
	# sakin su (nehir/göl) - okyanus shader'ının sakin bir kopyası
	water_mat = ShaderMaterial.new()
	water_mat.shader = load("res://shaders/ocean.gdshader")
	var noise_img := TextureFactory.make_tileable_noise(256, 707, 5, 3)
	water_mat.set_shader_parameter("detail_noise", ImageTexture.create_from_image(noise_img))
	water_mat.set_shader_parameter("foam_tex", TextureFactory.make_foam_texture(256, 808))
	water_mat.set_shader_parameter("far_field", 1.0)
	water_mat.set_shader_parameter("wave_speed", 0.25)
	water_mat.set_shader_parameter("heightmap_uv_scale", Vector2(1.0 / GameConstants.WORLD_SIZE, 1.0 / GameConstants.WORLD_SIZE))
	water_mat.set_shader_parameter("heightmap_min", -60.0)
	water_mat.set_shader_parameter("heightmap_range", 500.0)
	var terrain_hm: ImageTexture = terrain.heightmap_texture
	if terrain_hm:
		water_mat.set_shader_parameter("heightmap_tex", terrain_hm)

	structure_mat = StandardMaterial3D.new()
	structure_mat.albedo_texture = TextureFactory.make_detail_albedo(256, 303, Color(0.45, 0.44, 0.42), Color(0.28, 0.27, 0.26), 0.5)
	structure_mat.roughness = 0.95

	window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color(0.1, 0.08, 0.05)
	window_mat.emission_enabled = true
	window_mat.emission = Color(1.0, 0.72, 0.32)
	window_mat.emission_energy_multiplier = 2.2

func _find_spot(target: Vector2, radius: float, min_h: float, max_h: float, max_slope: float) -> Vector3:
	var best := Vector3(target.x, 0, target.y)
	var best_score := 1e9
	for i in range(400):
		var a := randf_range(0, TAU)
		var r := sqrt(randf()) * radius
		var p := target + Vector2(cos(a), sin(a)) * r
		var h := terrain.get_height(p.x, p.y)
		if h < min_h or h > max_h:
			continue
		var s := terrain.get_slope(p.x, p.y)
		if s > max_slope:
			continue
		var score := s * 100.0 + absf(h - (min_h + max_h) * 0.5) * 0.1
		if score < best_score:
			best_score = score
			best = Vector3(p.x, h, p.y)
	return best

func _build_rivers() -> void:
	for river in terrain.rivers:
		var verts := PackedVector3Array()
		var uvs := PackedVector2Array()
		var idx := PackedInt32Array()
		var width := 7.0
		var dist := 0.0
		var prev := Vector2.ZERO
		for i in range(river.size()):
			var p: Vector2 = river[i]
			var dir := Vector2(1, 0)
			if i < river.size() - 1:
				dir = (river[i + 1] - p).normalized()
			elif i > 0:
				dir = (p - river[i - 1]).normalized()
			var perp := Vector2(-dir.y, dir.x) * width
			if i > 0:
				dist += p.distance_to(prev)
			prev = p
			var y := terrain.get_height(p.x, p.y) + 0.9
			verts.append(Vector3(p.x - perp.x, y, p.y - perp.y))
			verts.append(Vector3(p.x + perp.x, y, p.y + perp.y))
			uvs.append(Vector2(0, dist * 0.25))
			uvs.append(Vector2(1, dist * 0.25))
			if i > 0:
				var b := (i - 1) * 2
				idx.append_array([b, b + 1, b + 2, b + 1, b + 3, b + 2])
		if verts.size() < 4:
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = idx
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.name = "Nehir"
		mi.mesh = mesh
		mi.material_override = water_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)

func _build_lakes() -> void:
	for lake in terrain.lakes:
		var c: Vector2 = lake["center"]
		var bed := terrain.get_height(c.x, c.y)
		var rim := 0.0
		for i in range(12):
			var a := TAU * float(i) / 12.0
			rim += terrain.get_height(c.x + cos(a) * lake["radius"] * 1.15, c.y + sin(a) * lake["radius"] * 1.15)
		rim /= 12.0
		var surface := lerpf(bed, rim, 0.75) + 0.4
		var disc := CylinderMesh.new()
		disc.top_radius = lake["radius"] * 0.92
		disc.bottom_radius = lake["radius"] * 0.92
		disc.height = 0.3
		disc.radial_segments = 24
		var mi := MeshInstance3D.new()
		mi.name = "Gol"
		mi.mesh = disc
		mi.material_override = water_mat
		mi.position = Vector3(c.x, surface, c.y)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)

func _build_waterfalls() -> void:
	var wf_mat := ShaderMaterial.new()
	wf_mat.shader = load("res://shaders/waterfall.gdshader")
	wf_mat.set_shader_parameter("streak_tex", TextureFactory.make_streak_texture(128, 1111))
	wf_mat.set_shader_parameter("foam_tex", TextureFactory.make_foam_texture(128, 1212))
	for spot in terrain.waterfall_spots:
		var pos: Vector3 = spot["pos"]
		var flow: Vector2 = spot["flow"]
		var base_y := terrain.get_height(pos.x, pos.z)
		var height := maxf(pos.y - base_y, 3.0)
		var quad := ProceduralMeshUtil.make_waterfall_quad(6.5, height)
		var mi := MeshInstance3D.new()
		mi.name = "Selale"
		mi.mesh = quad
		mi.material_override = wf_mat
		# şelale kuyudan denize doğru bakar
		var yaw := atan2(flow.x, flow.y)
		mi.transform = Transform3D(Basis.from_euler(Vector3(0, yaw + PI, 0)), Vector3(pos.x, base_y - 0.2, pos.z))
		root.add_child(mi)
		# şelale havuzu
		var pool := CylinderMesh.new()
		pool.top_radius = 7.0
		pool.bottom_radius = 8.0
		pool.height = 0.25
		pool.radial_segments = 16
		var pool_mi := MeshInstance3D.new()
		pool_mi.name = "SelaleHavuzu"
		pool_mi.mesh = pool
		pool_mi.material_override = water_mat
		pool_mi.position = Vector3(pos.x + flow.x * 3.0, maxf(base_y, -0.4) + 0.15, pos.z + flow.y * 3.0)
		pool_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(pool_mi)

func _build_ruins() -> void:
	# Antik kalıntılar: kırık sütunlar halkası + lento + bloklar
	var center := _find_spot(Vector2(260, -360), 250.0, 8.0, 70.0, 0.35)
	var ruins := Node3D.new()
	ruins.name = "antikKalintilar"
	ruins.position = center
	root.add_child(ruins)
	var columns := 8
	for i in range(columns):
		var a := TAU * float(i) / float(columns)
		var r := 7.0
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		var broken := 0.45 + 0.55 * ((i * 37 % 10) / 10.0)
		var col_mesh := ProceduralMeshUtil.make_column(4.5, 0.5, broken)
		var mi := MeshInstance3D.new()
		mi.mesh = col_mesh
		mi.material_override = structure_mat
		mi.position = p
		mi.rotation.y = randf_range(0, TAU)
		ruins.add_child(mi)
	# lento (üst kiriş)
	var lintel := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(16.0, 0.8, 1.2)
	lintel.mesh = lb
	lintel.material_override = structure_mat
	lintel.position = Vector3(0, 4.2, 0)
	lintel.rotation.y = 0.5
	ruins.add_child(lintel)
	# dağınık bloklar
	for i in range(6):
		var bm := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(randf_range(1.0, 2.5), randf_range(0.6, 1.2), randf_range(1.0, 2.0))
		bm.mesh = box
		bm.material_override = structure_mat
		bm.position = Vector3(randf_range(-9, 9), 0.4, randf_range(-9, 9))
		bm.rotation.y = randf_range(0, TAU)
		ruins.add_child(bm)

func _build_castles() -> void:
	# Ana kale (dağda) + uzak adada küçük kale
	_build_castle(_find_spot(Vector2(-700, 500), 350.0, 60.0, 260.0, 0.4), 1.0, "Kale")
	_build_castle(_find_spot(Vector2(2100, -1500), 200.0, 40.0, 190.0, 0.6), 0.6, "UzakKale")

func _build_castle(center: Vector3, scale_f: float, label: String) -> void:
	var castle := Node3D.new()
	castle.name = label
	castle.position = center
	castle.scale = Vector3(scale_f, scale_f, scale_f)
	root.add_child(castle)
	# platform
	var platform := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(34, 4, 34)
	platform.mesh = pb
	platform.material_override = structure_mat
	platform.position = Vector3(0, 1.5, 0)
	castle.add_child(platform)
	# 4 köşe kulesi
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tower := MeshInstance3D.new()
			tower.mesh = ProceduralMeshUtil.make_tower(15.0, 3.2)
			tower.material_override = structure_mat
			tower.position = Vector3(sx * 13.0, 3.0, sz * 13.0)
			castle.add_child(tower)
	# duvarlar
	for i in range(4):
		var wall := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(26.0, 6.0, 1.6)
		wall.mesh = wb
		wall.material_override = structure_mat
		var a := i * PI * 0.5
		wall.position = Vector3(cos(a) * 13.0, 5.5, sin(a) * 13.0)
		wall.rotation.y = -a + PI * 0.5
		castle.add_child(wall)
	# ana bina (keep)
	var keep := MeshInstance3D.new()
	var kb := BoxMesh.new()
	kb.size = Vector3(12, 14, 12)
	keep.mesh = kb
	keep.material_override = structure_mat
	keep.position = Vector3(0, 9.0, 0)
	castle.add_child(keep)
	# çatı
	var roof := MeshInstance3D.new()
	roof.mesh = ProceduralMeshUtil._cyl(0.0, 8.5, 5.0, 4)
	roof.material_override = structure_mat
	roof.position = Vector3(0, 18.5, 0)
	roof.rotation.y = PI * 0.25
	castle.add_child(roof)
	# pencereler (gece yanar)
	for i in range(6):
		var win := MeshInstance3D.new()
		var wb2 := BoxMesh.new()
		wb2.size = Vector3(0.7, 1.1, 0.2)
		win.mesh = wb2
		win.material_override = window_mat
		var a := TAU * float(i) / 6.0
		win.position = Vector3(cos(a) * 6.1, 10.0, sin(a) * 6.1)
		win.rotation.y = a + PI  # dışa dönük
		castle.add_child(win)

func _build_caves() -> void:
	# sahile yakın kayalıklarda mağara ağızları (koyu oyuk + kaya çerçevesi)
	var spots := [Vector2(-150, -1750), Vector2(80, -1900), Vector2(-2050, 1400)]
	var cave_mat := StandardMaterial3D.new()
	cave_mat.albedo_color = Color(0.02, 0.02, 0.03)
	cave_mat.roughness = 1.0
	for target in spots:
		var p := _find_spot(target, 200.0, 1.5, 14.0, 2.0)
		if p.y < 2.0:
			continue
		var mouth := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 3.2
		s.height = 6.4
		s.radial_segments = 10
		s.rings = 6
		mouth.mesh = s
		mouth.material_override = cave_mat
		mouth.scale = Vector3(1.0, 0.75, 0.45)
		mouth.position = Vector3(p.x, p.y + 1.2, p.z)
		root.add_child(mouth)
		for i in range(4):
			var rock := MeshInstance3D.new()
			rock.mesh = ProceduralMeshUtil.make_rock(1.4, 2000 + i)
			rock.material_override = structure_mat
			var a := TAU * float(i) / 4.0 + 0.4
			rock.position = Vector3(p.x + cos(a) * 3.4, p.y + 0.5 + (i % 2), p.z + sin(a) * 3.4)
			root.add_child(rock)

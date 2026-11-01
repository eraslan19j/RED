class_name VegetationSystem
extends Node3D
## VegetationSystem - prosedürel bitki dağılımı. Her arazi parçasına (chunk)
## MultiMeshInstance3D ile çam/geniş yapraklı ağaç, kaya, çalı ve çim ekler.
## Rüzgar, vertex shader'da yükseklik maskesi (COLOR.a) ile uygulanır.

var world_manager: WorldManager
var terrain: TerrainManager
var biome: BiomeManager

var density_multiplier := 1.0
var wind_strength := 0.4

var tree_mat: ShaderMaterial
var grass_mat: ShaderMaterial
var pine_mesh: ArrayMesh
var broadleaf_mesh: ArrayMesh
var scatter_mesh: ArrayMesh
var grass_mesh: ArrayMesh
var grass_tex: Texture

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	terrain = p_wm.get_manager("TerrainManager")
	biome = p_wm.get_manager("BiomeManager")
	terrain.chunk_built.connect(_on_chunk_built)
	_make_assets()

func _make_assets() -> void:
	tree_mat = ShaderMaterial.new()
	tree_mat.shader = load("res://shaders/vegetation.gdshader")
	tree_mat.set_shader_parameter("use_alpha_card", false)

	grass_tex = TextureFactory.make_grass_card(128, 1010)
	grass_mat = ShaderMaterial.new()
	grass_mat.shader = load("res://shaders/vegetation.gdshader")
	grass_mat.set_shader_parameter("use_alpha_card", true)
	grass_mat.set_shader_parameter("albedo_tex", grass_tex)

	pine_mesh = ProceduralMeshUtil.make_pine_tree(9.0)
	broadleaf_mesh = ProceduralMeshUtil.make_broadleaf_tree(7.5)
	# kaya + çalı tek "scatter" mesh'inde (ölçek ile ayrıştırılır)
	scatter_mesh = ArrayMesh.new()
	ProceduralMeshUtil.append_primitive(scatter_mesh, ProceduralMeshUtil.make_rock(1.0, 5), Transform3D(Basis(), Vector3(0, 0.4, 0)), Color(0.42, 0.41, 0.40, 0.0))
	ProceduralMeshUtil.append_primitive(scatter_mesh, ProceduralMeshUtil.make_bush(1.0), Transform3D(Basis(), Vector3(2.2, 0.5, 0)), Color(0.14, 0.30, 0.12, 0.0))
	grass_mesh = ProceduralMeshUtil.make_grass_card(1.4)

func set_density(d: float) -> void:
	density_multiplier = d

func set_wind(w: float) -> void:
	wind_strength = w
	for m in [tree_mat, grass_mat]:
		m.set_shader_parameter("wind_strength", w)
		m.set_shader_parameter("wind_speed", 0.8 + w * 0.8)

func _on_chunk_built(chunk: TerrainChunk) -> void:
	populate_chunk(chunk)

func populate_chunk(chunk: TerrainChunk) -> void:
	var d := chunk.built_distance
	var lod := 1.0
	if d < 700.0:
		lod = 1.0
	elif d < 1500.0:
		lod = 0.45
	else:
		lod = 0.18
	var step := 13.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(chunk.center.x * 7.13) ^ int(chunk.center.y * 3.71) ^ 12345

	var tree_transforms: Array[Transform3D] = []
	var tree_tints: Array[Color] = []
	var tree_is_pine: Array[bool] = []
	var scatter_transforms: Array[Transform3D] = []
	var scatter_tints: Array[Color] = []
	var grass_transforms: Array[Transform3D] = []
	var grass_tints: Array[Color] = []

	var half := chunk.size * 0.5
	var x0 := chunk.center.x - half
	var z0 := chunk.center.y - half
	var count := int((chunk.size / step) * (chunk.size / step))
	for i in range(count):
		var wx := x0 + rng.randf() * chunk.size
		var wz := z0 + rng.randf() * chunk.size
		var h := terrain.get_height(wx, wz)
		if h < 3.2:
			continue
		var slope := terrain.get_slope(wx, wz)
		var b := biome.get_biome(wx, wz, h, slope)
		var moist := biome.get_moisture(wx, wz)
		var is_tree: bool = b["type"] == BiomeManager.Biome.FOREST and slope < 0.62 and moist > 0.38
		if is_tree and rng.randf() < 0.55 * lod * density_multiplier:
			var s := rng.randf_range(0.75, 1.5)
			var rot := Basis.from_euler(Vector3(0, rng.randf_range(0, TAU), 0))
			tree_transforms.append(Transform3D(rot, Vector3(wx, h - 0.2, wz)) * Transform3D(Basis.from_scale(Vector3(s, s, s)), Vector3.ZERO))
			var green := rng.randf_range(0.75, 1.15)
			tree_tints.append(Color(green, green * rng.randf_range(0.95, 1.1), green * 0.8, 1.0))
			tree_is_pine.append(h > 70.0 or rng.randf() < 0.55)
		elif slope < 0.5 and h < 130.0 and rng.randf() < 0.10 * lod * density_multiplier:
			# kaya veya çalı
			var s := rng.randf_range(0.5, 2.2)
			var rot := Basis.from_euler(Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0, TAU), rng.randf_range(-0.2, 0.2)))
			scatter_transforms.append(Transform3D(rot * Basis.from_scale(Vector3(s, s * 0.8, s)), Vector3(wx, h - 0.1, wz)))
			var g := rng.randf_range(0.8, 1.1)
			scatter_tints.append(Color(g, g, g, 1.0))
		# çim: sadece yakında ve düz zeminde
		if d < 650.0 and slope < 0.42 and h > 3.2 and h < 110.0 and b["type"] != BiomeManager.Biome.ROCK:
			if rng.randf() < 0.5 * density_multiplier:
				var gs := rng.randf_range(0.7, 1.3)
				var grot := Basis.from_euler(Vector3(0, rng.randf_range(0, TAU), 0))
				grass_transforms.append(Transform3D(grot * Basis.from_scale(Vector3(gs, gs, gs)), Vector3(wx, h, wz)))
				grass_tints.append(Color(rng.randf_range(0.8, 1.15), rng.randf_range(0.9, 1.1), 0.75, 1.0))

	_spawn_multimesh(chunk, tree_mat, pine_mesh, _filter(tree_transforms, tree_tints, tree_is_pine, true), _filter_tints(tree_tints, tree_is_pine, true))
	_spawn_multimesh(chunk, tree_mat, broadleaf_mesh, _filter(tree_transforms, tree_tints, tree_is_pine, false), _filter_tints(tree_tints, tree_is_pine, false))
	_spawn_multimesh(chunk, tree_mat, scatter_mesh, scatter_transforms, scatter_tints)
	_spawn_multimesh(chunk, grass_mat, grass_mesh, grass_transforms, grass_tints)

func _filter(trs: Array[Transform3D], _tints: Array[Color], is_pine: Array[bool], want_pine: bool) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for i in range(trs.size()):
		if is_pine[i] == want_pine:
			out.append(trs[i])
	return out

func _filter_tints(tints: Array[Color], is_pine: Array[bool], want_pine: bool) -> Array[Color]:
	var out: Array[Color] = []
	for i in range(tints.size()):
		if is_pine[i] == want_pine:
			out.append(tints[i])
	return out

func _spawn_multimesh(chunk: TerrainChunk, mat: Material, mesh: Mesh, transforms: Array, tints: Array) -> void:
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_custom_data(i, tints[i] if i < tints.size() else Color.WHITE)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if chunk.built_distance < 700.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var half := chunk.size * 0.5
	mi.custom_aabb = AABB(Vector3(chunk.center.x - half, -50, chunk.center.y - half), Vector3(chunk.size, 120, chunk.size))
	chunk.add_child(mi)

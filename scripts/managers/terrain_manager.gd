class_name TerrainManager
extends Node3D
## TerrainManager - prosedürel ada/dağ/nehir/göl arazi üretimi + quadtree LOD
## ile parça (chunk) yönetimi. get_height(x,z) tüm sistemlerin (okyanus, bitki,
## ejderha inişi vb.) tek doğru kaynağıdır.

signal chunk_built(chunk: TerrainChunk)
signal chunk_freed(chunk: TerrainChunk)
signal heightmap_ready

var world_manager: WorldManager
var noise_hills: FastNoiseLite
var noise_ridge: FastNoiseLite
var noise_detail: FastNoiseLite

var islands: Array = []
var rivers: Array = []      # Array[PackedVector2Array]
var lakes: Array = []
var waterfall_spots: Array = []

var river_grid := PackedFloat32Array()
var river_grid_res := 256
var river_grid_world := GameConstants.WORLD_SIZE

var root_chunk: TerrainChunk
var all_chunks: Array[TerrainChunk] = []
var build_queue: Array[TerrainChunk] = []
var free_queue: Array[TerrainChunk] = []
var heightmap_texture: ImageTexture
var terrain_material: Material

var _update_timer := 0.0

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	_setup_noises()
	_setup_layout()
	_build_river_grid()
	_compute_waterfall_spots()
	_make_terrain_material()
	_make_heightmap_texture()
	root_chunk = TerrainChunk.new()
	root_chunk.setup(Vector2.ZERO, GameConstants.WORLD_SIZE, 0, self)
	add_chunk_node(root_chunk)

func add_chunk_node(c: TerrainChunk) -> void:
	add_child(c)
	all_chunks.append(c)

func queue_free_chunk(c: TerrainChunk) -> void:
	if not free_queue.has(c):
		free_queue.append(c)

func request_build(c: TerrainChunk) -> void:
	if not c.mesh_built and not build_queue.has(c):
		build_queue.append(c)

func _setup_noises() -> void:
	noise_hills = FastNoiseLite.new()
	noise_hills.seed = 1337
	noise_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_hills.frequency = 0.0016
	noise_hills.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_hills.fractal_octaves = 5
	noise_hills.fractal_gain = 0.5
	noise_hills.fractal_lacunarity = 2.0

	noise_ridge = FastNoiseLite.new()
	noise_ridge.seed = 4242
	noise_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_ridge.frequency = 0.0028
	noise_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise_ridge.fractal_octaves = 4

	noise_detail = FastNoiseLite.new()
	noise_detail.seed = 777
	noise_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_detail.frequency = 0.02

func _setup_layout() -> void:
	# Ana kita + adalar: {center, radius, peak}
	islands = [
		{"center": Vector2(0, 0), "radius": 2600.0, "peak": 420.0},
		{"center": Vector2(2100, -1500), "radius": 800.0, "peak": 190.0},
		{"center": Vector2(-2200, 1600), "radius": 700.0, "peak": 160.0},
		{"center": Vector2(1200, 2200), "radius": 560.0, "peak": 130.0},
		{"center": Vector2(-1400, -2100), "radius": 620.0, "peak": 150.0},
		{"center": Vector2(2650, 900), "radius": 240.0, "peak": 35.0},
		{"center": Vector2(-2750, -600), "radius": 200.0, "peak": 28.0},
		{"center": Vector2(600, -2650), "radius": 220.0, "peak": 30.0},
	]
	# Nehirler (ana kitadan denize dökülen 3 yol)
	rivers = [
		PackedVector2Array([Vector2(-500, 300), Vector2(-350, 100), Vector2(-250, -150), Vector2(-180, -500), Vector2(-120, -900), Vector2(-60, -1300), Vector2(0, -1750), Vector2(60, -2100)]),
		PackedVector2Array([Vector2(600, 700), Vector2(500, 400), Vector2(420, 100), Vector2(380, -300), Vector2(400, -700), Vector2(460, -1100), Vector2(560, -1500)]),
		PackedVector2Array([Vector2(-900, -600), Vector2(-700, -900), Vector2(-500, -1200), Vector2(-250, -1500), Vector2(0, -1750)]),
	]
	# Göller
	lakes = [
		{"center": Vector2(700, 900), "radius": 130.0, "depth": 9.0},
		{"center": Vector2(-1100, 200), "radius": 100.0, "depth": 8.0},
	]

func _build_river_grid() -> void:
	# Nehirlere olan mesafeyi kaba bir gridde önceden hesapla (hızlı sorgu için)
	var res := river_grid_res
	river_grid.resize(res * res)
	river_grid.fill(1e9)
	var cell := river_grid_world / float(res)
	for river in rivers:
		for i in range(river.size() - 1):
			var a: Vector2 = river[i]
			var b: Vector2 = river[i + 1]
			var seg_len := a.distance_to(b)
			var margin := 40.0
			var minx := minf(a.x, b.x) - margin
			var maxx := maxf(a.x, b.x) + margin
			var minz := minf(a.y, b.y) - margin
			var maxz := maxf(a.y, b.y) + margin
			var cx0 := clampi(int((minx + GameConstants.WORLD_HALF) / cell), 0, res - 1)
			var cx1 := clampi(int((maxx + GameConstants.WORLD_HALF) / cell), 0, res - 1)
			var cz0 := clampi(int((minz + GameConstants.WORLD_HALF) / cell), 0, res - 1)
			var cz1 := clampi(int((maxz + GameConstants.WORLD_HALF) / cell), 0, res - 1)
			for cz in range(cz0, cz1 + 1):
				for cx in range(cx0, cx1 + 1):
					var wx := (float(cx) + 0.5) * cell - GameConstants.WORLD_HALF
					var wz := (float(cz) + 0.5) * cell - GameConstants.WORLD_HALF
					var d := _segment_distance(Vector2(wx, wz), a, b)
					var idx := cz * res + cx
					if d < river_grid[idx]:
						river_grid[idx] = d

func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / max(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _river_distance(x: float, z: float) -> float:
	var res := river_grid_res
	var cell := river_grid_world / float(res)
	var fx := clampf((x + GameConstants.WORLD_HALF) / cell - 0.5, 0.0, res - 1.001)
	var fz := clampf((z + GameConstants.WORLD_HALF) / cell - 0.5, 0.0, res - 1.001)
	var x0 := int(fx)
	var z0 := int(fz)
	var tx := fx - x0
	var tz := fz - z0
	var i00 := z0 * res + x0
	var v00 := river_grid[i00]
	var v10 := river_grid[i00 + 1]
	var v01 := river_grid[i00 + res]
	var v11 := river_grid[i00 + res + 1]
	return lerpf(lerpf(v00, v10, tx), lerpf(v01, v11, tx), tz)

func _compute_waterfall_spots() -> void:
	# Her nehrin denize döküldüğü yerde şelale noktası bul
	for river in rivers:
		for i in range(river.size() - 1, 0, -1):
			var p: Vector2 = river[i]
			var h := get_height_raw(p.x, p.y)
			if h > 2.5:
				var top: Vector2 = river[i]
				var top_h := get_height_raw(top.x, top.y)
				waterfall_spots.append({"pos": Vector3(top.x, top_h + 0.4, top.y), "flow": (river[i - 1] - top).normalized()})
				break

## Dış katman (plaj/nehir) uygulamadan saf yükseklik
func get_height_raw(x: float, z: float) -> float:
	var mask := 0.0
	var peak := 0.0
	for isl in islands:
		var d := Vector2(x, z).distance_to(isl["center"])
		var f := smoothstep(isl["radius"], isl["radius"] * 0.30, d)
		if f > mask:
			mask = f
		var p: float = f * isl["peak"]
		if p > peak:
			peak = p
	var n1 := noise_hills.get_noise_2d(x, z)
	var ridge := noise_ridge.get_noise_2d(x, z)
	var hills := 45.0 + n1 * 55.0
	var mountains := ridge * ridge * peak
	var land := hills * mask + mountains
	var seafloor := -12.0 - absf(noise_detail.get_noise_2d(x * 0.7, z * 0.7)) * 28.0
	return lerpf(seafloor, land, smoothstep(0.03, 0.30, mask))

## Nihai yükseklik: plaj yumuşatma + nehir oyma + göl çukuru
func get_height(x: float, z: float) -> float:
	var h := get_height_raw(x, z)
	if h < 6.0 and h > -4.0:
		h = h * 0.35 + 1.9
	var rd := _river_distance(x, z)
	var rw := 16.0
	var rf := smoothstep(rw, rw * 0.35, rd)
	if rf > 0.0 and h > -1.0:
		h -= rf * 5.0 * clampf(h / 25.0, 0.3, 1.0)
	for lake in lakes:
		var d := Vector2(x, z).distance_to(lake["center"])
		var lf := smoothstep(lake["radius"], lake["radius"] * 0.4, d)
		if lf > 0.0:
			h -= lf * lake["depth"]
	return h

func get_slope(x: float, z: float) -> float:
	var e := 2.5
	var hl := get_height(x - e, z)
	var hr := get_height(x + e, z)
	var hd := get_height(x, z - e)
	var hu := get_height(x, z + e)
	var n := Vector3(2.0 * e, hr - hl, 0.0).cross(Vector3(0.0, hu - hd, 2.0 * e)).normalized()
	return 1.0 - n.y

func _make_terrain_material() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/terrain.gdshader")
	mat.set_shader_parameter("tex_sand", TextureFactory.make_detail_albedo(256, 101, Color(0.76, 0.70, 0.50), Color(0.55, 0.50, 0.36), 0.5))
	mat.set_shader_parameter("tex_grass", TextureFactory.make_detail_albedo(256, 202, Color(0.20, 0.34, 0.12), Color(0.38, 0.48, 0.20), 0.6))
	mat.set_shader_parameter("tex_rock", TextureFactory.make_detail_albedo(256, 303, Color(0.38, 0.37, 0.36), Color(0.22, 0.21, 0.20), 0.5))
	mat.set_shader_parameter("tex_snow", TextureFactory.make_detail_albedo(256, 404, Color(0.88, 0.90, 0.94), Color(0.72, 0.75, 0.82), 0.25))
	var noise_img := TextureFactory.make_tileable_noise(256, 505, 5, 3)
	mat.set_shader_parameter("tex_noise", ImageTexture.create_from_image(noise_img))
	mat.set_shader_parameter("normal_detail", TextureFactory.make_normal_map_from_height(noise_img, 2.5))
	terrain_material = mat

func _make_heightmap_texture() -> void:
	heightmap_texture = TextureFactory.make_heightmap_texture(
		GameConstants.HEIGHTMAP_TEXTURE_RES, GameConstants.WORLD_SIZE,
		Callable(self, "get_height"), -60.0, 440.0)
	heightmap_ready.emit()

## Quadtree güncelleme (StreamingManager tarafından çağrılır)
func update_quadtree(cam_pos: Vector3) -> void:
	_update_chunk(root_chunk, cam_pos)
	_process_free_queue()

func _rect_distance(p: Vector3, c: Vector2, s: float) -> float:
	var half := s * 0.5
	var dx := maxf(absf(p.x - c.x) - half, 0.0)
	var dz := maxf(absf(p.z - c.y) - half, 0.0)
	return Vector2(dx, dz).length()

func _update_chunk(chunk: TerrainChunk, cam_pos: Vector3) -> void:
	var d := _rect_distance(cam_pos, chunk.center, chunk.size)
	chunk.built_distance = d
	var want_split := chunk.size > GameConstants.MIN_CHUNK_SIZE and d < chunk.size * GameConstants.SPLIT_FACTOR
	if want_split and chunk.children.is_empty():
		chunk.create_children()
	if want_split:
		chunk.set_mesh_visible(false)
		for c in chunk.children:
			_update_chunk(c, cam_pos)
	else:
		if not chunk.children.is_empty():
			chunk.free_children()
		chunk.set_mesh_visible(true)
		if not chunk.mesh_built:
			request_build(chunk)

func process_build_queue(max_builds: int) -> void:
	var built := 0
	while built < max_builds and not build_queue.is_empty():
		var c: TerrainChunk = build_queue.pop_front()
		if is_instance_valid(c) and not c.mesh_built:
			c.build_mesh()
			chunk_built.emit(c)
			built += 1

func _process_free_queue() -> void:
	for c in free_queue:
		if is_instance_valid(c):
			all_chunks.erase(c)
			chunk_freed.emit(c)
			c.queue_free()
	free_queue.clear()

func get_chunk_count() -> int:
	var leaves := 0
	for c in all_chunks:
		if c.children.is_empty():
			leaves += 1
	return leaves

class_name Ocean
extends Node3D
## Ocean - iki katmanlı okyanus: kamerayı takip eden detaylı yakın alan
## (Gerstner dalgaları vertex shader'da) + ufuk kadar uzanan uzak alan.
## Kıyı köpüğü ve derinlik rengi dünya yükseklik haritası dokusundan okunur.

var world_manager: WorldManager
var near_mesh: MeshInstance3D
var far_mesh: MeshInstance3D
var near_mat: ShaderMaterial
var far_mat: ShaderMaterial
var amp_scale := 1.0
var _snap := 4.0

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	_make_materials()
	_make_meshes()
	var terrain: TerrainManager = p_wm.get_manager("TerrainManager")
	if terrain:
		terrain.heightmap_ready.connect(_on_heightmap_ready)
		if terrain.heightmap_texture:
			_on_heightmap_ready()

func _make_materials() -> void:
	var noise_img := TextureFactory.make_tileable_noise(256, 707, 5, 3)
	var noise_tex := ImageTexture.create_from_image(noise_img)
	var foam_tex := TextureFactory.make_foam_texture(256, 808)
	near_mat = ShaderMaterial.new()
	near_mat.shader = load("res://shaders/ocean.gdshader")
	_far_setup(near_mat, noise_tex, foam_tex, 0.0)
	far_mat = ShaderMaterial.new()
	far_mat.shader = load("res://shaders/ocean.gdshader")
	_far_setup(far_mat, noise_tex, foam_tex, 1.0)

func _far_setup(mat: ShaderMaterial, noise_tex: Texture, foam_tex: Texture, far_field: float) -> void:
	mat.set_shader_parameter("detail_noise", noise_tex)
	mat.set_shader_parameter("foam_tex", foam_tex)
	mat.set_shader_parameter("far_field", far_field)
	mat.set_shader_parameter("heightmap_uv_scale", Vector2(1.0 / GameConstants.WORLD_SIZE, 1.0 / GameConstants.WORLD_SIZE))
	mat.set_shader_parameter("heightmap_min", -60.0)
	mat.set_shader_parameter("heightmap_range", 500.0)

func _make_meshes() -> void:
	var near_plane := PlaneMesh.new()
	near_plane.size = Vector2(GameConstants.OCEAN_NEAR_SIZE, GameConstants.OCEAN_NEAR_SIZE)
	near_plane.subdivide_width = GameConstants.OCEAN_NEAR_SEGMENTS
	near_plane.subdivide_depth = GameConstants.OCEAN_NEAR_SEGMENTS
	near_mesh = MeshInstance3D.new()
	near_mesh.name = "OkyanusYakin"
	near_mesh.mesh = near_plane
	near_mesh.material_override = near_mat
	near_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# shader kamerayı takip ettiği için AABB geniş tutulur (frustum culling yanılmasın)
	near_mesh.custom_aabb = AABB(Vector3(-9500, -120, -9500), Vector3(19000, 240, 19000))
	add_child(near_mesh)

	var far_plane := PlaneMesh.new()
	far_plane.size = Vector2(GameConstants.OCEAN_FAR_SIZE, GameConstants.OCEAN_FAR_SIZE)
	far_plane.subdivide_width = GameConstants.OCEAN_FAR_SEGMENTS
	far_plane.subdivide_depth = GameConstants.OCEAN_FAR_SEGMENTS
	far_mesh = MeshInstance3D.new()
	far_mesh.name = "OkyanusUzak"
	far_mesh.mesh = far_plane
	far_mesh.material_override = far_mat
	far_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(far_mesh)

func _on_heightmap_ready() -> void:
	var terrain: TerrainManager = world_manager.get_manager("TerrainManager")
	if terrain and terrain.heightmap_texture:
		near_mat.set_shader_parameter("heightmap_tex", terrain.heightmap_texture)
		far_mat.set_shader_parameter("heightmap_tex", terrain.heightmap_texture)

func set_weather_waves(scale: float, speed: float) -> void:
	amp_scale = scale
	near_mat.set_shader_parameter("wave_speed", speed)
	far_mat.set_shader_parameter("wave_speed", speed)

func set_sun(dir: Vector3, color: Color, intensity: float, lightning: float) -> void:
	if near_mat == null:
		return
	for m in [near_mat, far_mat]:
		m.set_shader_parameter("sun_direction", dir)
		m.set_shader_parameter("sun_color", color)
		m.set_shader_parameter("sun_intensity", intensity)
		m.set_shader_parameter("lightning", lightning)

func set_lightning(v: float) -> void:
	if near_mat == null:
		return
	for m in [near_mat, far_mat]:
		m.set_shader_parameter("lightning", v)

func set_sky_reflect(color: Color) -> void:
	if near_mat == null:
		return
	for m in [near_mat, far_mat]:
		m.set_shader_parameter("sky_reflect_color", color)

func set_wetness(w: float) -> void:
	if near_mat == null:
		return
	for m in [near_mat, far_mat]:
		m.set_shader_parameter("wetness", w)

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var p := cam.global_position
	# doku kaymasını önlemek için ızgaraya yasla
	var cx := snappedf(p.x, _snap)
	var cz := snappedf(p.z, _snap)
	near_mat.set_shader_parameter("grid_center", Vector2(cx, cz))

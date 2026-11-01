class_name RainSystem
extends Node3D
## RainSystem - kamerayı saran silindir üzerinde shader ile çizilen yağmur.
## Mobil dostudur (tek draw call). Yoğunluk hava durumuna göre ayarlanır.

var intensity := 0.0
var mesh_instance: MeshInstance3D
var mat: ShaderMaterial
var world_manager: WorldManager

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/rain.gdshader")
	mat.set_shader_parameter("streak_tex", TextureFactory.make_streak_texture(128, 909))
	var cyl := CylinderMesh.new()
	cyl.top_radius = 55.0
	cyl.bottom_radius = 55.0
	cyl.height = 110.0
	cyl.radial_segments = 32
	cyl.cap_top = false
	cyl.cap_bottom = false
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Yagmur"
	mesh_instance.mesh = cyl
	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	set_intensity(0.0)

func set_intensity(v: float) -> void:
	intensity = clampf(v, 0.0, 1.0)
	mat.set_shader_parameter("intensity", intensity)
	mesh_instance.visible = intensity > 0.02

func set_lightning_flash(v: float) -> void:
	mat.set_shader_parameter("lightning", v)

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		global_position = Vector3(cam.global_position.x, cam.global_position.y + 20.0, cam.global_position.z)

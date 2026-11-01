class_name TerrainChunk
extends Node3D
## TerrainChunk - quadtree arazi parçası. Quadtree LOD: kameraya yakınsa 4 alt
## parçaya bölünür, uzaktaysa tek parça olarak çizilir. Her parçanın geometrisi
## ve bitkisi kuyruk (StreamingManager) ile aşamalı yüklenir.

var center := Vector2.ZERO
var size := 0.0
var depth := 0
var terrain_manager: TerrainManager
var mesh_built := false
var mesh_instance: MeshInstance3D
var children: Array[TerrainChunk] = []
var veg_root: Node3D
var built_distance := 0.0  # kameraya uzaklık (bitki yoğunluğu için)

func setup(p_center: Vector2, p_size: float, p_depth: int, p_tm: TerrainManager) -> void:
	center = p_center
	size = p_size
	depth = p_depth
	terrain_manager = p_tm
	name = "Chunk_%d_%d_d%d" % [int(center.x), int(center.y), depth]

func segments_for_size(p_size: float) -> int:
	return clampi(int(p_size / GameConstants.TARGET_CELL_SIZE), 8, GameConstants.MAX_CHUNK_VERTEX_DENSITY)

func create_children() -> void:
	if not children.is_empty():
		return
	var half := size * 0.5
	var quarter := size * 0.25
	for dx in [-quarter, quarter]:
		for dz in [-quarter, quarter]:
			var child := TerrainChunk.new()
			child.setup(center + Vector2(dx, dz), half, depth + 1, terrain_manager)
			children.append(child)
			terrain_manager.add_chunk_node(child)

func free_children() -> void:
	for c in children:
		terrain_manager.queue_free_chunk(c)
	children.clear()

func set_mesh_visible(v: bool) -> void:
	if mesh_instance:
		mesh_instance.visible = v

## Parça geometrisi: yükseklik örnekleme + elle hesaplanan normal/tangent (Godot 4.7: tangent = PackedFloat32Array, tepe başına 4 float).
func build_mesh() -> void:
	if mesh_built:
		return
	var segs := segments_for_size(size)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var n := segs + 1
	verts.resize(n * n)
	normals.resize(n * n)
	tangents.resize(n * n * 4)
	uvs.resize(n * n)
	var e := 2.0
	var x0 := center.x - size * 0.5
	var z0 := center.y - size * 0.5
	for iz in range(n):
		for ix in range(n):
			var wx := x0 + size * float(ix) / float(segs)
			var wz := z0 + size * float(iz) / float(segs)
			var wy := terrain_manager.get_height(wx, wz)
			var idx := iz * n + ix
			verts[idx] = Vector3(wx, wy, wz)
			uvs[idx] = Vector2(wx, wz)
			var hl := terrain_manager.get_height(wx - e, wz)
			var hr := terrain_manager.get_height(wx + e, wz)
			var hd := terrain_manager.get_height(wx, wz - e)
			var hu := terrain_manager.get_height(wx, wz + e)
			var dx := Vector3(2.0 * e, hr - hl, 0.0)
			var dz := Vector3(0.0, hu - hd, 2.0 * e)
			var nrm := dz.cross(dx).normalized()
			normals[idx] = nrm
			var tan := Vector3(1.0, (hr - hl) / (2.0 * e), 0.0).normalized()
			var bit := Vector3(0.0, (hu - hd) / (2.0 * e), 1.0).normalized()
			var handed := 1.0 if nrm.cross(tan).dot(bit) >= 0.0 else -1.0
			tangents[idx * 4] = tan.x
			tangents[idx * 4 + 1] = tan.y
			tangents[idx * 4 + 2] = tan.z
			tangents[idx * 4 + 3] = handed
	for iz in range(segs):
		for ix in range(segs):
			var i0 := iz * n + ix
			var i1 := i0 + 1
			var i2 := i0 + n
			var i3 := i2 + 1
			indices.append_array([i0, i2, i1, i1, i2, i3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var amesh := ArrayMesh.new()
	amesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = amesh
	mesh_instance.material_override = terrain_manager.terrain_material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var aabb := AABB(Vector3(x0, -80.0, z0), Vector3(size, 700.0, size))
	mesh_instance.custom_aabb = aabb
	add_child(mesh_instance)
	mesh_built = true

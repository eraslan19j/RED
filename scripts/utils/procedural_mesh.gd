class_name ProceduralMeshUtil
extends RefCounted
## Prosedürel geometri: ağaçlar, kayalar, kaleler, kalıntılar, şelale vb.
## Tüm modeller çalışma zamanında üretilir (lisans gerektirmez, CC0 eşdeğeri dahili üretim).

## Bir primitive mesh'in yüzey dizilerini (arrays) hedef ArrayMesh'e ekler.
## Dönüşüm (transform) tepe noktalarına ve normal noktalara uygulanır.
static func append_primitive(p_target: ArrayMesh, p_prim: PrimitiveMesh, p_transform: Transform3D, p_color: Color, p_color_a: float = -1.0) -> void:
	var surf := p_prim.surface_get_arrays(0)
	if surf.is_empty():
		return
	var verts: PackedVector3Array = surf[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = surf[Mesh.ARRAY_NORMAL] if surf[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uvs: PackedVector2Array = surf[Mesh.ARRAY_TEX_UV] if surf[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var index: PackedInt32Array = surf[Mesh.ARRAY_INDEX] if surf[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var new_verts := PackedVector3Array()
	new_verts.resize(verts.size())
	for i in range(verts.size()):
		new_verts[i] = p_transform * verts[i]
	var new_normals := PackedVector3Array()
	if not normals.is_empty():
		var basis := p_transform.basis
		new_normals.resize(normals.size())
		for i in range(normals.size()):
			new_normals[i] = (basis * normals[i]).normalized()
	var new_uvs := PackedVector2Array()
	if not uvs.is_empty():
		new_uvs = uvs.duplicate()
	var colors := PackedColorArray()
	colors.resize(verts.size())
	var a := p_color.a if p_color_a >= 0.0 else p_color.a
	for i in range(verts.size()):
		colors[i] = Color(p_color.r, p_color.g, p_color.b, a)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = new_verts
	if not new_normals.is_empty():
		arrays[Mesh.ARRAY_NORMAL] = new_normals
	if not new_uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = new_uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = index
	p_target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

static func _cyl(p_top: float, p_bottom: float, p_height: float, p_segments: int = 8, p_rings: int = 1) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = p_top
	c.bottom_radius = p_bottom
	c.height = p_height
	c.radial_segments = p_segments
	c.rings = p_rings
	return c

static func _sphere(p_radius: float, p_rings: int = 6, p_segments: int = 8) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = p_radius
	s.height = p_radius * 2.0
	s.radial_segments = p_segments
	s.rings = p_rings
	return s

static func _box(p_size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = p_size
	return b

## Çam ağacı: kahverengi gövde + yeşil katmanlı tepe (rengi vertex color ile kodlanır).
## Renk alfa kanalı rüzgar salınım maskesi olarak kullanılır (1 = tepe sallanır).
static func make_pine_tree(p_height: float = 9.0, p_trunk_color := Color(0.32, 0.22, 0.14), p_leaf_color := Color(0.10, 0.26, 0.10)) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var trunk_h := p_height * 0.32
	append_primitive(mesh, _cyl(0.16 * p_height * 0.2, 0.30 * p_height * 0.2, trunk_h, 7), Transform3D(Basis(), Vector3(0, trunk_h * 0.5, 0)), p_trunk_color, 0.0)
	var layers := 3
	for i in range(layers):
		var t := float(i) / float(layers - 1)
		var base_y := trunk_h + t * p_height * 0.62
		var r := p_height * 0.34 * (1.0 - t * 0.72)
		var h := p_height * 0.34
		append_primitive(mesh, _cyl(0.0, r, h, 8), Transform3D(Basis(), Vector3(0, base_y + h * 0.5, 0)), p_leaf_color, 0.35 + 0.65 * t)
	return mesh

## Geniş yapraklı ağaç: gövde + küresel tepe.
static func make_broadleaf_tree(p_height: float = 7.5, p_trunk_color := Color(0.36, 0.26, 0.17), p_leaf_color := Color(0.16, 0.36, 0.14)) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var trunk_h := p_height * 0.42
	append_primitive(mesh, _cyl(0.14, 0.26, trunk_h, 7), Transform3D(Basis(), Vector3(0, trunk_h * 0.5, 0)), p_trunk_color, 0.0)
	append_primitive(mesh, _sphere(p_height * 0.30, 5, 8), Transform3D(Basis(), Vector3(0, trunk_h + p_height * 0.22, 0)), p_leaf_color, 1.0)
	append_primitive(mesh, _sphere(p_height * 0.20, 4, 7), Transform3D(Basis(), Vector3(p_height * 0.14, trunk_h + p_height * 0.05, 0)), p_leaf_color, 1.0)
	return mesh

## Çalı: yassı küre.
static func make_bush(p_radius: float = 1.2, p_color := Color(0.14, 0.30, 0.12)) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var s := _sphere(p_radius, 4, 7)
	append_primitive(mesh, s, Transform3D(Basis.from_scale(Vector3(1.0, 0.7, 1.0)), Vector3(0, p_radius * 0.55, 0)), p_color, 0.6)
	return mesh

## Kaya: gürültü ile deforme edilmiş küre (basit ve mobil-dostu).
static func make_rock(p_radius: float = 1.0, p_seed: int = 5, p_color := Color(0.42, 0.41, 0.40)) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	var mesh := ArrayMesh.new()
	var s := _sphere(p_radius, 3, 6)
	var arr := s.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in range(verts.size()):
		var d := verts[i].normalized()
		var n := sin(d.x * 5.1 + p_seed) * sin(d.y * 4.3 + p_seed * 2.0) * sin(d.z * 6.7 + p_seed)
		verts[i] = verts[i] * (1.0 + n * 0.22)
	arr[Mesh.ARRAY_VERTEX] = verts
	var colors := PackedColorArray()
	colors.resize(verts.size())
	for i in range(verts.size()):
		colors[i] = Color(p_color.r, p_color.g, p_color.b, 0.0)
	arr[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh

## Çim kartı: iki çapraz kuad (alfa dokusu ile).
static func make_grass_card(p_size: float = 1.4) -> ArrayMesh:
	var h := p_size
	var w := p_size * 0.5
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var idx := PackedInt32Array()
	var quads := [
		[Vector3(-w, 0, 0), Vector3(w, 0, 0), Vector3(w, h, 0), Vector3(-w, h, 0)],
		[Vector3(0, 0, -w), Vector3(0, 0, w), Vector3(0, h, w), Vector3(0, h, -w)],
	]
	var normals := PackedVector3Array()
	var base := 0
	for q in quads:
		var quad_uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for i in range(4):
			verts.append(q[i])
			uvs.append(quad_uv[i])
			normals.append(Vector3(0, 1, 0))
			colors.append(Color(1, 1, 1, float(i) / 3.0)) # alpha = yükseklik maskesi
		idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
		base += 4
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## Kırık sütun (antik kalıntılar için).
static func make_column(p_height: float = 4.0, p_radius: float = 0.45, p_broken: float = 1.0, p_color := Color(0.72, 0.70, 0.64)) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var h := p_height * p_broken
	append_primitive(mesh, _cyl(p_radius * 0.9, p_radius, h, 8), Transform3D(Basis(), Vector3(0, h * 0.5, 0)), p_color, 0.0)
	append_primitive(mesh, _cyl(p_radius * 1.25, p_radius * 1.25, 0.3, 8), Transform3D(Basis(), Vector3(0, 0.15, 0)), p_color, 0.0)
	return mesh

## Kale kulesi.
static func make_tower(p_height: float = 14.0, p_radius: float = 3.0, p_color := Color(0.55, 0.54, 0.50)) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	append_primitive(mesh, _cyl(p_radius * 0.85, p_radius, p_height, 10), Transform3D(Basis(), Vector3(0, p_height * 0.5, 0)), p_color, 0.0)
	append_primitive(mesh, _cyl(0.0, p_radius * 1.15, p_height * 0.22, 10), Transform3D(Basis(), Vector3(0, p_height + p_height * 0.11, 0)), Color(0.30, 0.32, 0.38), 0.0)
	return mesh

## Şelale şeridi: dikey kuad (şelale shader'ı ile kaplanır).
static func make_waterfall_quad(p_width: float, p_height: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var w := p_width * 0.5
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-w, 0, 0), Vector3(w, 0, 0), Vector3(w, p_height, 0), Vector3(-w, p_height, 0),
	])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## Şimşek civarı: jagged çizgi (ImmediateMesh ile çizilir, bu yüzden sadece nokta listesi döner).
static func make_lightning_points(p_from: Vector3, p_to: Vector3, p_segments: int = 14, p_seed: int = 1) -> PackedVector3Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	var pts := PackedVector3Array()
	for i in range(p_segments + 1):
		var t := float(i) / float(p_segments)
		var p := p_from.lerp(p_to, t)
		if i > 0 and i < p_segments:
			var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.6), rng.randf_range(-1, 1))
			p += off * (1.0 - absf(t - 0.5) * 2.0) * 6.0
		pts.append(p)
	return pts

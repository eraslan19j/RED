class_name StreamingManager
extends Node3D
## StreamingManager - kamera etrafındaki arazi parçalarının yükleme/boşaltma
## kuyruğunu yönetir. Her karede sınırlı sayıda parça inşa edilir (frame budget)
## böylece akıcı bir deneyim sağlanır. İleride varlık (asset) akışı da buradan
## geçecek şekilde tasarlandı.

var world_manager: WorldManager
var terrain: TerrainManager
var max_builds_per_frame := 2
var _timer := 0.0
var stats := {"yuklenen": 0, "bosaltilan": 0, "kuyruk": 0}

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	terrain = p_wm.get_manager("TerrainManager")
	terrain.chunk_built.connect(_on_chunk_built)
	terrain.chunk_freed.connect(_on_chunk_freed)

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.2
		terrain.update_quadtree(cam.global_position)
	terrain.process_build_queue(max_builds_per_frame)
	stats["kuyruk"] = terrain.build_queue.size()

func _on_chunk_built(_c: TerrainChunk) -> void:
	stats["yuklenen"] += 1

func _on_chunk_freed(_c: TerrainChunk) -> void:
	stats["bosaltilan"] += 1

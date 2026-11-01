class_name FreeCamera
extends Node3D
## FreeCamera - serbest keşif kamerası. Klavye (WASD + Q/E + Shift) ve çoklu
## dokunmatik (sol joystick hareket, sağ taraf bakış) destekler.
## DragonCamera (M5) bu sınıfın arayüzünü miras alacak şekilde tasarlandı.

var camera: Camera3D
var world_manager: WorldManager
var yaw := 0.0
var pitch := -0.12
var speed := GameConstants.CAM_DEFAULT_SPEED
var enabled := true

var joystick := Vector2.ZERO      # x = sağ/sol, y = ileri/geri (-1..1)
var fly_input := 0.0              # yukarı/aşağı (-1..1)

var _keys := {}
var _look_touch := -1
var _look_last := Vector2.ZERO
var _stick_touch := -1
var _stick_origin := Vector2.ZERO

signal joystick_changed(v: Vector2)

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	camera = Camera3D.new()
	camera.name = "Kamera"
	camera.fov = GameConstants.CAMERA_FOV
	camera.near = GameConstants.CAMERA_NEAR
	camera.far = GameConstants.CAMERA_FAR
	add_child(camera)

func _ready() -> void:
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var w := get_viewport().get_visible_rect().size.x
			if event.position.x < w * 0.45 and _stick_touch == -1:
				_stick_touch = event.index
				_stick_origin = event.position
			elif _look_touch == -1:
				_look_touch = event.index
				_look_last = event.position
		else:
			if event.index == _stick_touch:
				_stick_touch = -1
				joystick = Vector2.ZERO
				joystick_changed.emit(joystick)
			if event.index == _look_touch:
				_look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch:
			var d := (event.position - _stick_origin) / 70.0
			if d.length() > 1.0:
				d = d.normalized()
			joystick = d
			joystick_changed.emit(joystick)
		elif event.index == _look_touch:
			var d: Vector2 = event.position - _look_last
			_look_last = event.position
			yaw -= d.x * GameConstants.CAM_LOOK_SPEED
			pitch -= d.y * GameConstants.CAM_LOOK_SPEED
			pitch = clampf(pitch, -1.45, 1.45)
	elif event is InputEventKey:
		if event.pressed and not event.echo:
			_keys[event.keycode] = true
		else:
			_keys.erase(event.keycode)

func _process(delta: float) -> void:
	rotation = Vector3(pitch, yaw, 0.0)
	if not enabled:
		return
	var fwd := 0.0
	var strafe := 0.0
	var up := 0.0
	if _keys.has(KEY_W) or _keys.has(KEY_UP):
		fwd += 1.0
	if _keys.has(KEY_S) or _keys.has(KEY_DOWN):
		fwd -= 1.0
	if _keys.has(KEY_A):
		strafe -= 1.0
	if _keys.has(KEY_D):
		strafe += 1.0
	if _keys.has(KEY_E) or _keys.has(KEY_SPACE):
		up += 1.0
	if _keys.has(KEY_Q) or _keys.has(KEY_CTRL):
		up -= 1.0
	fwd += -joystick.y
	strafe += joystick.x
	up += fly_input
	var sp := speed
	if _keys.has(KEY_SHIFT):
		sp = GameConstants.CAM_FAST_SPEED
	var move := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(strafe, up, -fwd)
	if move.length() > 0.001:
		position += move.normalized() * sp * delta * clampf(move.length(), 0.0, 1.0)
	# arazi/deniz üzerinde kal
	var min_y := maxf(
		world_manager.get_terrain_height(position.x, position.z) + GameConstants.CAM_MIN_HEIGHT_ABOVE_TERRAIN,
		GameConstants.SEA_LEVEL + GameConstants.CAM_MIN_HEIGHT_ABOVE_SEA)
	if position.y < min_y:
		position.y = min_y

class_name DayNightCycle
extends Node3D
## DayNightCycle - günün saati (0..24). LightingManager bu değeri güneş ve
## gökyüzü konumuna çevirir.

signal time_changed(hour: float)

var hour := GameConstants.START_TIME
var paused := false
var _emit_timer := 0.0

func advance(delta: float) -> void:
	if paused:
		return
	hour = fposmod(hour + delta * 24.0 / GameConstants.DAY_LENGTH_SECONDS, 24.0)
	_emit_timer -= delta
	if _emit_timer <= 0.0:
		_emit_timer = 0.1
		time_changed.emit(hour)

func is_night() -> bool:
	return hour < 5.5 or hour > 19.5

func get_day_factor() -> float:
	# 0 = gece, 1 = öğlen
	var t := (hour - 6.0) / 12.0
	if t < 0.0 or t > 1.0:
		return 0.0
	return sin(t * PI)

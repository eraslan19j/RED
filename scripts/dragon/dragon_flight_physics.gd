class_name DragonFlightPhysics
extends RefCounted
## DragonFlightPhysics - ejderha uçuş fiziği için arayüz (Milestone 4'te
## gerçek aerodinamik model ile doldurulacak: kaldırma, sürükleme, itki,
## stall hızı, alçalma, kanat çırpma dinamiği).

## Şu an yer tutucu: sıfır ivme döndürür.
static func compute_acceleration(_velocity: Vector3, _wing_input: float, _throttle: float, _air_density: float) -> Vector3:
	return Vector3.ZERO

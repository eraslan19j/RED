class_name DragonController
extends Node3D
## DragonController - EJDERHA SİSTEMLERİ İÇİN ARAYÜZ (Milestone 3-5'te doldurulacak).
## Şu an yer tutucu (stub): API ve sinyaller sabit; dünya entegrasyonu hazır.
## WorldManager.get_terrain_height() iniş ve uçuş irtifası için kullanılır.

signal mounted(dragon)
signal dismounted
signal took_off
signal landed

enum State { IDLE, MOUNTED, FLYING, LANDED }

var state: int = State.IDLE
var dragon: Node3D = null        # M3: iskeletli ejderha modeli
var physics: DragonFlightPhysics = null  # M4: aerodinamik

func mount(p_dragon: Node3D) -> void:
	dragon = p_dragon
	state = State.MOUNTED
	mounted.emit(dragon)

func take_off() -> void:
	if state == State.MOUNTED or state == State.LANDED:
		state = State.FLYING
		took_off.emit()

func land() -> void:
	if state == State.FLYING:
		state = State.LANDED
		landed.emit()

func dismount() -> void:
	state = State.IDLE
	dismounted.emit()

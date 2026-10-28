class_name FocusTimer
extends Node
## Focus timer ที่เก็บเวลาเริ่มเป็น Unix timestamp (ไม่นับ tick)
## ทำให้ถูกต้องแม้เครื่อง Sleep / Lock หน้าจอ

signal state_changed(new_state: State)
signal progress_changed(progress: float)

enum State { IDLE, BAKING, RESTING, COMPLETE }

const BAKING_END := 0.7  # 0% - 70% = Baking, 70% - 99% = Resting

var state: State = State.IDLE
var start_unix: float = 0.0
var duration_sec: float = 0.0


func start_minutes(minutes: int) -> void:
	start_seconds(minutes * 60.0)


# ใช้ตอนเทสต์ เช่น start_seconds(10.0) จะได้ไม่ต้องรอ 15 นาที
func start_seconds(seconds: float) -> void:
	if state != State.IDLE:
		return
	start_unix = Time.get_unix_time_from_system()
	duration_sec = seconds
	_set_state(State.BAKING)


# ยกเลิกกลางคัน (Phase 2 ค่อยเปลี่ยนเป็น "คุกกี้ไหม้")
func cancel() -> void:
	if state == State.BAKING or state == State.RESTING:
		_set_state(State.IDLE)


# เก็บเค้กตอนครบเวลา คืน true ถ้าเก็บสำเร็จ
func collect() -> bool:
	if state != State.COMPLETE:
		return false
	_set_state(State.IDLE)
	return true


func get_progress() -> float:
	if state == State.IDLE or duration_sec <= 0.0:
		return 0.0
	var elapsed := Time.get_unix_time_from_system() - start_unix
	return clampf(elapsed / duration_sec, 0.0, 1.0)


func _process(_delta: float) -> void:
	if state == State.IDLE or state == State.COMPLETE:
		return
	var p := get_progress()
	progress_changed.emit(p)
	var target := State.BAKING
	if p >= 1.0:
		target = State.COMPLETE
	elif p >= BAKING_END:
		target = State.RESTING
	if target != state:
		_set_state(target)


func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)

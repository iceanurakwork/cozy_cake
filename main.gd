extends Control
## Scene tree ที่ต้องมี (ชื่อ Node ต้องตรงตามนี้):
## Main (Control, Full Rect)  <- สคริปต์นี้
## ├─ Body (Panel)  Position (10,10)  Size (300,260)
## │   ├─ Character (ColorRect)  ตัวแทนตัวละคร
## │   ├─ StateLabel (Label)
## │   ├─ StartButton (Button)  text: "เริ่ม (เทสต์ 10 วิ)"
## │   └─ CollectButton (Button)  text: "เก็บเค้ก"
## └─ FocusTimer (Node)  แนบ focus_timer.gd
 
@onready var body: Control = $Body
@onready var character: ColorRect = $Body/Character
@onready var state_label: Label = $Body/StateLabel
@onready var start_btn: Button = $Body/StartButton
@onready var collect_btn: Button = $Body/CollectButton
@onready var focus_timer: FocusTimer = $FocusTimer
 
var cakes: int = 0
 
 
func _ready() -> void:
	_setup_window()
	focus_timer.state_changed.connect(_on_state_changed)
	start_btn.pressed.connect(func(): focus_timer.start_seconds(10.0))
	collect_btn.pressed.connect(_on_collect_pressed)
	_on_state_changed(focus_timer.state)
	# รอ 1 เฟรมให้ Layout คำนวณเสร็จก่อนค่อยตั้ง Click-through
	await get_tree().process_frame
	_update_passthrough()
 
 
func _setup_window() -> void:
	# per_pixel_transparency ต้องเปิดใน Project Settings (ตั้งตอน runtime ไม่ได้)
	get_viewport().transparent_bg = true
	var win := get_window()
	win.borderless = true
	win.always_on_top = true
	win.transparent = true
 
 
# เฉพาะพื้นที่ของ Body เท่านั้นที่รับคลิก ส่วนที่เหลือทะลุไปหน้าต่างอื่น
func _update_passthrough() -> void:
	var r := body.get_global_rect()
	var poly := PackedVector2Array([
		r.position,
		Vector2(r.end.x, r.position.y),
		r.end,
		Vector2(r.position.x, r.end.y),
	])
	DisplayServer.window_set_mouse_passthrough(poly)
 
 
func _on_state_changed(new_state: FocusTimer.State) -> void:
	collect_btn.visible = new_state == FocusTimer.State.COMPLETE
	start_btn.visible = new_state == FocusTimer.State.IDLE
	match new_state:
		FocusTimer.State.IDLE:
			character.color = Color.GRAY
			state_label.text = "Idle | เค้ก: %d" % cakes
		FocusTimer.State.BAKING:
			character.color = Color.ORANGE
			state_label.text = "Baking"
		FocusTimer.State.RESTING:
			character.color = Color.SKY_BLUE
			state_label.text = "Resting"
		FocusTimer.State.COMPLETE:
			character.color = Color.LIME_GREEN
			state_label.text = "Complete!"
 
 
func _on_collect_pressed() -> void:
	if focus_timer.collect():
		cakes += 1
		_on_state_changed(focus_timer.state)
 

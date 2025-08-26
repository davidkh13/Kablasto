extends TextureRect

var gameManager: Node
var start_pos : Vector2
var go_pass = true
var idle_timer: Timer

var cheat_sequence = [
	"ui_up", "ui_up", "ui_up",
	"ui_down", "ui_down", "ui_down",
	"ui_left", "ui_right", "ui_left", "ui_right"
]
var cheat_index = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gameManager = get_tree().get_root().get_node("Main/GameManager")
	gameManager.startScreen = self
	visible = false

	# Start a 60-second idle timer
	idle_timer = Timer.new()
	idle_timer.wait_time = 30
	idle_timer.one_shot = true
	idle_timer.autostart = true
	add_child(idle_timer)
	idle_timer.timeout.connect(_on_idle_timeout)
	
	var cam = get_viewport().get_camera_2d()
	if cam:
		start_pos = cam.global_position
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
func _input(event: InputEvent) -> void:
	if visible == true and go_pass == true:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				go_pass = false
				$AudioStreamPlayer.play()
				gameManager.play_ball(self)
				
	if event.is_action_pressed(cheat_sequence[cheat_index]):
		cheat_index += 1
		if cheat_index >= cheat_sequence.size():
			_activate_cheat()
			cheat_index = 0
	else:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") \
			or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			# Wrong input — reset sequence
			cheat_index = 0
	
				
func _on_idle_timeout() -> void:
	# No key pressed for 60 seconds → switch to Top Ten scene
	if go_pass:
		go_pass = false
		visible = false  # Hide title screen
		gameManager.get_node("ColorRectBlack").visible = false
		gameManager.get_node("Background").visible = true
		var cam = get_viewport().get_camera_2d()
		cam.position.x += 570
		cam.position. y += 380
		var top_ten = preload("res://top_ten_screen.tscn").instantiate()
		top_ten.visible = false
		get_parent().add_child(top_ten)
		await get_tree().process_frame
		top_ten.visible = true
		
		
func restart_idle_timer() -> void:
	if idle_timer:
		idle_timer.start()
		
		
func _activate_cheat () -> void:
	$AudioStreamPlayer.play()
	Globals.cheated = true

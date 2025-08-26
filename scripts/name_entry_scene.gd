extends Control


var score := 0
var level := 1
var gm : Node = null

var letters := ["A", "A", "A"]
var current_index := 0
var alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")
var is_done := false
var cursor_locked := false
var input_buffer := 0 #0 for no direction

signal name_entry_done


func _ready() -> void:
	gm = get_node("/root/Main/GameManager")
	update_letters()
	$VBoxContainer/CenterContainer/Cursor.scale *= 1.5
	var content = $VBoxContainer
	await center_node(content)
	move_cursor()


func setup(player_score: int, player_level: int):
	score = player_score
	level = player_level


func _process(_delta: float) -> void:
	if is_done:
		return
	
	if Input.is_action_just_pressed("ui_up"):
		change_letter(1)
		$AudioLetterChange.pitch_scale = randf_range(0.95, 1.05)
		$AudioLetterChange.play()
	elif Input.is_action_just_pressed("ui_down"):
		change_letter(-1)
		$AudioLetterChange.pitch_scale = randf_range(0.95, 1.05)
		$AudioLetterChange.play()
	elif Input.is_action_just_pressed("ui_select"):
		submit_name()
		
	if not cursor_locked:
		if Input.is_action_just_pressed("ui_right"):  # your action name
			move_cursor_smart(1)
			$AudioMove.pitch_scale = randf_range(0.95, 1.05)
			$AudioMove.play()
		elif Input.is_action_just_pressed("ui_left"):  # your action name
			move_cursor_smart(-1)
			$AudioMove.pitch_scale = randf_range(0.95, 1.05)
			$AudioMove.play()
	else:
		# If locked, remember a single queued input
		if input_buffer == 0:  # Don’t overwrite if already queued
			if Input.is_action_just_pressed("ui_right"):
				input_buffer = 1
			elif Input.is_action_just_pressed("ui_left"):
				input_buffer = -1


func change_letter(dir: int):
	var index = alphabet.find(letters[current_index])
	index = (index + dir) % alphabet.size()
	if index < 0:
		index += alphabet.size()
	letters[current_index] = alphabet[index]
	update_letters()


func update_letters():
	$VBoxContainer/CenterContainer/HBoxContainer/Label1.text = letters[0]
	$VBoxContainer/CenterContainer/HBoxContainer/Label2.text = letters[1]
	$VBoxContainer/CenterContainer/HBoxContainer/Label3.text = letters[2]


func move_cursor():
	var label = $VBoxContainer/CenterContainer/HBoxContainer.get_child(current_index)
	var label_pos = label.global_position
	var label_size = label.size

	$VBoxContainer/CenterContainer/Cursor.global_position = label_pos + (label_size / 2)
	
	# Animate scale "pop"
	var tween := get_tree().create_tween()
	$VBoxContainer/CenterContainer/Cursor.scale = Vector2(2.0, 2.0)
	tween.tween_property($VBoxContainer/CenterContainer/Cursor, "scale", Vector2(1.5, 1.5), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)


func move_cursor_smart(direction: int):
	cursor_locked = true
	current_index = (current_index + direction + 3) % 3
	move_cursor()

	# Animate the cursor pop
	var tween := get_tree().create_tween()
	$VBoxContainer/CenterContainer/Cursor.scale = Vector2(2.5, 2.5)
	tween.tween_property($VBoxContainer/CenterContainer/Cursor, "scale", Vector2(1.5, 1.5), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	# When the tween ends, unlock and check the buffer
	await get_tree().create_timer(0.25).timeout
	cursor_locked = false

	if input_buffer != 0:
		var buffered_dir := input_buffer
		input_buffer = 0
		move_cursor_smart(buffered_dir)

func submit_name():
	$AudioFinished.play()
	is_done = true
	var name2 = "".join(letters)
	HighScoreManager.add_score(name2, gm.score, gm.level)
	while $AudioFinished.playing:
		await get_tree().process_frame
	emit_signal("name_entry_done")
	queue_free()


func center_node(node: Control) -> void:
	await get_tree().process_frame  # Ensure size is valid
	var viewport_size = get_viewport().size
	var node_size = node.size
	node.position = (Vector2(viewport_size) - node_size) * 0.5

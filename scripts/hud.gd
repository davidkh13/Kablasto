extends CanvasLayer

@onready var level_label = $"Control (For HUD)/Level_text"
@onready var timer = $"Control (For HUD)/Timer"
@onready var shield_bar = $"Control (For HUD)/ProgressBar (shields)"
@onready var score_label = $"Control (For HUD)/VBoxContainer"
@onready var player_score = $"Control (For HUD)/VBoxContainer/Label"
var player: RigidBody2D = null
@onready var gm = get_node("../")
@onready var lives_container = $"Control (For HUD)/HBoxContainer"
@onready var low_shield_sound = $AudioStreamPlayer2D
@onready var boss_bar = $"Control (For HUD)/ProgressBarBoss"
@onready var radar = $"Control (For HUD)/RadarControl"
@onready var game_over_label = $"Control (For HUD)/LabelGameOver"
@onready var gold_shield = $"Control (For HUD)/ProgressGoldShield"

var default_position_game_over: Vector2
var boss = null
var played_low_shields := false
var life_icon_scene = preload("res://lives_icon.tscn") #spaceships


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_position_game_over = game_over_label.position
	_reset()
		
		
func _reset() -> void:
	var level = get_node("../").level #gm.level
	level_label.text = "Level " + str(level)
	level_label.visible = false
	timer.timeout.connect(_on_timer_timeout)
	timer.stop()
	shield_bar.modulate.a = 0.0
	lives_container.modulate.a = 0.0
	score_label.modulate.a = 0.0
	boss_bar.modulate.a = 0.0
	radar.modulate.a = 0.0
	gold_shield.modulate.a = 0.0
	if player_score:
		player_score.text = str(gm.score)
		

func _start_ready() -> void: #game begins here
	level_label.show()
	timer.start()
		
		
func set_player(p: RigidBody2D) -> void:
	player = p
	radar.player = p
	
func show_level(level: int) -> void:
	level_label.text = "Level " + str(level)
	level_label.modulate.a = 1.0
	level_label.show()
	timer.start() #Triggers _on_timer_out()
	
	
func show_final_level() -> void:
	level_label.text = "Final Boss"
	level_label.modulate.a = 1.0
	level_label.show()
	timer.start() #Triggers _on_timer_out()
	
func show_level_bonus(level: int) -> void:
	level_label.text = "Bonus Level " + str(level)
	level_label.modulate.a = 1.0
	level_label.show()
	timer.start() #Triggers _on_timer_out()
	
func _update_lives(lives: int) -> void:
	#clear icons
	for child in lives_container.get_children():
		child.queue_free()
	#add one icon per life
	for i in range(lives):
		var icon = life_icon_scene.instantiate()
		lives_container.add_child(icon)
		icon.position = Vector2(i * 50, 20)
		

func update_score_label() -> void:
	if player_score:
		player_score.text = str(gm.score)
	

func _on_timer_timeout() -> void:
	#fade out level_label
	var tween = create_tween()
	tween.tween_property(level_label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	#fade in shield_bar
	var tween2 = create_tween()
	tween2.tween_property(shield_bar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	#fade in lives_icon
	var tween3 = create_tween()
	tween3.tween_property(lives_container, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	#fade in score box
	var tween4 = create_tween()
	tween4.tween_property(score_label, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	if boss:
		var tween5 = create_tween()
		tween5.tween_property(boss_bar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	var tween6 = create_tween()
	tween6.tween_property(radar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	if player.shield_level > 1:
		gold_shield.visible = true
		var tween7 = create_tween()
		tween7.tween_property(gold_shield, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	gm.start_level()


func _update_shield_bar(shield_value: int):
	if player.shield_level > 1:
		gold_shield.value = player.goldShields
	shield_bar.value = shield_value
	var fill_style = shield_bar.get("theme_override_styles/fill")
	if shield_value > 50:
		fill_style.bg_color = Color("00d030") #Green
		fill_style.border_color = Color("c7e230")
	elif shield_value > 25:
		fill_style.bg_color = Color("ffff00") #Yellow
		fill_style.border_color = Color("bba400")
	else:
		fill_style.bg_color = Color("ff0000") #Red
		fill_style.border_color = Color("800000")
		if not played_low_shields:
			low_shield_sound.play()
			played_low_shields = true
			
func _update_boss_bar(health_value: int):
	boss_bar.value = health_value
	var fill_style = boss_bar.get("theme_override_styles/fill")
	
	if health_value <= 25:
		fill_style.bg_color = Color("ff0059") # Boss danger red
		fill_style.border_color = Color("800040")
	
func stop_low_shield_sound() -> void:
	if low_shield_sound.playing:
		low_shield_sound.stop()
		

func assign_boss(boss_instance):
	boss = boss_instance
	

func _process(_delta: float) -> void:
	#shield_bar.value = shields
	if boss:
		_update_boss_bar(boss.life)
	if player:
		_update_shield_bar(player.shields)
		if(player.position.y < -90 && player.position.x < -50):
			shield_bar.visible = false
			lives_container.visible =  false
			gold_shield.visible = false
		else:
			shield_bar.visible = true
			lives_container.visible = true
			if player.shield_level > 1:
				gold_shield.visible = true
	
		if(player.position.y < - 50) && (player.position.x > 200) && (player.position.x < 1100):
			score_label.visible = false
		else:
			score_label.visible = true
		
	#any_enemies_on_screen()
		
func any_enemies_on_screen() -> bool:
	var camera_rect = get_camera_visible_rect()
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if camera_rect.has_point(enemy.global_position):
			#print("enemies: ", get_tree().get_nodes_in_group("Enemies").size())
			#print("on screen true")
			return true
	#print("enemies: ", get_tree().get_nodes_in_group("Enemies").size())
	#print("on screen false")
	return false
	
func get_camera_visible_rect() -> Rect2:
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_pos = get_viewport().get_camera_2d().global_position
	var half_size = viewport_size * 0.5
	return Rect2(camera_pos - half_size, viewport_size)

func show_game_over_label() -> void:
	game_over_label.visible = true
	game_over_label.modulate.a = 0.0
	
	var tween = get_tree().create_tween()
	tween.tween_property(game_over_label, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func slide_game_over_label_up() -> void:
	game_over_label.position = default_position_game_over
	var tween = get_tree().create_tween()
	
	var start_pos: Vector2 = game_over_label.position
	var end_pos: Vector2 = start_pos + Vector2(0, -240)
	
	tween.tween_property(game_over_label, "position", end_pos, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

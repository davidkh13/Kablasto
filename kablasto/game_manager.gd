extends Node2D

var level: int = 2#1
var level_director: int = 1#1 #used to direct which level we enter
var lives: int = 2
var score: int = 0
var time_left: float = 30.0
var level_active: bool = false
var first_start := true
var rock_pool: Array = []
@export var rock_pool_max := 50 #max rocks
var player
var bonus_data := []
var hud : Node = null
var boss : Node = null

@export var asteroid_scene: PackedScene
@export var player_scene: PackedScene
@export var asteroid_boss_scene : PackedScene

@export var starting_rocks: int = 1#5
@export var space_rocks: int = 1#20 # max number of rocks this level

var total_rocks_spawned: int = 0
var rocks_remaining: int = 0

@onready var bg_music := $StreamPlayerBG_Music
@onready var boss_music := $StreamPlayerBoss

func _ready() -> void:
	spawn_player()

func _die() -> void:
	lives -= 1
	if lives >= 0:
		await get_tree().create_timer(1.0).timeout
		spawn_player()
	else:
		game_over()

func start_level() -> void: #this gets called by hud
	if first_start: #to avoid repeat startup rock spawn
		first_start = false
		if level_director == 1:
			level_active = true
			#time_left = 30.0
			start_level_1()
		if level_director == 2:
			level_active = true
			time_left = 60.0
			fade_out_and_play_boss_theme()
			start_level_3()

func spawn_player() -> void:
	if player_scene:
		player = player_scene.instantiate()
		player.global_position = Vector2(640, 360)
		add_child(player)
		if player.has_node("Camera2D/HUD"):
			player.get_node("Camera2D/HUD")._update_lives(lives)
			hud = player.get_node("Camera2D/HUD")
		if hud and boss:
			hud.assign_boss(boss)
		player.player_died.connect(_die)

func start_level_1() -> void:
	if not asteroid_scene:
		return
		
	if player:
		player.hud.get_child(0).get_node("ProgressBarBoss").visible = false

	total_rocks_spawned = 0
	rocks_remaining = 0

	for i in range(starting_rocks):
		spawn_asteroid()
		
func start_level_3() -> void:
	await get_tree().create_timer(2.0).timeout
	spawn_boss(asteroid_boss_scene, get_random_position())
	var boss_bar = player.hud.get_child(0).get_node("ProgressBarBoss")
	boss_bar.visible = true
	#fade in boss bar
	var tween = create_tween()
	tween.tween_property(boss_bar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	var tween2 = create_tween()
	tween2.tween_property(boss_bar, "value", 100, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
func spawn_boss(boss_scene: PackedScene, position: Vector2) -> void:
	boss = boss_scene.instantiate()
	boss.global_position = position
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var to_center = (screen_center - boss.position).normalized()
	var angle_variation = randf_range(-0.3, 0.3)
	boss.direction = to_center.rotated(angle_variation)
	boss.game_manager = self #reference to game_manager
	add_child(boss)
	if hud:
		hud.assign_boss(boss)
	#connect boss signals
	if not boss.shake_screen.is_connected(_screen_shake):
		boss.shake_screen.connect(_screen_shake)
		
	if not boss.short_shake.is_connected(_short_shake):
		boss.short_shake.connect(_short_shake)
		
	if not boss.boss_died.is_connected(_boss_died):
		boss.boss_died.connect(_boss_died)

func spawn_asteroid() -> void:
	if total_rocks_spawned >= space_rocks:
		return

	var asteroid = _get_asteroid()
	asteroid.position = get_random_position()

	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var to_center = (screen_center - asteroid.position).normalized()
	var angle_variation = randf_range(-0.3, 0.3)
	asteroid.direction = to_center.rotated(angle_variation)

	if not asteroid.is_inside_tree():
		add_child(asteroid)

	if asteroid.has_method("reset"):
		asteroid.reset()

	asteroid.add_to_group("Enemies")
	#print("Enemies: ", get_tree().get_nodes_in_group("Enemies").size())
	asteroid.visible = true
	total_rocks_spawned += 1
	rocks_remaining += 1

	if not asteroid.rock_destroyed.is_connected(_on_rock_destroyed):
		asteroid.rock_destroyed.connect(_on_rock_destroyed)

func _on_rock_destroyed():
	rocks_remaining -= 1
	
	for i in range(2):
		if total_rocks_spawned < space_rocks:
			spawn_asteroid()

	if rocks_remaining == 0 and total_rocks_spawned >= space_rocks:
		level_active = false
		start_bonus_sequence(time_left, lives, player.shields)
		await get_tree().create_timer(5.0).timeout
		advance_to_next_level()

func advance_to_next_level():
	level += 1
	if level == 2:
		hud = get_node("Player/Camera2D/HUD")
		hud.show_level(level)
		first_start = true
		starting_rocks = 1#7
		space_rocks = 1#30
		time_left = 45.0
		
		#wait for label to vanish
		await get_tree().create_timer(2.0).timeout
		start_level()
	if level == 3:
		level_director = 2
		hud = get_node("Player/Camera2D/HUD")
		hud.show_level(level)
		first_start = true
		start_level()
	

func get_random_position() -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	match randi() % 4:
		0: return Vector2(randf_range(0, viewport_size.x), -200)
		1: return Vector2(randf_range(0, viewport_size.x), 940)
		2: return Vector2(-365, randf_range(0, viewport_size.y))
		3: return Vector2(1655, randf_range(0, viewport_size.y))
	return Vector2.ZERO

func _get_asteroid() -> Node2D:
	for rock in rock_pool:
		if not rock.visible:
			return rock
	if rock_pool.size() >= rock_pool_max:
		return
	var new_rock = asteroid_scene.instantiate()
	new_rock.visible = false
	rock_pool.append(new_rock)
	add_child(new_rock)
	return new_rock

func _process(delta: float) -> void:
	if level_active:
		time_left = max(time_left - delta, 0.0)
		#print(time_left)
	#position the boss bar
	if player and boss:
		if player.position.y > 820:
			player.hud.get_child(0).get_node("ProgressBarBoss").move_up()
		else:
			player.hud.get_child(0).get_node("ProgressBarBoss").move_down()

func game_over() -> void:
	print("Game Over")

#The popup bonus functions
func calculate_time_bonus(time_left: float) -> int:
	return int(time_left * 15.0) #faster = more points
	
func calculate_lives_bonus(lives_left: int) -> int:
	return lives_left * 1000
	
func calculate_shields_bonus(shields_left: int) -> int:
	return shields_left * 50
	
func show_bonuses() -> void:
	var BonusPopupScene = preload("res://bonus_popup.tscn")
	for bonus in bonus_data:
		if bonus["value"] > 0:
			var popup = BonusPopupScene.instantiate() as BonusPopup
			get_tree().current_scene.add_child(popup)
			popup.set_bonus(bonus["value"], bonus["name"])
			score += bonus["value"]
			hud.update_score_label()
			await popup.popup_complete
	
func start_bonus_sequence(time_left: float, lives_left: int, shields_left: int) -> void:
	bonus_data = [
		{"name": "Time", "value": calculate_time_bonus(time_left)},
		{"name": "Lives", "value": calculate_lives_bonus(lives_left)},
		{"name": "Shields", "value": calculate_shields_bonus(shields_left)},
	]
	await show_bonuses()
	
func kill_all_rocks() -> void:
	for rock in rock_pool:
		if rock.visible:
			rock._take_damage(3)
	player.hud.get_child(0).get_node("ProgressBarBoss").visible = false

	
func fade_out_and_play_boss_theme() -> void:
	var fade_time = 2.0  # seconds for fade out
	var steps = 20
	var delay = fade_time / steps

	for i in range(steps):
		bg_music.volume_db = lerp(0, -80, float(i) / steps)  # fade volume to silence
		await get_tree().create_timer(delay).timeout

	bg_music.stop()
	boss_music.play()
	
func _screen_shake() -> void:
	var cam = player.get_node("Camera2D")
	cam.shake(4.0, 1.0)
	
func _short_shake() -> void:
	var cam = player.get_node("Camera2D")
	cam.shake(4.0, 10.0)

func _boss_died() -> void:
	level_active = false
	start_bonus_sequence(time_left, lives, player.shields)
	await get_tree().create_timer(5.0).timeout
	advance_to_next_level()

extends Node2D

var level: int = 1
var level_director: int = 1 #used to direct which level we enter
var lives: int = 2
var score: int = 0
var player_weapon_level: int = 1
var player_shield_level: int = 1
var time_left: float = 30.0
var level_active: bool = false
var first_start := true
var rock_pool: Array = []
var eyeball_pool: Array = []
var exploderBot_pool: Array = []
var miniship_pool: Array = []
var mothership_pool: Array = []
var active_exploderBots: int = 0
var bonus_goody_queue: Array = []
var bonus_sequence_running := false
@export var rock_pool_max := 50 #max rocks
@export var eyeball_pool_max := 30
@export var exploderBot_pool_max := 25
@export var miniship_pool_max := 30
@export var mothership_pool_max := 25
var player
var bonus_data := []
@onready var hud : Node = $HUD
var boss : Node = null
var highscore_scene : Node = null
var name_entry_scene : Node = null
var level_advance_requested := false
var startScreen : Node = null


@export var asteroid_scene: PackedScene
@export var player_scene: PackedScene
@export var asteroid_boss_scene : PackedScene
@export var eyeball_scene: PackedScene
@export var eyeball_boss_scene: PackedScene
@export var formation_scene: PackedScene
@export var charger_boss_scene: PackedScene
@export var exploderBot_scene: PackedScene
@export var exploderBoss_scene: PackedScene
@export var miniship_scene: PackedScene
@export var mothership_scene: PackedScene
@export var mothershipBoss_scene: PackedScene
@export var finalBoss_scene: PackedScene

@export var starting_rocks: int = 5
@export var space_rocks: int = 20 # max number of rocks this level
@export var starting_eyeballs: int = 3
@export var space_eyeballs: int = 15 # max for the level
@export var starting_exploderBots: int = 1
@export var space_exploderBots: int = 10 # max for the level
@export var starting_motherships: int = 3
@export var space_motherships: int = 10 # max for the level

var total_rocks_spawned: int = 0
var total_eyeballs_spawned: int = 0
var total_exploderBots_spawned: int = 0
var total_motherships_spawned: int = 0
var enemies_killed: int = 0 #used to spawn formations
var goodie_counts := {} #a blank dictionary

@onready var bg_music := $StreamPlayerBG_Music
@onready var boss_music := $StreamPlayerBoss
@onready var waltz := $StreamPlayerWaltz
@onready var final_boss_music := $finalboss
@onready var end_credits_music := $end_credits_audio
@onready var fanfare_music := $fanfare

const RADAR_CLEANUP_RADIUS := 2000.0

func request_level_advance():
	
	if level_advance_requested:
		print(">>> LEVEL ADVANCE ALREADY IN PROGRESS <<<")
		return
	level_advance_requested = true
	await get_tree().process_frame
	advance_to_next_level()


func _ready() -> void:
	await get_tree().create_timer(2.0).timeout  # wait 2 seconds
	
	fade_swap($TextureRectLogo, $TextureRectGODOT)
	# Wait another 2 seconds
	await get_tree().create_timer(3.0).timeout
	var start_scene = preload("res://start_screen.tscn").instantiate()
	get_parent().add_child(start_scene)
	fade_swap($TextureRectGODOT, start_scene)
	
			
func fade_swap(out_node: TextureRect, in_node: TextureRect, fade_time: float = 1.0) -> void:
	# Make sure the in_node is visible and transparent
	in_node.visible = true
	in_node.modulate.a = 0.0
	
	# Fade out the first node
	var tween = create_tween()
	tween.tween_property(out_node, "modulate:a", 0.0, fade_time)
	# Fade in the second node
	var tween2 = create_tween()
	tween2.tween_property(in_node, "modulate:a", 1.0, fade_time)

func play_ball(start_screen: Node) -> void: #the game starts here
	var tween = create_tween()
	tween.tween_property(start_screen, "modulate:a", 0.0, 1.0)
	await get_tree().create_timer(2.0).timeout  # wait 2 seconds
	start_screen.visible = false
	reset_game()
	spawn_player()
	hud._start_ready()
	$ColorRectBlack.visible = false
	$Background.visible = true
	fade_out_and_play_new_theme(waltz, bg_music)
	
	
func reset_game() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.queue_free()
	level = 1
	hud._reset()
	hud.level_label.modulate.a = 1.0
	hud.level_label.visible = true
	hud.game_over_label.position = Vector2(499.5, 336.0)
	level_director = 1
	lives = 2
	score = 0
	hud.update_score_label()
	player_weapon_level = 1
	player_shield_level = 1
	time_left = 30.0
	level_active = false
	first_start = true
	rock_pool.clear()
	eyeball_pool.clear()
	exploderBot_pool.clear()
	miniship_pool.clear()
	mothership_pool.clear()
	active_exploderBots = 0
	bonus_goody_queue.clear()
	bonus_sequence_running = false
	if Globals.cheated == true:
		lives += 8
		player_weapon_level += 2
		player_shield_level += 2
		Globals.cheated = false
	
	
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
		level_active = true
		level_advance_requested = false
		bonus_sequence_running = false
		match level_director:
			1:
				start_level_1()
			2: #boss rock
				time_left = 60.0
				fade_out_and_play_new_theme(bg_music, boss_music)
				start_level_3()
			3: #bonus level
				time_left = 60.0
				fade_out_and_play_new_theme(boss_music, bg_music)
				start_level_4()
			4: #eyeballs
				time_left = 60.0
				start_level_5()
			5: #boss eyeball
				time_left = 60.0
				fade_out_and_play_new_theme(bg_music, boss_music)
				start_level_6()
			6: #formations
				time_left = 120.0
				start_level_9()
			7: #boss charger
				time_left = 90.0
				fade_out_and_play_new_theme(bg_music, boss_music)
				start_level_11()
			8: #exploderBots
				time_left = 120.0
				start_level_13()
			9: #boss exploder
				time_left = 90.0
				fade_out_and_play_new_theme(bg_music, boss_music)
				start_level_15()
			10: #motherships
				time_left = 120.0
				start_level_17()
			11: #boss mothership
				time_left = 90.0
				fade_out_and_play_new_theme(bg_music, boss_music)
				start_level_19()
			12: #final boss
				time_left = 160.0
				fade_out_and_play_new_theme(boss_music, final_boss_music)
				start_level_20()
			13: #end credits
				fade_out_and_play_new_theme(final_boss_music, fanfare_music)
				# Wait for the fanfare to finish
				await get_tree().create_timer(fanfare_music.stream.get_length() + 1.0).timeout
				$endWords.play()
				await get_tree().create_timer($endWords.stream.get_length() + 1.0).timeout
				roll_credits()
				

func roll_credits() -> void:
	Globals.player.player_has_control = false
	Globals.player.get_node("ThrustParticles").player_has_control = false
	Globals.player.exit_to_left()
	hud.get_child(0).visible = false
	hud.get_child(0).get_node("ProgressBar (shields)").visible = false
	hud.get_child(0).get_node("ProgressBarBoss").visible = false
		
	await get_tree().create_timer(2.0).timeout
	end_credits_music.play()
	$Credits.start_scroll()
	await end_credits_music.finished
	game_over()
	
func spawn_player() -> void:
	if player_scene:
		player = player_scene.instantiate()
		player.global_position = Vector2(640, 360)
		add_child(player)
		hud.set_player(player)
		hud._update_lives(lives)
		hud.played_low_shields = false
		
		if hud and boss:
			hud.assign_boss(boss)
		player.player_died.connect(_die)
		

func start_level_1() -> void:
	if not asteroid_scene:
		return
		
	if player:
		hud.get_child(0).get_node("ProgressBarBoss").visible = false

	total_rocks_spawned = 0

	for i in range(starting_rocks):
		spawn_asteroid()
		

func prepare_bonus_goodie_list(total_goodies : int):
	bonus_goody_queue.clear()
	
	var half := total_goodies / 2
	for i in range(half):
		bonus_goody_queue.append("shield")
		bonus_goody_queue.append("weapon")
		
	bonus_goody_queue.shuffle()
	
	
func register_goodie(goodie_type: String) -> void:
	if not goodie_counts.has(goodie_type):
		goodie_counts[goodie_type] = 0
	goodie_counts[goodie_type] += 1
	
	
func start_level_9() -> void: #formations
	await get_tree().create_timer(2.0).timeout
	
	if not asteroid_scene:
		return
		
	if not eyeball_scene:
		return
		
	if not formation_scene: #these get spawned when enemies are killed
		return
		
	total_rocks_spawned = 0
	total_eyeballs_spawned = 0
	enemies_killed = 0
	
	for i in range(starting_rocks):
		spawn_asteroid()
	for i in range(starting_eyeballs):
		spawn_eyeball()
	

func start_level_20() -> void:
	await get_tree().create_timer(2.0).timeout
	spawn_boss(finalBoss_scene, Vector2(1900, get_viewport().size.y/2))
	var boss_bar = player.hud.get_child(0).get_node("ProgressBarBoss")
	boss_bar.visible = true
	#fade in boss bar
	var tween = create_tween()
	tween.tween_property(boss_bar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	var tween2 = create_tween()
	tween2.tween_property(boss_bar, "value", 100, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	

func start_level_19() -> void:
	await get_tree().create_timer(2.0).timeout
	spawn_boss(mothershipBoss_scene, get_random_position())
	var boss_bar = player.hud.get_child(0).get_node("ProgressBarBoss")
	boss_bar.visible = true
	#fade in boss bar
	var tween = create_tween()
	tween.tween_property(boss_bar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	var tween2 = create_tween()
	tween2.tween_property(boss_bar, "value", 100, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	


func start_level_15() -> void: #exploderBoss
	await get_tree().create_timer(2.0).timeout
	spawn_boss(exploderBoss_scene, get_random_position())
	var boss_bar = player.hud.get_child(0).get_node("ProgressBarBoss")
	boss_bar.visible = true
	#fade in boss bar
	var tween = create_tween()
	tween.tween_property(boss_bar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	var tween2 = create_tween()
	tween2.tween_property(boss_bar, "value", 100, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	
func start_level_17() -> void:
	await get_tree().create_timer(2.0).timeout
	
	if not asteroid_scene:
		return
		
	if not eyeball_scene:
		return
		
	if not miniship_scene:
		return
		
	if not formation_scene: #these get spawned when enemies are killed
		return
		
	total_rocks_spawned = 0
	total_eyeballs_spawned = 0
	total_motherships_spawned = 0
	enemies_killed = 0
	
	for i in range(starting_rocks):
		spawn_asteroid()
	for i in range(starting_eyeballs):
		spawn_eyeball()
	for i in range(starting_motherships):
		spawn_mothership()



func start_level_13() -> void:
	await get_tree().create_timer(2.0).timeout
	
	if not asteroid_scene:
		return
		
	if not eyeball_scene:
		return
		
	if not exploderBot_scene:
		return
		
	if not formation_scene: #these get spawned when enemies are killed
		return
		
	total_rocks_spawned = 0
	total_eyeballs_spawned = 0
	total_exploderBots_spawned = 0
	enemies_killed = 0
	
	for i in range(starting_rocks):
		spawn_asteroid()
	for i in range(starting_eyeballs):
		spawn_eyeball()
	for i in range(starting_exploderBots):
		spawn_exploderBot()

	
func start_level_11() -> void:
	await get_tree().create_timer(2.0).timeout
	spawn_boss(charger_boss_scene, get_random_position())
	var boss_bar = player.hud.get_child(0).get_node("ProgressBarBoss")
	boss_bar.visible = true
	#fade in boss bar
	var tween = create_tween()
	tween.tween_property(boss_bar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	var tween2 = create_tween()
	tween2.tween_property(boss_bar, "value", 100, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	


func start_level_6() -> void: #boss eyeball
	await get_tree().create_timer(2.0).timeout
	spawn_boss(eyeball_boss_scene, get_random_position())
	var boss_bar = player.hud.get_child(0).get_node("ProgressBarBoss")
	boss_bar.visible = true
	#fade in boss bar
	var tween = create_tween()
	tween.tween_property(boss_bar, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	var tween2 = create_tween()
	tween2.tween_property(boss_bar, "value", 100, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	


func start_level_5():
	await get_tree().create_timer(2.0).timeout
	
	if not asteroid_scene:
		return
		
	if not eyeball_scene:
		return
		
	total_rocks_spawned = 0
	total_eyeballs_spawned = 0
	
	for i in range(starting_rocks):
		spawn_asteroid()
	for i in range(starting_eyeballs):
		spawn_eyeball()


func start_level_4() -> void: #bonus level
	clear_enemies()
	bonus_goody_queue.clear()
	if bonus_goody_queue.is_empty():
		prepare_bonus_goodie_list(40)  # fallback or error guard
	var bonus_duration := 15.0
	var spawn_interval := bonus_duration / float(bonus_goody_queue.size())

	# Spawn goodies repeatedly
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout", Callable(self, "spawn_goody"))
	add_child(spawn_timer)
	
	# Timer to end bonus round
	await get_tree().create_timer(bonus_duration).timeout
	spawn_timer.stop()
	spawn_timer.queue_free()
	
	await wait_until_all_goodies_gone()
	evaluate_bonus_results()

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


func spawn_exploderBot() -> void:
	if total_exploderBots_spawned >= space_exploderBots:
		return
		
	var exploderBot = _get_exploderBot()
	exploderBot.position = get_random_position()
	
	exploderBot.direction = (Globals.player.global_position - exploderBot.global_position).normalized()
	
	if not exploderBot.is_inside_tree():
		add_child(exploderBot)

	if exploderBot.has_method("reset"):
		exploderBot.reset()
		
	exploderBot.add_to_group("Enemies")
	active_exploderBots += 1
	
	exploderBot.visible = true
	total_exploderBots_spawned += 1
	
	if not exploderBot.exploderBot_destroyed.is_connected(_on_exploderBot_destroyed):
		exploderBot.exploderBot_destroyed.connect(_on_exploderBot_destroyed)
	


func spawn_formation(position: Vector2):
	var formation = formation_scene.instantiate()
	formation.global_position = position
	if not formation.formation_destroyed.is_connected(_on_formation_destroyed):
		formation.formation_destroyed.connect(_on_formation_destroyed)
	add_child(formation)
	$formationApproach.play()
	

func _on_formation_destroyed() -> void:
	_on_enemy_destroyed()
	
	var enemies_left := get_tree().get_nodes_in_group("Enemies").filter(func(e): return e.visible)
	
	if enemies_left.is_empty():
		if level_active == false:
			return
		level_active = false
		start_bonus_sequence(time_left, lives, player.shields)
		await get_tree().create_timer(5.0).timeout
		request_level_advance()


func spawn_mothership() -> void:
	if total_motherships_spawned >= space_motherships:
		return
	
	var mothership = _get_mothership()
	mothership.position = get_random_position()

	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var to_center = (screen_center - mothership.position).normalized()
	var angle_variation = randf_range(-0.3, 0.3)
	mothership.direction = to_center.rotated(angle_variation)

	if not mothership.is_inside_tree():
		add_child(mothership)

	if mothership.has_method("reset"):
		mothership.reset()

	mothership.add_to_group("Enemies")
	mothership.game_manager = self
	
	mothership.visible = true
	mothership.shoot_timer.start()
	total_motherships_spawned += 1

	if not mothership.mothership_destroyed.is_connected(_on_mothership_destroyed):
		mothership.mothership_destroyed.connect(_on_mothership_destroyed)
	

func spawn_eyeball() -> void:
	if total_eyeballs_spawned >= space_eyeballs:
		return
	
	var eyeball = _get_eyeball()
	eyeball.position = get_random_position()

	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var to_center = (screen_center - eyeball.position).normalized()
	var angle_variation = randf_range(-0.3, 0.3)
	eyeball.direction = to_center.rotated(angle_variation)

	if not eyeball.is_inside_tree():
		add_child(eyeball)

	if eyeball.has_method("reset"):
		eyeball.reset()

	eyeball.add_to_group("Enemies")
	
	eyeball.visible = true
	eyeball.shoot_timer.start()
	total_eyeballs_spawned += 1

	if not eyeball.eyeball_destroyed.is_connected(_on_eyeball_destroyed):
		eyeball.eyeball_destroyed.connect(_on_eyeball_destroyed)
	

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
	
	asteroid.visible = true
	total_rocks_spawned += 1

	if not asteroid.rock_destroyed.is_connected(_on_rock_destroyed):
		asteroid.rock_destroyed.connect(_on_rock_destroyed)


func _on_enemy_destroyed(): #for timing when to spawn formation
	if level != 9 and level != 10:
		return
		
	enemies_killed += 1

	match enemies_killed:
		3:
			spawn_formation(get_random_position())
		9:
			spawn_formation(get_random_position())
		15:
			spawn_formation(get_random_position())


func _on_miniship_destroyed():
	await get_tree().process_frame  # Wait a frame so freed rocks are gone
	
	_on_enemy_destroyed()
	
	var enemies_left := get_tree().get_nodes_in_group("Enemies").filter(func(e): return e.visible)
	if enemies_left.is_empty():
		if level_active == false:
			return
		level_active = false
		start_bonus_sequence(time_left, lives, player.shields)
		await get_tree().create_timer(5.0).timeout
		request_level_advance()


func _on_mothership_destroyed():
	if level < 19:
		for i in range(2):
				if total_motherships_spawned < space_motherships:
					spawn_mothership()
			
	await get_tree().process_frame  # Wait a frame so freed rocks are gone
	
	_on_enemy_destroyed()
	
	var enemies_left := get_tree().get_nodes_in_group("Enemies").filter(func(e): return e.visible)
	if enemies_left.is_empty():
		if level_active == false:
			return
		level_active = false
		start_bonus_sequence(time_left, lives, player.shields)
		await get_tree().create_timer(5.0).timeout
		request_level_advance()


func _on_exploderBot_destroyed():
	active_exploderBots -= 1
	
	if active_exploderBots == 0:
		for i in range(2):
			if total_exploderBots_spawned < space_exploderBots:
				spawn_exploderBot()
			
	await get_tree().process_frame  # Wait a frame so freed rocks are gone
	
	_on_enemy_destroyed()
	
	var enemies_left := get_tree().get_nodes_in_group("Enemies").filter(func(e): return e.visible)
	if enemies_left.is_empty() and total_exploderBots_spawned >= space_exploderBots:
		if level_active == false:
			return
		level_active = false
		start_bonus_sequence(time_left, lives, player.shields)
		await get_tree().create_timer(5.0).timeout
		request_level_advance()


func _on_eyeball_destroyed():
	for i in range(2):
		if total_eyeballs_spawned < space_eyeballs:
			spawn_eyeball()
	
	await get_tree().process_frame  # Wait a frame so freed rocks are gone
	
	_on_enemy_destroyed()
	
	var enemies_left := get_tree().get_nodes_in_group("Enemies").filter(func(e): return e.visible)
	if enemies_left.is_empty():
		if level_active == false:
			return
		level_active = false
		start_bonus_sequence(time_left, lives, player.shields)
		await get_tree().create_timer(5.0).timeout
		request_level_advance()


func _on_rock_destroyed():
	for i in range(2):
		if total_rocks_spawned < space_rocks:
			spawn_asteroid()
	
	await get_tree().process_frame  # Wait a frame so freed rocks are gone
		
	_on_enemy_destroyed()
		
	var enemies_left := get_tree().get_nodes_in_group("Enemies").filter(func(e): return e.visible)
	print(enemies_left.size())
	if enemies_left.size() == 1:
		for enemy in enemies_left:
			print("Enemy still active:", enemy.name, "visible:", enemy.visible, "pos:", enemy.global_position)
	if enemies_left.is_empty():
		if level_active == false:
			return
		level_active = false
		start_bonus_sequence(time_left, lives, player.shields)
		await get_tree().create_timer(5.0).timeout
		request_level_advance()

func advance_to_next_level():
		
	level += 1
	
	match level:
		2:
			hud.show_level(level)
			first_start = true
			starting_rocks = 7
			space_rocks = 30
			time_left = 45.0
		
			#wait for label to vanish
			await get_tree().create_timer(2.0).timeout
			start_level()
		3: #boss rock
			level_director = 2
			hud.show_level(level)
			first_start = true
			start_level()
		4: #bonus level
			level_director = 3
			hud.show_level_bonus(level)
			first_start = true
			start_level()
		5: #first eyeball round
			level_director = 4
			hud.show_level(level)
			first_start = true
			starting_rocks = 5
			space_rocks = 20
			starting_eyeballs = 3
			space_eyeballs = 15
			start_level()
		6:
			level_director = 4
			hud.show_level(level)
			first_start = true
			starting_rocks = 7
			space_rocks = 25
			starting_eyeballs = 5
			space_eyeballs = 20
			start_level()
		7: #boss eyeball
			level_director = 5
			hud.show_level(level)
			first_start = true
			start_level()
		8: #bonus level
			level_director = 3
			hud.show_level_bonus(level)
			first_start = true
			start_level()
		9: #formation enemies
			level_director = 6
			hud.show_level(level)
			first_start = true
			starting_rocks = 5
			space_rocks = 15
			starting_eyeballs = 3
			space_eyeballs = 10
			start_level()
		10: #formation enemies
			level_director = 6
			hud.show_level(level)
			first_start = true
			starting_rocks = 5
			space_rocks = 20
			starting_eyeballs = 3
			space_eyeballs = 15
			start_level()
		11: #boss charger
			level_director = 7
			hud.show_level(level)
			first_start = true
			start_level()
		12: #bonus level
			level_director = 3
			hud.show_level_bonus(level)
			first_start = true
			start_level()
		13: #exploderBots
			level_director = 8
			hud.show_level(level)
			first_start = true
			starting_rocks = 5
			space_rocks = 15
			starting_eyeballs = 3
			space_eyeballs = 10
			starting_exploderBots = 1
			space_exploderBots = 14
			start_level()
		14: #exploderBots
			level_director = 8
			hud.show_level(level)
			first_start = true
			starting_rocks = 7
			space_rocks = 20
			starting_eyeballs = 5
			space_eyeballs = 15
			starting_exploderBots = 2
			space_exploderBots = 20
			start_level()
		15: #boss exploder
			level_director = 9
			hud.show_level(level)
			first_start = true
			start_level()
		16: #bonus level
			level_director = 3
			hud.show_level_bonus(level)
			first_start = true
			start_level()
		17: #motherships
			level_director = 10
			hud.show_level(level)
			first_start = true
			starting_rocks = 5
			space_rocks = 10
			starting_eyeballs = 3
			space_eyeballs = 6
			starting_motherships = 3
			space_motherships = 10
			start_level()
		18: #motherships
			level_director = 10
			hud.show_level(level)
			first_start = true
			starting_rocks = 5
			space_rocks = 15
			starting_eyeballs = 3
			space_eyeballs = 9
			starting_motherships = 3
			space_motherships = 12
			start_level()
		19: #boss mothership
			level_director = 11
			hud.show_level(level)
			first_start = true
			start_level()
		20: #final boss
			level_director = 12
			hud.show_final_level()
			first_start = true
			start_level()
		21: #end credits
			level_director = 13
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


func _get_mothership() -> Node2D:
	for mothership in mothership_pool:
		if not mothership.visible:
			return mothership
	if mothership_pool.size() >= mothership_pool_max:
		return
	var new_mothership = mothership_scene.instantiate()
	new_mothership.game_manager = self
	new_mothership.visible = false
	mothership_pool.append(new_mothership)
	add_child(new_mothership)
	return new_mothership


func _get_miniship() -> Node2D:
	for miniship in miniship_pool:
		if not miniship.visible:
			return miniship
	if miniship_pool.size() >= miniship_pool_max:
		return
	var new_miniship = miniship_scene.instantiate()
	new_miniship.visible = false
	miniship_pool.append(new_miniship)
	add_child(new_miniship)
	return new_miniship


func _get_exploderBot() -> Node2D:
	for exploderBot in exploderBot_pool:
		if not exploderBot.visible:
			return exploderBot
	if exploderBot_pool.size() >= exploderBot_pool_max:
		return
	var new_exploderBot = exploderBot_scene.instantiate()
	new_exploderBot.visible = false
	exploderBot_pool.append(new_exploderBot)
	add_child(new_exploderBot)
	return new_exploderBot


func _get_eyeball() -> Node2D:
	for eyeball in eyeball_pool:
		if not eyeball.visible:
			return eyeball
	if eyeball_pool.size() >= eyeball_pool_max:
		return
	var new_eyeball = eyeball_scene.instantiate()
	new_eyeball.visible = false
	eyeball_pool.append(new_eyeball)
	add_child(new_eyeball)
	return new_eyeball


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
			hud.get_child(0).get_node("ProgressBarBoss").move_up()
		else:
			hud.get_child(0).get_node("ProgressBarBoss").move_down()
	
	cleanup_stray_enemies()
	
func game_over() -> void:
	#print(hud)
	hud.get_child(0).get_node("ProgressBar (shields)").visible = false
	hud.get_child(0).get_node("ProgressBarBoss").visible = false
	
	if bg_music.is_playing():
		fade_out_and_play_new_theme(bg_music, waltz)
	elif boss_music.is_playing():
		fade_out_and_play_new_theme(boss_music, waltz)
	elif final_boss_music.is_playing():
		fade_out_and_play_new_theme(final_boss_music, waltz)
	else:
		waltz.stop()
		waltz.volume_db = -3.0
		waltz.play()
		
	await get_tree().create_timer(0.5).timeout
	
	#Qualify High Score
	if HighScoreManager.qualifies_for_highscore(score):
		name_entry_scene = preload("res://name_entry_scene.tscn").instantiate()
		await get_tree().create_timer(3.0).timeout
		
		$HUD.add_child(name_entry_scene)
		name_entry_scene.visible = true
		var tweenA = get_tree().create_tween()
		tweenA.tween_property(name_entry_scene, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Wait until the name entry scene emits its completion signal
		await name_entry_scene.name_entry_done
	
	hud.get_child(0).visible = true
	hud.get_child(0).get_node("ProgressBar (shields)").visible = false
	hud.get_child(0).get_node("ProgressBarBoss").visible = false
	hud.get_child(0).get_node("ProgressGoldShield").visible = false
	hud.get_child(0).get_node("Level_text").visible = false
	hud.get_child(0).get_node("HBoxContainer").visible = false
	hud.get_child(0).get_node("VBoxContainer").visible = false
		
	hud.show_game_over_label()
	
	# Load the Top Ten scene
	highscore_scene = preload("res://top_ten_screen.tscn").instantiate()
	await get_tree().create_timer(5.0).timeout
	hud.slide_game_over_label_up()
	# Optionally pass the score to it if you have a method for that
	if highscore_scene.has_method("set_player_score"):
		highscore_scene.set_player_score(score)
	
	# Add to the current scene tree to display it
	$HUD.add_child(highscore_scene)
	highscore_scene.visible = true
	highscore_scene.modulate.a = 0.0
	
	var tween = get_tree().create_tween()
	tween.tween_property(highscore_scene, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	
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
			$HUD.add_child(popup)
			popup.set_bonus(bonus["value"], bonus["name"])
			score += bonus["value"]
			hud.update_score_label()
			await popup.popup_complete
	
func start_bonus_sequence(time_left: float, lives_left: int, shields_left: int) -> void:
	if bonus_sequence_running:
		return
	bonus_sequence_running = true
	bonus_data = [
		{"name": "Time", "value": calculate_time_bonus(time_left)},
		{"name": "Lives", "value": calculate_lives_bonus(lives_left)},
		{"name": "Shields", "value": calculate_shields_bonus(shields_left)},
	]
	await show_bonuses()
	
func kill_all_rocks() -> void:
	for rock in rock_pool:
		if rock.rock_destroyed.is_connected(_on_rock_destroyed):
			rock.rock_destroyed.disconnect(_on_rock_destroyed)
		if rock.visible:
			rock._take_damage(3)
	for mothership in mothership_pool:
		if mothership.mothership_destroyed.is_connected(_on_mothership_destroyed):
			mothership.mothership_destroyed.disconnect(_on_mothership_destroyed)
		if mothership.visible:
			mothership._take_damage(9)
	hud.get_child(0).get_node("ProgressBarBoss").visible = false
	


func fade_out_and_play_new_theme(out_theme: Node, in_theme: Node) -> void:
	var fade_time = 2.0  # seconds for fade out
	var steps = 20
	var delay = fade_time / steps

	for i in range(steps):
		out_theme.volume_db = lerp(0, -80, float(i) / steps)  # fade volume to silence
		await get_tree().create_timer(delay).timeout

	out_theme.stop()
	in_theme.volume_db = -3.0
	in_theme.play()
	
func _screen_shake() -> void:
	var cam = player.get_node("Camera2D")
	cam.shake(4.0, 1.0)
	
func _short_shake() -> void:
	var cam = player.get_node("Camera2D")
	cam.shake(4.0, 10.0)

func _boss_died() -> void:
	if level_active == false:
		return
	level_active = false
	start_bonus_sequence(time_left, lives, player.shields)
	await get_tree().create_timer(5.0).timeout
	
	request_level_advance()


func spawn_goody() -> void:
	if bonus_goody_queue.is_empty():
		return #Nothing left to spawn
		
	var type = bonus_goody_queue.pop_front()
	
	var g = preload("res://goody.tscn").instantiate()
	g.goodie_type = type
	g.gm = self
	g.position = get_random_position()
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var to_center = (screen_center - g.position).normalized()
	var angle_variation = randf_range(-0.3, 0.3)
	g.direction = to_center.rotated(angle_variation)
	add_child(g)
	
	
func wait_until_all_goodies_gone() -> void:
	while true:
		var active_goodies := get_tree().get_nodes_in_group("goodies")
		if active_goodies.is_empty():
			break
		await get_tree().process_frame  # Wait 1 frame before checking again
	
	
func evaluate_bonus_results():
	var max_count := 0
	var most_collected_type := ""
	
	for type in goodie_counts.keys():
		var count = goodie_counts[type]
		if count > max_count:
			max_count = count
			most_collected_type = type
	
	print("Most collected type:", most_collected_type, "with", max_count, "collected.")
	print(goodie_counts)
	# Optional: award player based on that type
	match most_collected_type:
		"weapon":
			grant_weapon_upgrade()
		"shield":
			grant_shield_upgrade()
		_:
			request_level_advance()


func grant_weapon_upgrade() -> void:
	player_weapon_level += 1
	if player:
		player.weapon_level = player_weapon_level
		if player_weapon_level > 3:
			lives += 1
			player.hud._update_lives(lives)
	$weaponUpgrade.play()
	await $weaponUpgrade.finished
	request_level_advance()
	
	
func grant_shield_upgrade() -> void:
	player_shield_level += 1
	if player:
		player.shield_level = player_shield_level
		player.shields = 100
		player.goldShields = 100
		player.hud.gold_shield.value = player.goldShields
		player.update_smoke_emit()
		if player_shield_level > 2:
			lives += 1
			player.hud._update_lives(lives)
	$shieldUpgrade.play()
	await $shieldUpgrade.finished
	request_level_advance()


func clear_enemies():
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.queue_free()
		
		
func cleanup_stray_enemies():
	if not Globals.player:
		return
	
	var player_pos = Globals.player.global_position
	var cleanup_radius_sq = RADAR_CLEANUP_RADIUS * RADAR_CLEANUP_RADIUS

	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue

		var to_player = player_pos - enemy.global_position
		if to_player.length_squared() > cleanup_radius_sq:
			enemy._take_damage(999)
		

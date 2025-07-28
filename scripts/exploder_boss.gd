extends RigidBody2D

@export var exploderBot_size := Vector2(.75, .75)
@export var direction: Vector2 = Vector2.ZERO
@export var speed: float = 100.0
@export var tracking_speed: float = 50.0
@export var turn_speed: float = 50.0
@export var shot_delay :float = 2.5
var life := 100
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")
var game_manager
var shoot_timer := Timer.new()
var is_dying := false
@onready var rocks_node = $rocks

@export var explosion_scene: PackedScene
@export var radial_glow_scene: PackedScene
@export var exploderBot_scene: PackedScene

signal shake_screen
signal short_shake
signal boss_died



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Enemies")
	$Sprite2D.scale = exploderBot_size
	$CollisionPolygon2D.scale = exploderBot_size
	$"Area2D/CollisionPolygon2D".scale = exploderBot_size
	
	add_child(shoot_timer)
	shoot_timer.wait_time = shot_delay
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(self._on_shoot_timer_timeout)
	shoot_timer.start()
	
	if rocks_node and rocks_node.get_parent() == self:
		remove_child(rocks_node)
		get_parent().add_child(rocks_node)
		# Optionally set position/rotation to keep it visually correct
		rocks_node.global_position = global_position
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_instance_valid(rocks_node):
		rocks_node.global_position = global_position
		
	if is_dying:
		return
		
	if Globals.player:
		var to_player = (Globals.player.global_position - global_position).normalized()
		var target_rot = to_player.angle() + PI / 2.0
		rotation = lerp_angle(rotation, target_rot, turn_speed * delta)

		# Move slowly forward
		linear_velocity = Vector2.UP.rotated(rotation) * tracking_speed

		var angle_diff = abs(short_angle_dist(rotation, target_rot))
		var distance = global_position.distance_to(Globals.player.global_position)
		if angle_diff < deg_to_rad(5):
			linear_velocity = to_player * speed
		
func lock_into_gameplay() -> void:
	collision_mask = 1 | 2
	
	
func short_angle_dist(a: float, b: float) -> float:
	return atan2(sin(b - a), cos(b - a))
	
	
func reset() -> void:
	visible = true
	$Sprite2D.visible = true
	call_deferred("_enable_collision")
	set_process(true)
	life = 5
	

func _take_damage(amount: int) -> void:
	if life <= 0:
		return
	life -= amount
	var sound_player = AudioStreamPlayer2D.new()
	sound_player.stream = SOUND_BULLET_HIT
	add_child(sound_player)
	sound_player.play()
	sound_player.finished.connect(func() -> void: sound_player.queue_free())
	if life <= 0:
		shoot_timer.stop()
		is_dying = true
		die()
		rocks_node.die()
		return
		
func die() -> void:
	remove_from_group("Enemies")
	emit_signal("shake_screen") #received by gameManager
	var boss_global_position = global_position
	_glow_effect(boss_global_position)
	$CollisionPolygon2D.call_deferred("set_disabled", true)
	$CollisionPolygon2D.global_position.y = -10000
	$"Area2D/CollisionPolygon2D".call_deferred("set_disabled", true)
	$"Area2D/CollisionPolygon2D".global_position.y = -10000
	#freeze sprite movement
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_deferred("freeze", true)
	
	if game_manager:
		game_manager.kill_all_rocks()
		await get_tree().create_timer(0.05).timeout
	
	for i in range(20):
		$Sprite2D.visible = (i % 2 == 0)
				
		var explosion = explosion_scene.instantiate()
		var offset = Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
		var pos = boss_global_position + offset
		explosion.global_position = pos
		get_tree().current_scene.add_child(explosion)
		
		$ExplosionSoundPool.play_sound(pos)
		await get_tree().create_timer(0.20).timeout
		
	await get_tree().create_timer(2.0).timeout
	emit_signal("boss_died")
	queue_free()


func _disable_collision() -> void:
	$CollisionPolygon2D.disabled = true
	$Area2D/CollisionPolygon2D.disabled = true
	
	
func _enable_collision() -> void:
	$CollisionPolygon2D.disabled = false
	$"Area2D/CollisionPolygon2D".disabled = false


func _free_sound_player(sound_player: AudioStreamPlayer2D) -> void:
	sound_player.queue_free()
	
	
func _glow_effect(pos: Vector2) -> void:
	var glow_spot = radial_glow_scene.instantiate()
	var sprite := glow_spot.get_node("Sprite2D")
	sprite.visible = true
	sprite.modulate = Color(1, 1, 1, 0.0)
	add_child(glow_spot)
	glow_spot.global_position = pos
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1.0), 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.0), 2.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(Callable(glow_spot, "queue_free"))
	

func _on_shoot_timer_timeout():
	spawn_exploderBot()
	
	
func spawn_exploderBot() -> void:
	var spawn_pos = $Marker2D.global_position
	_glow_effect_small(spawn_pos)  # Add glow first
	
	await get_tree().create_timer(0.2).timeout  # Short delay to sync with the glow
	
	var exploderBot = game_manager._get_exploderBot()
	exploderBot.position = spawn_pos
	
	if Globals.player:
		exploderBot.direction = (Globals.player.global_position - exploderBot.global_position).normalized()
	
	if not exploderBot.is_inside_tree():
		add_child(exploderBot)

	if exploderBot.has_method("reset"):
		exploderBot.reset()
		
	exploderBot.add_to_group("Enemies")
	
	exploderBot.visible = true


func _glow_effect_small(pos: Vector2) -> void:
	var glow_spot = radial_glow_scene.instantiate()
	var sprite := glow_spot.get_node("Sprite2D")
	sprite.scale = Vector2(.05, .05)
	sprite.visible = true
	sprite.modulate = Color(1, 1, 1, 0.0)
	add_child(glow_spot)
	glow_spot.global_position = pos
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1.0), .2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.0), .2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(Callable(glow_spot, "queue_free"))
	

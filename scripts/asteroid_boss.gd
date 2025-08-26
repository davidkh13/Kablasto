extends RigidBody2D

@export var life := 100
@export var asteroid_scene : PackedScene
@export var explosion_scene: PackedScene
@export var radial_glow_scene: PackedScene
const SOUND_EXPLODE = preload("res://explosion.wav")
@export var spawn_force := 300.0
@export var spawn_cooldown := 1.0
@export var speed: float = 150.0
@export var rotation_speed : float = randf_range(-30.0, 30.0)
@export var direction: Vector2 = Vector2.ZERO
var game_manager

var spawn_cooldown_timer := 0.0

const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
signal shake_screen
signal short_shake
signal boss_died



func _ready() -> void:
	add_to_group("Enemies")
	linear_velocity = direction.normalized() * speed
	

func _process(delta: float) -> void:
	if linear_velocity.length() < speed * 0.95:
		linear_velocity = linear_velocity.normalized() * speed
	
	angular_velocity = deg_to_rad(rotation_speed)
	
	if spawn_cooldown_timer > 0.0:
		spawn_cooldown_timer -= delta
	
	
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
	
func _take_damage(amount: int) -> void:
	if life <= 0:
		return  # Already dead, ignore extra hits
	life -= amount
	emit_signal("short_shake") #picked up by gm
	
	var sound_player = AudioStreamPlayer2D.new()
	sound_player.stream = SOUND_BULLET_HIT
	add_child(sound_player)
	sound_player.play()
	sound_player.finished.connect(func() -> void: sound_player.queue_free())
	
	if life <= 0:
		die()
		return
	
	if spawn_cooldown_timer > 0.0:
		return #Still in cooldown
		
	for i in range(6):
		var angle = TAU * i / 6 #evenly spaced angles
		var offset = Vector2(50 * cos(angle), 50 * sin(angle))
		var spawn_pos = global_position + offset
		call_deferred("spawn_asteroid", spawn_pos)
		
	spawn_cooldown_timer = spawn_cooldown
	
	
func die() -> void:
	remove_from_group("Enemies")
	emit_signal("shake_screen") #received by gameManager
	var boss_global_position = global_position
	_glow_effect(boss_global_position)
	$CollisionPolygon2D.call_deferred("set_disabled", true)
	$CollisionPolygon2D.global_position.y = -10000
	$"Area2D(Hit Box)/CollisionPolygon2D".call_deferred("set_disabled", true)
	$"Area2D(Hit Box)/CollisionPolygon2D".global_position.y = -10000
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
	
func spawn_asteroid(pos: Vector2) -> void:
	if game_manager == null:
		return
		
	var asteroid = game_manager._get_asteroid()
	if asteroid == null:
		return
		
	asteroid.position = pos
	var direction = (pos - global_position).normalized()
	var force = direction * spawn_force
	
	if asteroid.has_method("reset"):
		asteroid.reset()
	asteroid.linear_velocity = force
	asteroid.add_to_group("Enemies")
	asteroid.visible = true


func lock_into_gameplay() -> void:
	collision_mask = 1 | 2

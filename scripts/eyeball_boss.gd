extends RigidBody2D

@export var eyeball_size := Vector2(.50, .50)
@export var direction: Vector2 = Vector2.ZERO
@export var speed: float = 120.0
@export var shot_delay :float = 2.5
var life := 100
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")
const SOUND_SHOOT = preload("res://bad_laser.wav")
var shoot_timer := Timer.new()
var max_offset := 20.0 #For eye shifting.
var game_manager

@export var explosion_scene: PackedScene
@export var bullet_scene: PackedScene
@export var radial_glow_scene: PackedScene

signal shake_screen
signal short_shake
signal boss_died


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Enemies")
	$Sprite2D.scale = eyeball_size
	$Sprite2D2.scale = eyeball_size
	$Sprite2D3.scale = eyeball_size
	$CollisionPolygon2D.scale = eyeball_size
	$Area2D_HitBox/CollisionPolygon2D.scale = eyeball_size
		
	linear_velocity = direction.normalized() * speed

	add_child(shoot_timer)
	shoot_timer.wait_time = shot_delay
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(self._on_shoot_timer_timeout)
	shoot_timer.start()
	
func _on_shoot_timer_timeout():
	shoot()
	await get_tree().create_timer(0.50).timeout
	shoot()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if linear_velocity.length() < speed * 0.95:
		linear_velocity = linear_velocity.normalized() * speed
		
		if Globals.player and Globals.player.is_inside_tree():
			var to_player_global = (Globals.player.global_position - global_position).normalized()
			
			#Convert to local
			var to_player_local = global_transform.basis_xform_inv(to_player_global)
			
			$Sprite2D2.position = to_player_local * max_offset
	

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
	if life <= 0 or amount > 900:
		return  # Already dead, ignore extra hits
	life -= amount
	emit_signal("short_shake") #picked up by gm
	speed += 5.0
	shot_delay -= .05
	
	var sound_player = AudioStreamPlayer2D.new()
	sound_player.stream = SOUND_BULLET_HIT
	add_child(sound_player)
	sound_player.play()
	sound_player.finished.connect(func() -> void: sound_player.queue_free())
	
	if life <= 0: #die
		remove_from_group("Enemies")
		emit_signal("shake_screen")
		shoot_timer.stop()
		var boss_global_position = global_position
		_glow_effect(boss_global_position)
		$CollisionPolygon2D.call_deferred("set_disabled", true)
		$CollisionPolygon2D.global_position.y = -10000
		$Area2D_HitBox/CollisionPolygon2D.call_deferred("set_disabled", true)
		$Area2D_HitBox/CollisionPolygon2D.global_position.y = -10000
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		set_deferred("freeze", true)
		
		if game_manager:
			game_manager.kill_all_rocks()
		
		for i in range(20):
			$Sprite2D.visible = (i % 2 == 0)
			$Sprite2D2.visible = (i % 2 == 0)
			$Sprite2D3.visible = (i % 2 == 0)
				
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
	$Area2D_HitBox/CollisionPolygon2D.disabled = true

func _enable_collision() -> void:
	$CollisionPolygon2D.disabled = false
	$Area2D_HitBox/CollisionPolygon2D.disabled = false

func _free_sound_player(sound_player: AudioStreamPlayer2D) -> void:
	sound_player.queue_free()
	
	
func shoot() -> void:
	# Blink: hide Sprite2
	$Sprite2D2.visible = false

	# Wait 0.3 seconds (blink duration)
	await get_tree().create_timer(0.3).timeout
	
	# Open eye again
	$Sprite2D2.visible = true
	
	if Globals.player and Globals.player.is_inside_tree():
		var bullet = bullet_scene.instantiate()
		bullet.position = global_position
		bullet.hit_player.connect(Globals.player._got_hit)
		get_parent().add_child(bullet)

		var direction = (Globals.player.global_position - global_position).normalized()
		var bullet_color = Color.RED
		var bullet_speed = 850.0
		var bullet_spin = 15.0

		bullet.setup(direction, bullet_color, bullet_speed, bullet_spin)

		var sound_player = AudioStreamPlayer2D.new()
		sound_player.stream = SOUND_SHOOT
		add_child(sound_player)
		sound_player.play()
		
		sound_player.finished.connect(func() -> void:
			call_deferred("_free_sound_player", sound_player))
		
func lock_into_gameplay() -> void:
	collision_mask = 1 | 2

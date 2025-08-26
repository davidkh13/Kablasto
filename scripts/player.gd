extends RigidBody2D

@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var size: float = .25 #Scale factor
var hud: CanvasLayer = null
@onready var damage_smoke = $Damage_smoke
signal player_died
const SOUND_EXPLODE = preload("res://explosion.wav")
const SOUND_BAB_BULLET_HIT = preload("res://hit_player.wav")

var thrust_power = 1000.0  # Thrust strength
var max_speed = 1000.0 # Limit the maximum speed
var rotation_speed: float = 8.0
var background
var shields: int = 100
var goldShields: int = 100
var gameManager: Node
var weapon_level : int
var shield_level : int
var is_invulnerable := true
var player_has_control := true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.player = self
	gameManager = get_parent()
	background = get_parent().get_node("Background")
	hud = get_parent().get_node("HUD")
	weapon_level = gameManager.player_weapon_level
	shield_level = gameManager.player_shield_level
	$Camera2D.make_current()
		
	var sprite = $Sprite2D
	sprite.scale = Vector2(size, size)
	
	var collision_polygon = $CollisionPolygon2D
	var original_points = collision_polygon.polygon
	var scaled_points = []
	for point in original_points:
		scaled_points.append(point * size)
	collision_polygon.polygon = scaled_points
	
	var thrust_node = $ThrustParticles
	thrust_node.position = Vector2(0, -50)
	thrust_node.scale = Vector2.ONE
	
	modulate.a = 0.5 #half transparent
	$InvulnTimer.timeout.connect(_on_invuln_timer_timeout)

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
		
	var side_edge = background.texture.get_size() * background.scale / 2
	
	
	# Wrap around horizontally
	if position.x < 640 - side_edge.x:
		position.x = 640 + side_edge.x
	elif position.x > 640 + side_edge.x:
		position.x = 640 - side_edge.x
	
		# Wrap around vertically
	if position.y < 360 - side_edge.y:
		position.y = 360 + side_edge.y
	elif position.y > 360 + side_edge.y:
		position.y = 360 - side_edge.y
		
	if $Sprite2D.visible == true and player_has_control == true:
		# Handle player input for movement (arrow keys or WASD)
		if Input.is_action_pressed("ui_right"):  # Right arrow
			#rotation += rotation_speed * delta  # Rotate clockwise (right)
			#apply_torque_impulse(rotation_speed * delta)
			angular_velocity = rotation_speed
		
		elif Input.is_action_pressed("ui_left"):  # Left arrow
			#rotation -= rotation_speed * delta  # Rotate clockwise (left)
			#apply_torque_impulse(-rotation_speed * delta)
			angular_velocity = -rotation_speed
		
		else:
			angular_velocity = 0.0

		if Input.is_action_pressed("ui_up"):  #up Arrow
			var direction = Vector2.UP.rotated(rotation)  # Get direction facing the ship
			linear_velocity += direction * thrust_power * delta  # Apply force to the velocity
			linear_velocity = linear_velocity.limit_length(max_speed) #Clamp to max speed
		
	
		if Input.is_action_pressed("ui_down"):  # S or Down Arrow
			linear_velocity = linear_velocity.move_toward(Vector2.ZERO, thrust_power * delta)  # Slow down gradually

		if Input.is_action_just_pressed("ui_select"):
			fire_bullet()
	
		
func fire_bullet():
	match weapon_level:
		1:
			_spawn_bullet_at_offset(Vector2.ZERO)
		2:
			_spawn_bullet_at_offset(Vector2(-30, 25))
			_spawn_bullet_at_offset(Vector2(30, 25))
		_:
			_spawn_bullet_at_offset(Vector2.ZERO)
			_spawn_bullet_at_offset(Vector2(-30, 25))
			_spawn_bullet_at_offset(Vector2(30, 25))
	$Laser_Fire.play()
	
	
func _spawn_bullet_at_offset(offset: Vector2):
	var bullet = bullet_scene.instantiate() #Create bullet instance
	var rotated_offset = offset.rotated(rotation)
	bullet.position = position + Vector2(0, -1).rotated(rotation) * 30 + rotated_offset
	bullet.rotation = rotation
	get_parent().add_child(bullet)
	if not bullet.hit_rock.is_connected(_on_hit_rock):
		bullet.hit_rock.connect(_on_hit_rock)
	
	

	
func _on_hit_rock() -> void:
	gameManager.score += 100
	hud.update_score_label()
	
func update_smoke_emit() -> void:
	damage_smoke.emitting = shields <= 25
	
func take_damage(damage: int) -> void:
	if shields > 0:
		if goldShields > 0 and shield_level > 1 and not is_invulnerable:
			goldShields -= damage
		else:
			if not is_invulnerable:
				shields -= damage
		$Camera2D.shake(4.0, 5.0)
		update_smoke_emit()
		if shields <= 0:
			hud.stop_low_shield_sound()
			damage_smoke.emitting = false
			$Sprite2D.visible = false
			$CollisionPolygon2D.call_deferred("set_disabled", true)
			$ThrustParticles.call_deferred("set_emitting", false)
			$ThrustParticles.visible = false
					
			for i in range(5):				
				var sound_player = AudioStreamPlayer2D.new()
				sound_player.stream = SOUND_EXPLODE
				add_child(sound_player)
				sound_player.play()
				sound_player.finished.connect(func() -> void: sound_player.queue_free())

				var explosion = explosion_scene.instantiate()
				var offset = Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
				explosion.global_position = global_position + offset
				get_tree().current_scene.add_child(explosion)
				await get_tree().create_timer(0.05).timeout
			var temp_cam = get_node("../tempCamera2D")
			#if gameManager.lives > 0:
			temp_cam.position = $Camera2D.get_screen_center_position()
			temp_cam.make_current()
			#else:
			#temp_cam.queue_free()
			await get_tree().create_timer(2.0).timeout
			emit_signal("player_died")
			Globals.player = null
			
			queue_free()
			
			
func _got_hit() -> void:
	var sound_player = AudioStreamPlayer2D.new()
	sound_player.stream = SOUND_BAB_BULLET_HIT
	add_child(sound_player)
	sound_player.play()
		
	sound_player.finished.connect(func() -> void:
		call_deferred("_free_sound_player", sound_player))
		
	
func _free_sound_player(sound_player: AudioStreamPlayer2D) -> void:
	sound_player.queue_free()


func _on_invuln_timer_timeout() -> void:
	is_invulnerable = false
	modulate.a = 1.0  # Restore visibility


func exit_to_left() -> void:
	player_has_control = false
	$ThrustParticles.player_has_control =  false
	
	# Rotate to face left
	var target_rotation = -PI / 2
	var rotate_duration = 1.0
	var tween = create_tween()
	tween.tween_property(self, "rotation", target_rotation, rotate_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# Begin flying left
	var fly_duration = 3.0
	var fly_distance = -get_viewport_rect().size.x * 1.2  # Fly off-screen
	var start_pos = position
	var end_pos = start_pos + Vector2(fly_distance, 0)
	
	$ThrustParticles.autopilot = true
	# Detach camera from player
	var temp_cam = get_node("../tempCamera2D")
	#if gameManager.lives > 0:
	temp_cam.position = $Camera2D.get_screen_center_position()
	temp_cam.make_current()
	
	# Tween to new position
	var fly_tween = create_tween()
	fly_tween.tween_property(self, "position", end_pos, fly_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await fly_tween.finished
	queue_free()

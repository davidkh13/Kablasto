extends RigidBody2D

@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var size: float = .25 #Scale factor
@onready var Hud = $Camera2D/HUD
@onready var damage_smoke = $Damage_smoke
signal player_died
const SOUND_EXPLODE = preload("res://explosion.wav")


var thrust_power = 1000.0  # Thrust strength
var max_speed = 1000.0 # Limit the maximum speed
var rotation_speed: float = 8.0
var background
var hud
var shields: int = 100
var gameManager: Node



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gameManager = get_parent()
	background = get_parent().get_node("Background")
	hud = get_child(1).get_child(0)
	
	
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
		
	if $Sprite2D.visible == true:
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
	var bullet = bullet_scene.instantiate() #Create bullet instance
	bullet.position = position + Vector2(0, -1).rotated(rotation) * 30 #Spawn at front
	bullet.rotation = rotation
	get_parent().add_child(bullet)
	if not bullet.hit_rock.is_connected(_on_hit_rock):
		bullet.hit_rock.connect(_on_hit_rock)
	$Laser_Fire.play()
	
func _on_hit_rock() -> void:
	gameManager.score += 100
	hud.update_score_label()
	
func update_smoke_emit() -> void:
	damage_smoke.emitting = shields <= 25
	
func take_damage(damage: int) -> void:
	if shields > 0:
		shields -= damage
		$Camera2D.shake(4.0, 5.0)
		update_smoke_emit()
		if shields <= 0:
			Hud.stop_low_shield_sound()
			damage_smoke.emitting = false
			$Sprite2D.visible = false
			$CollisionPolygon2D.call_deferred("set_disabled", true)
			#$CollisionPolygon2D.global_position.y = -10000
			$ThrustParticles.call_deferred("set_emitting", false)
			$ThrustParticles.visible = false
			#$ThrustParticles.global_position.y = -10000
		
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
				
			await get_tree().create_timer(2.0).timeout
			emit_signal("player_died")
			queue_free()
			
			
		
	

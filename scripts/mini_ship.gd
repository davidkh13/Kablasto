extends RigidBody2D

@export var miniship_size := Vector2(.07, .07)
@export var direction: Vector2 = Vector2.ZERO
@export var speed: float = 320.0
@export var tracking_speed: float = 50.0
@export var turn_speed: float = 50.0
var life := 5
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")
const SOUND_SHOOT = preload("res://bad_laser.wav")
var shoot_timer := Timer.new()

@export var explosion_scene: PackedScene
@export var bullet_scene: PackedScene

signal miniship_destroyed



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.scale = miniship_size
	$CollisionPolygon2D.scale = miniship_size
	$"Area2D/CollisionPolygon2D".scale = miniship_size
	
	add_child(shoot_timer)
	shoot_timer.wait_time = randf_range(3.0, 5.0)
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(self._on_shoot_timer_timeout)
	shoot_timer.start()
	
	
func _on_shoot_timer_timeout():
	shoot()
	
	
func shoot() -> void:
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
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
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
	if life <= 0: #die
		remove_from_group("Enemies")
		shoot_timer.stop()
		var sound_player2 = AudioStreamPlayer2D.new()
		sound_player2.stream = SOUND_DIE
		add_child(sound_player2)
		sound_player2.play()
		
		sound_player2.finished.connect(func() -> void:
			call_deferred("_free_sound_player", sound_player2))
		
		visible = false
		$Sprite2D.visible = false
				
		call_deferred("_disable_collision")
		
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
		await get_tree().create_timer(1.0).timeout
		   
		set_process(false)
		emit_signal("miniship_destroyed")


func _disable_collision() -> void:
	$CollisionPolygon2D.disabled = true
	$Area2D/CollisionPolygon2D.disabled = true
	
	
func _enable_collision() -> void:
	$CollisionPolygon2D.disabled = false
	$"Area2D/CollisionPolygon2D".disabled = false


func _free_sound_player(sound_player: AudioStreamPlayer2D) -> void:
	sound_player.queue_free()

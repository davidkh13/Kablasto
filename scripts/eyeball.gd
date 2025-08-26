extends RigidBody2D

@export var eyeball_size := Vector2(.20, .20)
@export var direction: Vector2 = Vector2.ZERO
@export var speed: float = randf_range(80.0, 120.0)
var life := 5
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")
const SOUND_SHOOT = preload("res://bad_laser.wav")
var shoot_timer := Timer.new()
var max_offset := 5.0 #For eye shifting.
const MAX_SPEED = 400.0

@export var explosion_scene: PackedScene
@export var bullet_scene: PackedScene

signal eyeball_destroyed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.scale = eyeball_size
	$Sprite2D2.scale = eyeball_size
	$Sprite2D3.scale = eyeball_size
	$CollisionPolygon2D.scale = eyeball_size
	$Area2D_HitBox/CollisionPolygon2D.scale = eyeball_size
	
	linear_velocity = direction.normalized() * speed
	
	add_child(shoot_timer)
	shoot_timer.wait_time = randf_range(3.0, 5.0)
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(self._on_shoot_timer_timeout)
	shoot_timer.start()
	
func _on_shoot_timer_timeout():
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
	

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED


func reset() -> void:
	visible = true
	$Sprite2D.visible = true
	$Sprite2D2.visible = true
	$Sprite2D3.visible = true
	call_deferred("_enable_collision")
	set_process(true)
	life = 5
	speed = randf_range(80.0, 120.0)
	linear_velocity = direction.normalized() * speed
	
	
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
		$Sprite2D2.visible = false
		$Sprite2D3.visible = false
		
		call_deferred("_disable_collision")
		
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
		await get_tree().create_timer(1.0).timeout
		   
		set_process(false)
		emit_signal("eyeball_destroyed")
		
		
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

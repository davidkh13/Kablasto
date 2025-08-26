extends CharacterBody2D

@export var speed: float = randf_range(80.0, 120.0)
@export var ship_size: Vector2 = Vector2(.20, .20)
var life: int = 10
var slot_index: int = -1
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")
const SOUND_SHOOT = preload("res://bad_laser.wav")

@export var explosion_scene: PackedScene
@export var bullet_scene: PackedScene
var fire_cooldown := 0.0
@export var fire_interval := 1.2  # Seconds between shots

signal fighter_died

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.scale = ship_size
	$CollisionPolygon2D.scale = ship_size
	$Area2D/CollisionPolygon2D.scale = ship_size
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fire_cooldown -= delta	
	
	
func _physics_process(_delta):
	var collision = move_and_collide(Vector2.ZERO)
	if collision and collision.get_collider().is_in_group("Enemies"):
		var enemy = collision.get_collider()
		if enemy is RigidBody2D:
			var push_dir = (enemy.global_position - global_position).normalized()
			enemy.apply_impulse(push_dir * 100.0)


func shoot() -> void:
	if fire_cooldown <= 0.0 and bullet_scene:
		fire_cooldown = fire_interval
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.rotation = rotation
		bullet.hit_player.connect(Globals.player._got_hit)
		get_tree().current_scene.add_child(bullet)

		var direction = Vector2.UP.rotated(global_rotation)
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
	collision_mask = 1 #| 2
	
	
func _free_sound_player(sound_player: AudioStreamPlayer2D) -> void:
	sound_player.queue_free()
	
	
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
		fighter_died.emit(self)
		queue_free()
		
		
func _disable_collision() -> void:
	$CollisionPolygon2D.disabled = true
	$Area2D/CollisionPolygon2D.disabled = true
		

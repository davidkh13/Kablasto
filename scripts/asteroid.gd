extends RigidBody2D

@export var speed: float = randf_range(80.0, 120.0)
@export var rotation_speed : float = randf_range(-30.0, 30.0)
@export var direction: Vector2 = Vector2.ZERO
@export var rock_size: Vector2 = Vector2(randf_range(.18, .32), randf_range(.18, .32))
var life: int = 3
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")
const MAX_SPEED = 400.0
@export var explosion_scene: PackedScene
signal rock_destroyed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.scale = rock_size
	$CollisionPolygon2D.scale = rock_size
	$"Area2D(hitbox)/CollisionPolygon2D".scale = rock_size
	
	linear_velocity = direction.normalized() * speed
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if linear_velocity.length() < speed * 0.95:
		linear_velocity = linear_velocity.normalized() * speed
	
	angular_velocity = deg_to_rad(rotation_speed)
		
	
func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED


func reset() -> void:
	visible = true
	$Sprite2D.visible = true
	call_deferred("_enable_collision")
	set_process(true)
	life = 3
	scale = Vector2.ONE
	speed = randf_range(80.0, 120.0)
	rotation_speed = randf_range(-30.0, 30.0)
	linear_velocity = direction.normalized() * speed
	angular_velocity = deg_to_rad(rotation_speed)
	
func _take_damage(amount: int) -> void:
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
		emit_signal("rock_destroyed")
		
func _disable_collision() -> void:
	$CollisionPolygon2D.disabled = true
	$"Area2D(hitbox)/CollisionPolygon2D".disabled = true

func _enable_collision() -> void:
	$CollisionPolygon2D.disabled = false
	$"Area2D(hitbox)/CollisionPolygon2D".disabled = false

func _free_sound_player(sound_player: AudioStreamPlayer2D) -> void:
	sound_player.queue_free()
	

func lock_into_gameplay() -> void:
	collision_mask = 1 | 2

extends RigidBody2D

@export var direction: Vector2 = Vector2.ZERO
var game_manager
var life := 100
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")

enum BossState { TRACKING, CHARGING, RECOVERING }
var state: BossState = BossState.TRACKING

@export var tracking_speed: float = 50.0
@export var charge_speed: float = 600.0
@export var turn_speed: float = 1.0
@export var charge_duration: float = 0.7
@export var recovery_time: float = 1.5

@export var radial_glow_scene: PackedScene
@export var explosion_scene: PackedScene
@export var formation_scene: PackedScene

var formation_active: bool = false
var current_formation: Node = null

var charge_direction: Vector2 = Vector2.ZERO
var charge_timer: float = 0.0
var recovery_timer: float = 0.0

var player: Node2D = null
var vulnerable: bool = false

signal shake_screen
signal short_shake
signal boss_died

func _ready() -> void:
	add_to_group("Enemies")
	player = Globals.player
	vulnerable = false
	$GPUParticles2D.emitting = true
	linear_velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if current_formation == null:
		formation_active = false
	
	# Reacquire player if needed
	if player == null and Globals.player != null:
		player = Globals.player

	if player == null:
		linear_velocity = Vector2.ZERO  # Stop moving
		return  # Skip AI logic until player exists
	
	
	match state:
		BossState.TRACKING:
			_track_player(delta)
		BossState.CHARGING:
			_do_charge(delta)
		BossState.RECOVERING:
			_recover(delta)

func _track_player(delta: float) -> void:
	if not player or state != BossState.TRACKING or life <= 0:
		return

	var to_player = player.global_position - global_position
	var target_rot = to_player.angle() + PI / 2.0
	rotation = lerp_angle(rotation, target_rot, turn_speed * delta)

	# Move slowly forward
	linear_velocity = Vector2.UP.rotated(rotation) * tracking_speed

	# Check if it's time to charge
	var angle_diff = abs(short_angle_dist(rotation, target_rot))
	var distance = global_position.distance_to(player.global_position)
	if angle_diff < deg_to_rad(10) and distance < 550.0:
		linear_velocity = Vector2.ZERO
		await get_tree().create_timer(1.0).timeout
		_start_charge()

func _start_charge() -> void:
	state = BossState.CHARGING
	charge_timer = charge_duration
	vulnerable = true
	$GPUParticles2D.emitting = false
	if not player:
		return
	charge_direction = (player.global_position - global_position).normalized()
	linear_velocity = charge_direction * charge_speed
	
	# Disable glow when vulnerable
	var shader = $Sprite2D.material as ShaderMaterial
	if shader:
		shader.set_shader_parameter("glow_enabled", false)

func _do_charge(delta: float) -> void:
	# Keep moving forward during charge
	linear_velocity = charge_direction * charge_speed

	# Optional: push the player if within range
	if player:
		var dist = global_position.distance_to(player.global_position)
		var push_radius = 64.0
		if dist < push_radius:
			var force = charge_direction.normalized() * 12000.0
			player.apply_central_impulse(force)

	charge_timer -= delta
	if charge_timer <= 0.0:
		_start_recovery()


func _start_recovery() -> void:
	state = BossState.RECOVERING
	await get_tree().create_timer(1.5).timeout
	vulnerable = false
	$GPUParticles2D.emitting = true
	recovery_timer = recovery_time
	linear_damp = 10.0
	
	# Re-enable glow when invulnerable
	var shader = $Sprite2D.material as ShaderMaterial
	if shader:
		shader.set_shader_parameter("glow_enabled", true)

func _recover(delta: float) -> void:
	# Apply braking
	var friction_force = -linear_velocity * 4.0  # Tune as needed
	apply_central_impulse(friction_force * delta)

	recovery_timer -= delta
	if recovery_timer <= 0.0:
		state = BossState.TRACKING
		linear_damp = 0.0
		linear_velocity = Vector2.ZERO  # fully stop

func lock_into_gameplay() -> void:
	pass

func short_angle_dist(a: float, b: float) -> float:
	return atan2(sin(b - a), cos(b - a))
	

func _not_vulnerable() -> void:
	$weak_hit.play()
	
	
func _take_damage(amount: int) -> void:
	if life <= 0 or amount > 900:
		return  # Already dead, ignore extra hits
	
	life -= amount
	emit_signal("short_shake") #picked up by gm
	
	var sound_player = AudioStreamPlayer2D.new()
	sound_player.stream = SOUND_BULLET_HIT
	add_child(sound_player)
	sound_player.play()
	sound_player.finished.connect(func() -> void: sound_player.queue_free())
	
	if life <= 0:
		$GPUParticles2D.emitting = false
		$GPUParticles2D.visible = false
		die()
		return
		
	if not formation_active:
		summon_formation()
	
func die() -> void:
	if formation_active:
		current_formation._kill_all_fighters()
	
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
	

func summon_formation() -> void:
	current_formation = formation_scene.instantiate()
	formation_active = true
	get_tree().current_scene.add_child(current_formation)
	current_formation.global_position = game_manager.get_random_position()
	$formationApproach.play()
	

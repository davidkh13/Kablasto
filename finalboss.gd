extends RigidBody2D

@export var direction: Vector2 = Vector2.ZERO
var game_manager
var life := 100
var number_of_generators := 4
var entering := true
var vulnerable: bool = false
var max_offset := 10.0 #For eye shifting.
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")
const SOUND_WEAK_HIT = preload("res://weak_hit.wav")
var blink_timer := Timer.new()
var is_dying := false
@export var speed: float = 60.0
@export var tracking_speed: float = 30.0
@export var turn_speed: float = 2.0

@export var entry_position := Vector2(1000, 500)  # Where the boss should stop
@export var drift_speed := 10.0

@onready var gens_node = $generators

@export var explosion_scene: PackedScene
@export var radial_glow_scene: PackedScene


signal shake_screen
signal short_shake
signal boss_died


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Enemies")
	vulnerable = false
	$GPUParticles2D.emitting = true
	
	if gens_node and gens_node.get_parent() == self:
		remove_child(gens_node)
		get_parent().add_child(gens_node)
		# Optionally set position/rotation to keep it visually correct
		gens_node.global_position = global_position
		
	# CONNECT GENERATOR SIGNALS
	for gen in gens_node.get_children():
		if gen.has_signal("generator_destroyed"):
			gen.generator_destroyed.connect(_on_generator_destroyed)
	
	rotation = deg_to_rad(-90)
	var entry_tween = get_tree().create_tween()
	entry_tween.tween_property(self, "position", entry_position, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entry_tween.play()
	
	await entry_tween.finished
	entering = false
	
	add_child(blink_timer)
	blink_timer.wait_time = randf_range(3.0, 5.0)
	blink_timer.one_shot = false
	blink_timer.timeout.connect(self._on_blink_timer_timeout)
	blink_timer.start()
	
	


func _physics_process(delta: float) -> void:
	if is_instance_valid(gens_node):
		gens_node.global_position = global_position
		
	if is_dying:
		return
	
	if Globals.player and Globals.player.is_inside_tree():
			var to_player_global = (Globals.player.global_position - global_position).normalized()
			
			#Convert to local
			var to_player_local = global_transform.basis_xform_inv(to_player_global)
			
			$SpriteEyeball.position = to_player_local * max_offset
			
			if not entering:
				var target_rot = to_player_global.angle() + PI / 2.0
				rotation = lerp_angle(rotation, target_rot, turn_speed * delta)

				# Move slowly forward
				linear_velocity = Vector2.UP.rotated(rotation) * tracking_speed

				var angle_diff = abs(short_angle_dist(rotation, target_rot))
				var distance = global_position.distance_to(Globals.player.global_position)
				if angle_diff < deg_to_rad(5):
					linear_velocity = to_player_global * speed
					
func _on_blink_timer_timeout():
	_blink()
	
	
func _blink() -> void:
	# Blink: hide Sprite2
	$SpriteEyeball.visible = false
	vulnerable = false

	# Wait 0.3 seconds (blink duration)
	await get_tree().create_timer(0.3).timeout
	
	# Open eye again
	$SpriteEyeball.visible = true
	if number_of_generators <= 0:
		vulnerable = true


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
		blink_timer.stop()
		is_dying = true
		die()
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
	$Area2D_Eye/CollisionShape2D.call_deferred("set_disabled", true)
	$Area2D_Eye/CollisionShape2D.global_position.y = -10000
	#freeze sprite movement
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_deferred("freeze", true)
	
	_start_dissolve_effect()
	$SpriteEyelid.visible = false
	
	if game_manager:
		game_manager.kill_all_rocks()
		await get_tree().create_timer(0.05).timeout
		
	for i in range(25):
		$SpriteEyeball.visible = (i % 2 == 0)
		$Spritebody.visible = (i % 2 == 0)
				
		var explosion = explosion_scene.instantiate()
		var offset = Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
		var pos = boss_global_position + offset
		_glow_effect_small(pos)
		explosion.global_position = pos
		get_tree().current_scene.add_child(explosion)
		
		$ExplosionSoundPool.play_sound(pos)
		await get_tree().create_timer(0.20).timeout
		
	await get_tree().create_timer(2.0).timeout
	emit_signal("boss_died")
	queue_free()
	
	
func short_angle_dist(a: float, b: float) -> float:
	return atan2(sin(b - a), cos(b - a))
	

func lock_into_gameplay() -> void:
	collision_mask = 8
	
	
func _on_generator_destroyed() -> void:
	number_of_generators -= 1
	if number_of_generators == 0:
		vulnerable = true
		$GPUParticles2D.emitting = false
		
		var shader = [
			$SpriteEyelid.material as ShaderMaterial,
			$SpriteEyeball.material as ShaderMaterial,
			$Spritebody.material as ShaderMaterial
		]
		for s in shader:
			s.set_shader_parameter("glow_enabled", false)
		
		 #change collision here
		
func _not_vulnerable() -> void:
	$weak_hit.play()
	
	
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
	
	
func _start_dissolve_effect() -> void:
	var sprites = [
		$SpriteEyeball.material,
		$SpriteEyelid.material,
		$Spritebody.material
	]
	
	for mat in sprites:
		if mat is ShaderMaterial:
			mat.set_shader_parameter("use_dissolve", true)
			var tween = create_tween()
			tween.tween_property(mat, "shader_parameter/dissolve_amount", 1.0, 15.0)
			

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
	
	
	

extends CharacterBody2D

@onready var red_light := $Sprite2D2
var life: int = 50
const SOUND_BULLET_HIT = preload("res://hit_rock.wav")
const SOUND_DIE = preload("res://explosion.wav")

@export var explosion_scene: PackedScene

signal generator_destroyed


func _ready() -> void:
	add_to_group("Enemies")
	await get_tree().create_timer(randf_range(0.2, 1.0)).timeout
	blink_loop()


func _physics_process(delta: float) -> void:
	pass
	
	
func blink_loop() -> void:
	red_light.visible = !red_light.visible
	await get_tree().create_timer(0.5).timeout
	blink_loop()
	
	
func _take_damage(amount: int) -> void:
	if amount > 900 or life <= 0:
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
		$Sprite2D2.visible = false
		
		call_deferred("_disable_collision")
		
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
		await get_tree().create_timer(1.0).timeout
		   
		set_process(false)
		emit_signal("generator_destroyed")
		
		
func lock_into_gameplay() -> void:
	collision_mask = 1
	
	
func _free_sound_player(sound_player: AudioStreamPlayer2D) -> void:
	sound_player.queue_free()
	
	
func _disable_collision() -> void:
	$CollisionPolygon2D.disabled = true
	$Area2D/CollisionPolygon2D.disabled = true

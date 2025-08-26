extends Area2D

@export var goodie_type: String = "shield"  # "shield" or "weapon"
var gm : Node = null
@export var speed: float = 150.0
@export var direction: Vector2 = Vector2.LEFT
@export var wave_amplitude: float = 50.0  # pixels side-to-side
@export var wave_frequency: float = 1.5   # how many waves per second

var base_position: Vector2
var wave_timer: float = 0.0
var collected := false

var goody_colors := {
	"weapon": Color.INDIAN_RED,
	"shield": Color.STEEL_BLUE
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#gm = get_node("/root/Main/GameManager")
	add_to_group("goodies")
	#connect("body_entered", Callable(self, "_on_body_entered"))

	# Assign the correct sprite based on type
	match goodie_type:
		"shield":
			$Sprite2D.texture = preload("res://shieldgoodie.png")
		"weapon":
			$Sprite2D.texture = preload("res://weapongoodie.png")

	# Optional: Add a little animation or randomness
	self.rotation = randf_range(-0.1, 0.1)
	direction = direction.normalized()
	base_position = global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	wave_timer += delta
	
	#move forward
	base_position += direction * speed * delta
	
	# Calculate wave offset (perpendicular to main direction)
	var perpendicular = Vector2(-direction.y, direction.x)
	var wave_offset = perpendicular * sin(wave_timer * PI * 2.0 * wave_frequency) * wave_amplitude
	
	# Combine base motion and wave offset
	global_position = base_position + wave_offset

	# Clean up off-screen
	if is_out_of_bounds():
		queue_free()
		

func is_out_of_bounds() -> bool:
	return position.x < -365 or position.x > 1655 or position.y < -220 or position.y > 940



func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not collected:
		collected = true
		var color = goody_colors.get(goodie_type, Color.WHITE)
		$CPUParticles2D.modulate = color
		$CPUParticles2D.emitting = true
		# Notify GameManager (you’ll implement this)
		gm.score += 100
		gm.hud.update_score_label()
		if gm.has_method("register_goodie"):
			gm.register_goodie(goodie_type)

		# Disable collisions immediately to prevent duplicates
		$CollisionShape2D.call_deferred("set_disabled", true)
		$Sprite2D.visible = false

		# Optional: visual or sound effect
		$AudioStreamPlayer.play()
		await $AudioStreamPlayer.finished

		# Clean up
		queue_free()

extends GPUParticles2D

@onready var thruster_particles = $"."

var thrust_timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thrust_timer = $Thrust_Timer
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#Update the flame rotation
	thruster_particles.rotation_degrees = rotation_degrees
	
	if Input.is_action_pressed("ui_up"):
		thruster_particles.emitting = true
		if thrust_timer.is_stopped():
			thrust_timer.start()
	else:
		thruster_particles.emitting = false
		if !thrust_timer.is_stopped():
			thrust_timer.stop()
			

func _on_thrust_timer_timeout() -> void:
	$Thrust_sound.play()

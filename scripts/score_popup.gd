extends Node2D

@export var float_speed := -30.0
@export var fade_time := 1.0
@export var drift_range := 10.0 #Random sideways motion

var time_passed := 0.0
var drift_offset := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#A little random drift
	drift_offset = randf_range(-drift_range, drift_range)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	position.y += float_speed * delta
	position.x += drift_offset * delta
	var alpha: float = 1.0 - (time_passed / fade_time)
	alpha = clamp(alpha, 0.0, 1.0)
	
	var base_color = Color(1.0, 0.9, 0.2, alpha)
	var label = $Label
	label.modulate = base_color
	
	#Scale effect
	var start_scale := 0.5
	var end_scale := 1.8
	var scale_progress: float = clamp(time_passed / .5, 0.0, 1.0)
	scale = Vector2.ONE * lerp(start_scale, end_scale, scale_progress)
	
	if time_passed > fade_time:
		queue_free()

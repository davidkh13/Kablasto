extends Camera2D

var shake_amount: float = 0.0
var shake_decay: float = 5.0
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Enable the camera to be active
	make_current()
	rng.randomize()
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Apply the limits
	self.limit_left = -360
	self.limit_right = 1648
	self.limit_top = -216
	self.limit_bottom = 936
	
	if shake_amount > 0:
		offset = Vector2(
			rng.randf_range(-shake_amount, shake_amount),
			rng.randf_range(-shake_amount, shake_amount)
		)
		shake_amount -= shake_decay * delta
	else:
		offset = Vector2.ZERO
		shake_amount = 0.0
			
func shake(intensity: float, decay: float) -> void:
	shake_amount = intensity
	shake_decay = decay

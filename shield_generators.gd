extends Marker2D

@export var generator_size := Vector2(.25, .25)
var rock_spin_speed := 2.5
var orbit_speed := .8



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CharacterBody2D.scale *= generator_size
	$CharacterBody2D2.scale *= generator_size
	$CharacterBody2D3.scale *= generator_size
	$CharacterBody2D4.scale *= generator_size
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation += orbit_speed * delta
	
	$CharacterBody2D/Sprite2D.rotation += rock_spin_speed * delta
	$CharacterBody2D2/Sprite2D.rotation += rock_spin_speed * delta
	$CharacterBody2D3/Sprite2D.rotation += rock_spin_speed * delta
	$CharacterBody2D4/Sprite2D.rotation += rock_spin_speed * delta

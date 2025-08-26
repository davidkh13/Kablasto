extends Marker2D


var rock_spin_speed := 2.5
var orbit_speed := .8

@export var explosion_scene: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation += orbit_speed * delta
	
	$theRock1/Sprite2D.rotation += rock_spin_speed * delta
	
	$theRock2/Sprite2D.rotation += rock_spin_speed * delta
	
	
	
func die() ->void:
	visible = false
	$theRock1/Sprite2D.visible = false
	$theRock2/Sprite2D.visible = false
	
	call_deferred("_disable_collision")
	
	var explosion = explosion_scene.instantiate()
	var explosion2 = explosion_scene.instantiate()
	explosion.global_position = $theRock1/Sprite2D.global_position
	explosion2.global_position = $theRock2/Sprite2D.global_position
	
	get_tree().current_scene.add_child(explosion)
	get_tree().current_scene.add_child(explosion2)
	
	queue_free()
	

func _disable_collision() -> void:
	$theRock1/CollisionPolygon2D.disabled = true
	$theRock1/Area2D/CollisionPolygon2D.disabled = true
	$theRock2/CollisionPolygon2D.disabled = true
	$theRock2/Area2D/CollisionPolygon2D.disabled = true

	

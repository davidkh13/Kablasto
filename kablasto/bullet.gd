extends Area2D

@export var speed =  1250.0 #bullet speed
@export var spin_speed = 15
@onready var sprite = $Sprite2D
@onready var collision = $CollisionPolygon2D
@onready var popup_scene = preload("res://score_popup.tscn")

signal hit_rock

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scale *= .5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += Vector2(0, -1).rotated(rotation) * speed * delta
	sprite.rotation += spin_speed * delta
	collision.rotation += spin_speed * delta
	
	#print("pos:", position)
	
	if is_out_of_bounds():
		queue_free()
		
func is_out_of_bounds() -> bool:
	#var screen_size = get_viewport().size
	return position.x < -365 or position.x > 1655 or position.y < -220 or position.y > 940



func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.has_method("_take_damage"):
		body._take_damage(1)
		show_score_popup(100, body.global_position)
		#if body.name == "asteroid":
		emit_signal("hit_rock") #signal recieved by player adds to score
		queue_free()
		
func show_score_popup(points: int, at_position: Vector2) -> void:
	var popup = popup_scene.instantiate()
	if popup.has_node("Label"):
		popup.get_node("Label").text = "+%d" % points
	popup.global_position = at_position
	get_tree().root.add_child(popup)
	

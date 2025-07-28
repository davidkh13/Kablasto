extends Area2D

@export var speed =  1250.0 #bullet speed
@export var spin_speed = 15
@onready var sprite = $Sprite2D
@onready var collision = $CollisionPolygon2D
@onready var popup_scene = preload("res://score_popup.tscn")
var velocity := Vector2.ZERO

signal hit_player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scale *= .5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += velocity * delta
	sprite.rotation += spin_speed * delta
	collision.rotation += spin_speed * delta
	
	#print("pos:", position)
	
	if is_out_of_bounds():
		queue_free()
		
func is_out_of_bounds() -> bool:
	#var screen_size = get_viewport().size
	return position.x < -365 or position.x > 1655 or position.y < -220 or position.y > 940



func _on_body_entered(body: Node2D) -> void:
	if body == Globals.player:
		body.take_damage(5)
		emit_signal("hit_player")
		queue_free()
		
	

func setup(direction: Vector2, custom_color: Color = Color.WHITE, custom_speed: float = 1250.0, custom_spin_speed: float = 15.0) -> void:
	rotation = direction.angle()
	speed = custom_speed
	spin_speed = custom_spin_speed
	sprite.modulate = custom_color
	velocity = direction * custom_speed
	
	

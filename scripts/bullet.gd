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
	return position.x < -400 or position.x > 2000 or position.y < -400 or position.y > 1200



func _on_body_entered(body: Node2D) -> void:
	if body.has_method("_take_damage"):
		# If it's the ChargerBoss and it's not vulnerable, do nothing except free the bullet
		if body.name == "charger_boss" and not body.vulnerable:
			queue_free()
			body._not_vulnerable()
			return
		if body.name == "mothershipBoss" and not body.vulnerable:
			queue_free()
			body._not_vulnerable()
			return
		if body.name == "FinalBoss":
			if not body.vulnerable:
				queue_free()
				body._not_vulnerable()
				return
			else:
				return
			
		body._take_damage(1)
		if body.name == "theRock1" or body.name == "theRock2":
			queue_free()
			return
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
	
	
func _on_area_entered(area: Area2D) -> void:
	if area.name == "Area2D_Eye":
		var boss = area.get_parent()
		if boss.vulnerable:
			if boss.has_method("_take_damage"):
				boss._take_damage(1)
			show_score_popup(100, area.global_position)
			emit_signal("hit_rock") #signal recieved by player adds to score
			queue_free()
		else:
			queue_free()
			boss._not_vulnerable()
			return
	

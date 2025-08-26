extends Control

var player: RigidBody2D = null
var radar_size := Vector2(100, 100)
var radar_range := 2000.0 #world distance shown on radar
var last_viewport_height := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(50, 400)
	set_process(true)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var current_height = get_viewport().size.y
	if current_height != last_viewport_height:
		last_viewport_height = current_height
		position.y = current_height - 150
	#var enemies := get_tree().get_nodes_in_group("Enemies")
	#var visible_enemies := 0

	queue_redraw()
	
func _draw() -> void:
	if player == null:
		return
	
	#Draw background
	draw_circle(radar_size / 2.0, radar_size.x / 2.0, Color(0, 0, 0, 0.4))
	draw_circle(radar_size / 2.0, 2.5, Color.BLUE)
	#Draw enemies
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if not enemy is Node2D:
			continue
		
		var offset : Vector2 = enemy.global_position - player.global_position
		if offset.length() > radar_range:
			continue
			
		var normalized := offset / radar_range
		var radar_pos := normalized * radar_size / 2.0 + radar_size / 2.0
		
		draw_circle(radar_pos, 2.5, Color.RED)

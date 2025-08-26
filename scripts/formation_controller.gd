extends Node2D

@export var fighter_scene: PackedScene
@export var speed: float = 150.0
@export var turn_speed: float = .5
@export var retreat_duration: float = 4.0
@export var retreat_distance: float = 300.0 #start retreat
@export var align_tolerance: float = 0.12

@export var slot_spring := 6.0     # pull‑back strength
@export var slot_damp   := 0.9     # friction
@export var max_drift   := 50.0    # distance before a hard snap

enum State { APPROACH, RETREAT, LOOP_BACK }
var state: State = State.APPROACH
var retreat_timer := 0.0

var fighters := []
var slots := []
var slot_vel := []

signal formation_destroyed

func _ready():
	 # Cache local offsets of each Marker2D once
	for child in get_children():
		if child is Marker2D:
			slots.append(child.position)

	face_player()
	spawn_formation()
	

func _process(delta: float) -> void:
	if not Globals.player or not Globals.player.is_inside_tree():
		return
		
	var to_player: Vector2 = Globals.player.global_position - global_position
	var target_rot: float  = to_player.angle() + PI / 2  
	var forward: Vector2 = Vector2.UP.rotated(rotation)
	var distance   = to_player.length()
		
	match state:
		State.APPROACH:
			to_player = Globals.player.global_position - global_position
			target_rot = to_player.angle() + PI / 2  
			rotation = lerp_angle(rotation, target_rot, turn_speed * delta)
		
			#var forward = Vector2.UP.rotated(rotation)
			position += forward * speed * delta
			
			# Let fighters shoot while approaching
			for f in fighters:
				if f:
					f.shoot()
					
			if distance < retreat_distance:
				state = State.RETREAT
				retreat_timer = 0.0
				
		State.RETREAT:
			var away_rot = (to_player * -1).angle() + PI / 2
			rotation = lerp_angle(rotation, away_rot, turn_speed * delta)
			position += Vector2.UP.rotated(rotation) * speed * delta
			
			retreat_timer += delta
			if retreat_timer >= retreat_duration:
				retreat_timer = 0.0
				state = State.LOOP_BACK
				
		State.LOOP_BACK:
			rotation = lerp_angle(rotation, target_rot, turn_speed * delta)
			position += Vector2.UP.rotated(rotation) * speed * delta
				
			if abs(short_angle_diff(rotation, target_rot)) < align_tolerance:
				state = State.APPROACH
				
	for f in fighters:
		if not is_instance_valid(f):
			continue

		var slot = slots[f.slot_index].rotated(rotation)
		var target_pos = global_position + slot
		var to_target = target_pos - f.global_position

		slot_vel[f.slot_index] += to_target * slot_spring * delta
		slot_vel[f.slot_index] *= pow(slot_damp, delta * 60)

		if to_target.length() > max_drift * 3.0:
			f.global_position = target_pos
			slot_vel[f.slot_index] = Vector2.ZERO
		else:
			f.global_position += slot_vel[f.slot_index] * delta

		

	  

func move_forward(delta: float) -> void:
	var forward = Vector2.RIGHT.rotated(rotation)
	position += forward * speed * delta


func spawn_formation() -> void:
	for f in fighters:
		if f:
			f.queue_free()
	fighters.clear()
	slot_vel.clear()

	for i in slots.size():
		var fighter = fighter_scene.instantiate()
		fighter.slot_index = i
		add_child(fighter)
		fighter.add_to_group("Enemies")
		fighters.append(fighter)
		fighter.fighter_died.connect(_on_fighter_died)
		
		slot_vel.append(Vector2.ZERO)


func face_player() -> void:
	if Globals.player and Globals.player.is_inside_tree():
		var to_player = Globals.player.global_position - global_position
		rotation = to_player.angle() + PI / 2
		
		
func short_angle_diff(a: float, b: float) -> float:
	return wrapf(b - a, -PI, PI)
	
	
func _on_fighter_died(fighter):
	fighters.erase(fighter)
	if fighters.is_empty():
		formation_destroyed.emit()
		queue_free()
		
		
func _kill_all_fighters() -> void:
	for f in fighters:
		f._take_damage(10)

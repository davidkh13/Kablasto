extends Control
class_name BonusPopup

@onready var popup_label: Label = $Label
@onready var bonus_sound := $AudioStreamPlayer
var speed := 200.0
var float_distance := 300.0
var distance_moved := 0.0
var last_viewport_width := 0.0

signal popup_complete

func set_bonus(value: int, bonus_type: String) -> void:
	popup_label.text = "+%d %s Bonus!" % [value, bonus_type]

	var screen_center = get_viewport().size * 0.5
	var label_half_size = popup_label.size * 0.5

	position = screen_center - label_half_size
	modulate = Color.LIGHT_GOLDENROD
	bonus_sound.play()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		
	var move_step = speed * delta
	position.y -= move_step
	distance_moved += move_step

	if distance_moved >= float_distance:
		emit_signal("popup_complete")
		queue_free()
		
		

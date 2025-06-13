extends Node2D
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
	modulate = Color.LIGHT_GOLDENROD
	position = get_viewport().get_visible_rect().size * 0.5
	bonus_sound.play()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var current_width = get_viewport().size.x
	if current_width != last_viewport_width:
		last_viewport_width = current_width
		_center_horizontally()
	
	var move_step = speed * delta
	position.y -= move_step
	distance_moved += move_step

	if distance_moved >= float_distance:
		emit_signal("popup_complete")
		queue_free()
		
		
func _center_horizontally() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		push_warning("No Camera2D found")
		return
		
	# Get the center of the camera view in world coordinates
	var screen_center = camera.get_screen_center_position()
		
	var rect = get_viewport().get_visible_rect()
	var viewport_width = get_viewport().size.x
	
	var font = popup_label.get_theme_font("font")
	var font_size = popup_label.get_theme_font_size("font_size")
	var text_width = font.get_string_size(popup_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	global_position.x = screen_center.x - (text_width / 2)

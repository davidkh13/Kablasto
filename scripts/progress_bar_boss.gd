extends ProgressBar

var last_viewport_width := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.y = get_viewport().size.y - 50
	_center_horizontally()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var current_width = get_viewport().size.x
	if current_width != last_viewport_width:
		last_viewport_width = current_width
		_center_horizontally()
		
	
	
func _center_horizontally() -> void:
	var viewport_width = get_viewport().size.x
	var container_width = size.x
	position.x = (viewport_width - container_width) / 2
	
	
func move_up() -> void:
	position.y = 125
	
func move_down() -> void:
	position.y = get_viewport().size.y - 50

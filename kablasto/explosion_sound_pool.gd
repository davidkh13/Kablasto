extends Node

@export var max_players := 20
@export var sound_stream: AudioStream

var pool: Array[AudioStreamPlayer2D] = []
var index := 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(max_players): #fill the audio pool
		var player = AudioStreamPlayer2D.new()
		player.stream = sound_stream
		add_child(player)
		pool.append(player)
		
func play_sound(position: Vector2):
	var player = pool[index]
	player.global_position = position
	player.attenuation = 0.0
	player.play()
	index = (index + 1) % pool.size()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

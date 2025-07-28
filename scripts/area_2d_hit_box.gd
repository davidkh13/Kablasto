extends Area2D

const SOUND_CRASH = preload("res://crash.wav")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
func _play_sound(stream: AudioStream) -> void :
	var sound_player = AudioStreamPlayer2D.new()
	sound_player.stream = stream
	add_child(sound_player)
	sound_player.play()
	sound_player.finished.connect(func(): sound_player.queue_free())


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		_play_sound(SOUND_CRASH)
		body.take_damage(10)

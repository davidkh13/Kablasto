extends CanvasLayer


@onready var credits = $Label
@onready var screen_size = get_viewport().get_visible_rect().size

@export var scroll_speed := 15.0  # pixels per second
@export var wait_before_scroll := 1.5  # delay before scrolling starts
@export var fade_out_after := 1.5  # delay after credits finish

var scroll_started := false
var finished := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	$Label.bbcode_enabled = true
	$Label.text = """
[center][b]Kablasto[/b]
A Game by David Henson
[color=#aaaaaa]© 2025[/color]


[b]Asteroid Wrangler[/b]
David "Manga" Henson


[b]Button Mashing[/b]
David "Trigger Fingers" Henson


[b]Crayon Department[/b]
David "Doodles" Henson


[b]Coffee Procurement[/b]
Dave's Java Hut


[b]Pew Pew and Other Strange Noises[/b]
David "Madman" Henson


[b]Lullaby Recording[/b]
David "Bebop" Henson


[b]Nap Time Specialist[/b]
David "ZZZZZ" Henson


[b]Unknown Transmissions[/b]
[i]“gamecodeplus13.blogspot.com”[/i]


[b]Special Thanks[/b]
Godot Engine, ChatGPT, Blender, Gimp, OpenMPT, Audacity
And you - thanks for playing!


[b]License[/b]
Free to play. Please share and enjoy!



This is a work of fiction.
So, any resemblance to actual persons, living or dead,
or actual events… would be pretty funny, right?
[/center]
"""
	credits.set_size(Vector2(screen_size.x * 0.8, 10000)) # Large height to allow scroll
	credits.position = Vector2((screen_size.x - credits.size.x) / 2, screen_size.y)

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if scroll_started and not finished:
		credits.position.y -= scroll_speed * delta

		# Once it's scrolled completely out of view
		if credits.position.y + credits.size.y < 0:
			finished = true
			await get_tree().create_timer(fade_out_after).timeout
			# Replace this with your own signal/scene transition
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func start_scroll() -> void:
	visible = true
	await get_tree().process_frame
	scroll_started = true

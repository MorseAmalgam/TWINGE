extends ChatTrigger

@export var sound:AudioStream
var player:AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.stream = sound
	player.max_polyphony = 10
	add_child(player)
	pass

func run(_command_user, _message):
	player.play()
	pass

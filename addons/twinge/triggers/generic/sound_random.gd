extends ChatTrigger

@export var sounds:Array[AudioStream]
var player:AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.max_polyphony = 10
	add_child(player)
	pass

func run(_command_user, _message):
	player.stream = sounds.pick_random()
	player.play()
	pass

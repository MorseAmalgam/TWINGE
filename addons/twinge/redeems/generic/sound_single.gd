extends TwingeSoundRedeemTemplate

@export var sound:AudioStream

func run(_command_user, _details)->bool:
	player.stream = sound
	player.play()
	return true

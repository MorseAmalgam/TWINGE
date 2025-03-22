extends TwingeSoundRedeemTemplate

@export var sound:AudioStream

func run(_user, _details)->bool:
	player.stream = sound
	player.play()
	return true

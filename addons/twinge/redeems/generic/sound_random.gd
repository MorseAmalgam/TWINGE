extends TwingeSoundRedeemTemplate

@export var sounds:Array[AudioStream]

func run(_user, _details)->bool:
	player.stream = sounds.pick_random()
	player.play()
	return true

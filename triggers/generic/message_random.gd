extends ChatTrigger

@export var responses:Array[String]

func run(_command_user, _message):
	get_parent().twinge.endpoint("send_message", [responses.pick_random()])
	pass

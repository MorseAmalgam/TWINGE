extends ChatTrigger

@export var responses:Array[String]

func run(_command_user, _message):
	for response in responses:
		get_parent().twinge.endpoint("send_message", [response])
	pass

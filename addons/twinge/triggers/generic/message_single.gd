extends ChatTrigger

@export var response:String

func run(_command_user, _message):
	get_parent().twinge.endpoint("send_message", [response])
	pass

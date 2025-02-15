extends TwingePointRedeemTemplate

@export var responses:Array[String]

func run(_command_user, _details)->bool:
	get_parent().twinge.endpoint("send_message", [responses.pick_random()])
	return true

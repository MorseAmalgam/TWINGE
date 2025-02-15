extends TwingePointRedeemTemplate

@export var response:String

func run(_command_user, _details)->bool:
	get_parent().twinge.endpoint("send_message", [response])
	return true

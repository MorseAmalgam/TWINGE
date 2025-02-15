extends TwingePointRedeemTemplate

@export var responses:Array[String]

func run(_command_user, _details)->bool:
	for response in responses:
		await get_parent().twinge.endpoint("send_message", [response])
	return true

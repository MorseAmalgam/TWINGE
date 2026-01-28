extends TwingeModule
class_name TwingeRaidModule
## Implements features related to raids.

signal start_raid(details)
signal cancel_raid(details)
signal channel_raided(details)

func get_scopes() -> Array[String]:
	return [
		# Used to start or cancel a raid
		"channel:manage:raids",
	]


func get_event_subscriptions() -> Array:
	twinge.eventsub.event_received.connect(_handle_event)
	return [
		{ 
			"event": "channel.raid",
			"condition": {
				"to_broadcaster_user_id":"broadcaster_user_id"
			}
		},
		{ 
			"event": "channel.raid",
			"condition": {
				"from_broadcaster_user_id":"broadcaster_user_id"
			}
		},
	]


func _ready():
	service_identifier = "Module-Raids"
	twinge.register_endpoint("start_raid", self, "_start_raid")
	twinge.register_endpoint("cancel_raid", self, "_cancel_raid")

	twinge.register_hook("start_raid", start_raid)
	twinge.register_hook("channel_raided", channel_raided)


func _handle_channel_raid(details):
	if (details.from_broadcaster_user_id == twinge.credentials.broadcaster_user_id):
		details.user_target = await twinge.get_user(details.to_broadcaster_user_id)
		start_raid.emit(details)
		pass
	elif (details.to_broadcaster_user_id == twinge.credentials.broadcaster_user_id):
		details.user_raid_leader = await twinge.get_user(details.from_broadcaster_user_id)
		channel_raided.emit(details)
		pass
	pass

func _start_raid(raid_target:String):
	var res = await twinge.api.query(
		self,
		"raids",
		{},
		{	
			"from_broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"to_broadcaster_id" : raid_target
		},
		HTTPClient.METHOD_POST
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	pass

func _cancel_raid():
	var res = await twinge.api.query(
		self,
		"raids",
		{},
		{	
			"broadcaster_id" : twinge.credentials.broadcaster_user_id
		},
		HTTPClient.METHOD_DELETE
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	pass

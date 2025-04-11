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
	if (details.from_broadcaster_id == twinge.credentials.broadcaster_user_id):
		start_raid.emit(details)
		pass
	elif (details.to_broadcaster_id == twinge.credentials.broadcaster_user_id):
		channel_raided.emit(details)
		pass
	pass

func _start_raid():
	pass

func _cancel_raid():
	pass

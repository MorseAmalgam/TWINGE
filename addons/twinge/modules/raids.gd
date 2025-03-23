extends TwingeModule
class_name TwingeRaidModule
## Implements features related to raids.

signal start_raid(details)
signal cancel_raid(details)
signal channel_raid(details)

func get_scopes() -> Array[String]:
	return [
		# Used to start or cancel a raid
		"channel:manage:raids",
	]


func get_event_subscriptions() -> Array:
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


func _handle_channel_raid(details):
	pass

func _start_raid():
	pass

func _cancel_raid():
	pass

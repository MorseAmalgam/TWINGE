extends TwingeModule
## (AFFILIATE+) Implements polls and predictions.

@export_category("Twitch Capabilities")
## Read allows the module to watch for events related to polls.
## Read & Manage allows the module to also create and manage polls.
@export_enum("None", "Read", "Read & Manage") var allow_polls = 0
## Read allows the module to watch for events related to predictions.
## Read & Manage allows the module to also create and manage predictions.
@export_enum("None", "Read", "Read & Manage") var allow_predictions = 0

func get_scopes() -> Array[String]:
	var scopes:Array[String] = [
		"user:bot", "channel:bot"
	]
	if (allow_polls == 1):
		# Can get info on active polls, and process when they end.
		scopes.append("channel:read:polls")
	elif (allow_polls == 2):
		# Used to start, end, and track polls.
		scopes.append("channel:manage:polls")
	if (allow_predictions == 1):
		# Can get info on active polls, and process when they end.
		scopes.append("channel:read:predictions")
	elif (allow_predictions == 2):
		# Used to start, end, and track polls.
		scopes.append("channel:manage:predictions")
	return scopes


func get_event_subscriptions() -> Array:
	twinge.eventsub.event_received.connect(_handle_event)
	var events:Array
	if (0 < allow_polls):
		events.append_array([
		{ 
			"event": "channel.poll.begin",
			"condition": {
			}
		},
		{ 
			"event": "channel.poll.progress",
			"condition": {
			}
		},
		{ 
			"event": "channel.poll.end",
			"condition": {
			}
		},
		])
	
	if (0 < allow_predictions):
		events.append_array([
		{ 
			"event": "channel.prediction.begin",
			"condition": {
			}
		},
		{ 
			"event": "channel.prediction.progress",
			"condition": {
			}
		},
		{ 
			"event": "channel.prediction.lock",
			"condition": {
			}
		},
		{ 
			"event": "channel.prediction.end",
			"condition": {
			}
		},
		])
	return events


func _ready():
	service_identifier = "Module-Polls&Predictions"
	if (0 < allow_polls):
		twinge.register_endpoint("get_polls", self, "_get_polls")
	if (allow_polls == 2):
		twinge.register_endpoint("create_poll", self, "_create_poll")
		twinge.register_endpoint("end_poll", self, "_end_poll")
	if (0 < allow_predictions):
		twinge.register_endpoint("get_predictions", self, "_get_predictions")
	if (allow_predictions == 2):
		twinge.register_endpoint("create_prediction", self, "_create_prediction")
		twinge.register_endpoint("end_prediction", self, "_end_prediction")


func _handle_channel_poll_begin(details):
	pass


func _handle_channel_poll_progress(details):
	pass


func _handle_channel_poll_end(details):
	pass


func _handle_channel_prediction_begin(details):
	pass


func _handle_channel_prediction_progress(details):
	pass


func _handle_channel_prediction_lock(details):
	pass


func _handle_channel_prediction_end(details):
	pass

func _get_polls():
	pass

func _create_poll():
	pass

func _end_poll():
	pass

func _get_predictions():
	pass

func _create_prediction():
	pass

func _end_prediction():
	pass

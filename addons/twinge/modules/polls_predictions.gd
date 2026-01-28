extends TwingeModule
class_name TwingePollPredictionModule
## (AFFILIATE+) Implements polls and predictions.

@export_category("Twitch Capabilities")
## Read allows the module to watch for events related to polls.
## Read & Manage allows the module to also create and manage polls.
@export_enum("None", "Read", "Read & Manage") var allow_polls = 0
## Read allows the module to watch for events related to predictions.
## Read & Manage allows the module to also create and manage predictions.
@export_enum("None", "Read", "Read & Manage") var allow_predictions = 0

var current_poll
var last_poll
var current_prediction
var last_prediction

signal channel_poll_begin
signal channel_poll_progress
signal channel_poll_end
signal channel_prediction_begin
signal channel_prediction_progress
signal channel_prediction_lock
signal channel_prediction_end


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
		twinge.register_endpoint("lock_prediction", self, "_lock_prediction")
		twinge.register_endpoint("resolve_prediction", self, "_resolve_prediction")
		twinge.register_endpoint("cancel_prediction", self, "_cancel_prediction")


func _handle_channel_poll_begin(details):
	current_poll = details
	channel_poll_begin.emit(details)
	pass


func _handle_channel_poll_progress(details):
	current_poll = details
	channel_poll_progress.emit(details)
	pass


func _handle_channel_poll_end(details):
	last_poll = details
	current_poll = null
	channel_poll_end.emit(details)
	pass


func _handle_channel_prediction_begin(details):
	current_prediction = details
	channel_prediction_begin.emit(details)
	pass


func _handle_channel_prediction_progress(details):
	details = await _propagate_user_arrays(details)
	current_prediction = details
	
	# Emit our signal
	channel_prediction_progress.emit(details)
	pass


func _handle_channel_prediction_lock(details):
	details = await _propagate_user_arrays(details)
	current_prediction = details
	
	# Emit our signal
	channel_prediction_lock.emit(details)
	pass


func _handle_channel_prediction_end(details):
	details = await _propagate_user_arrays(details)
	last_prediction = details
	current_prediction = null
	
	# Emit our signal
	channel_prediction_end.emit(details)
	pass

func _propagate_user_arrays(details):
	var outcomes: Array = []
	for outcome in details.outcomes:
		var top_predictors: Array = []
		for prediction in outcome.top_predictors:
			var predictor = {
				"user": await twinge.get_user(prediction.user_id),
				"channel_points_used":prediction.channel_points_used,
				"channel_points_won":prediction.channel_points_won
			}
			top_predictors.append(predictor)
		outcome.user_top_predictors = top_predictors
		outcomes.append(outcome)
	details.outcomes = outcomes
	
	return details

# AAAA THIS FUNCTION SUCKS
#func _get_polls(poll_ids:Array = []):
	## Twitch does a weird thing and allows you to include the same parameter over and over. 
	## This messes with all logical implementations of how to handle inputting a list of ids.
	## It also completely conflicts with how tmi.gd handles requests, making all of this VERY problematic.
	#if poll_ids.size() > 0:
		#var poll_uri = "&id=".join(following.slice(index, index + count_per_request))
		#var result = await twinge.api.query(
			#self,
			#"streams?first=%s&type=live&user_id=%s" % [count_per_request, user_ids]
			#)
	#var response = await twinge.api.query(
		#self,
		#"polls",
		#{},
		#{
			#"broadcaster_id" : twinge.credentials.broadcaster_user_id
		#}
	#)
#
	#if response.code < 300:
		#pass
	#pass

func _create_poll(title:String, choices:Array[String], duration:int, channel_point_cost:int=0):
	# Create our request body
	var choices_array: Array
	for choice in choices:
		choices_array.append({
			"title":choice
		})
	var request_body = {
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"title": title,
			"choices":choices_array,
			"duration": duration
		}
	
	if channel_point_cost > 0:
		request_body.channel_points_voting_enabled = "true"
		request_body.channel_points_per_vote = channel_point_cost
		
	var response = await twinge.api.query(
		self,
		"polls",
		{},
		request_body,
		HTTPClient.METHOD_POST
	)
	if response.code < 300:
		return response.data
	debug_message("Twitch returned invalid response: %s" % response.code, DebugType.ERROR)
	pass

func _end_poll(archive:bool = false):
	if current_poll == null:
		debug_message("No poll to end, skipping.")
		return
		
	var response = await twinge.api.query(
		self,
		"polls",
		{},
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"id" : current_poll.id,
			"status": "ARCHIVED" if archive else "TERMINATED"
		},
		HTTPClient.METHOD_PATCH
	)
	if response.code < 300:
		return response.data
	debug_message("Twitch returned invalid response: %s" % response.code, DebugType.ERROR)
	pass

#func _get_predictions():
	#pass

func _create_prediction(title:String, outcomes:Array, prediction_window:int):
	# Create our request body
	var outcomes_array: Array
	for outcome in outcomes:
		outcomes_array.append({
			"title":outcome
		})

	var response = await twinge.api.query(
		self,
		"predictions",
		{},
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"title": title,
			"outcomes":outcomes_array,
			"prediction_window": prediction_window
		},
		HTTPClient.METHOD_POST
	)
	if response.code < 300:
		return response.data
	debug_message("Twitch returned invalid response: %s" % response.code, DebugType.ERROR)
	pass

func _lock_prediction():
	if current_prediction == null:
		debug_message("No prediction to end, skipping.")
		return
		
	var response = await twinge.api.query(
		self,
		"predictions",
		{},
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"id" : current_prediction.id,
			"status": "LOCKED"
		},
		HTTPClient.METHOD_PATCH
	)
	if response.code < 300:
		return response.data
	debug_message("Twitch returned invalid response: %s" % response.code, DebugType.ERROR)
	pass

func _resolve_prediction(outcome_id:String):
	if current_prediction == null:
		debug_message("No prediction to end, skipping.")
		return
		
	var response = await twinge.api.query(
		self,
		"predictions",
		{},
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"id" : current_prediction.id,
			"status": "RESOLVED",
			"winning_outcome_id":outcome_id
		},
		HTTPClient.METHOD_PATCH
	)
	if response.code < 300:
		return response.data
	debug_message("Twitch returned invalid response: %s" % response.code, DebugType.ERROR)
	pass

func _cancel_prediction():
	if current_prediction == null:
		debug_message("No prediction to end, skipping.")
		return
		
	var response = await twinge.api.query(
		self,
		"predictions",
		{},
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"id" : current_prediction.id,
			"status": "CANCELED"
		},
		HTTPClient.METHOD_PATCH
	)
	if response.code < 300:
		return response.data
	debug_message("Twitch returned invalid response: %s" % response.code, DebugType.ERROR)
	pass

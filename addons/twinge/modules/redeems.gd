extends TwingeModule
class_name TwingeRedeemsModule
## (AFFILIATE+) Implements channel point redeem features.

@export_enum("None", "Read", "Read & Manage") var allow_redeems = 0

var redeems = {}

func get_scopes() -> Array[String]:
	var scopes:Array[String] = [
		"user:bot", "channel:bot"
	]
	if (allow_redeems == 1):
		# Used to read channel point information
		scopes.append("channel:read:redemptions")
	elif (allow_redeems == 2):
		# Used to manage channel point redeems
		scopes.append("channel:manage:redemptions")

	return scopes

func get_event_subscriptions() -> Array:
	twinge.eventsub.event_received.connect(_handle_event)
	var events:Array
	if (0 < allow_redeems):
		events.append_array([
		{ 
			"event": "channel.channel_points_automatic_reward_redemption.add",
			"condition": {}
		},
		{ 
			"event": "channel.channel_points_custom_reward.add",
			"condition": {}
		},
		{ 
			"event": "channel.channel_points_custom_reward.update",
			"condition": {}
		},
		{ 
			"event": "channel.channel_points_custom_reward.remove",
			"condition": {}
		},
		{ 
			"event": "channel.channel_points_custom_reward_redemption.add",
			"condition": {}
		},
		{ 
			"event": "channel.channel_points_custom_reward_redemption.update",
			"condition": {}
		},
	])
	
	return events

func _ready():
	super()
	service_identifier = "Module-Redeems"
	if (0 < allow_redeems):
		twinge.register_endpoint("get_redeem_list", self, "_get_custom_rewards")
		twinge.register_endpoint("create_redeem", self, "_create_redeem")
		twinge.register_endpoint("update_redeem", self, "_update_redeem")
		twinge.register_endpoint("delete_redeem", self, "_delete_redeem")
		twinge.register_endpoint("get_redeem_redemptions", self, "_get_custom_reward_redemption")

func _on_twinge_connected():
	# Get rewards
	await _update_custom_reward_list()

	# Only attempt to create redeems if we have permission
	if (allow_redeems < 2):
		return

	for redeem in get_children():
		if not (redeem is TwingePointRedeemTemplate):
			continue
		redeem = redeem as TwingePointRedeemTemplate
		# Redeem exists, just pass the ID back
		if redeems.has(redeem.title):
			debug_message("Redeem %s is already registered, capturing ID and updating on Twitch." % redeem.title)
			redeem.twitch_redeem_id = redeems[redeem.title]
			await _update_redeem(redeem)
			continue
		else:
			# New redeem, register with Twitch
			debug_message("Creating redeem for %s" % redeem.title)
			var response = await _create_redeem(redeem)
			redeem.twitch_redeem_id = response.id
	pass

func _get_custom_rewards():
	pass

func _update_custom_reward_list(only_manageable:bool = true):
	var response = await twinge.api.query(
		self,
		"channel_points/custom_rewards",
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"only_manageable_rewards" : only_manageable
		}
	)
	
	if (response.code != 200):
		return
		
	for reward in response.data.data:
		redeems[reward.title] = reward.id
	pass

func _get_custom_reward_redemption():
	pass


func _create_redeem(redeem:TwingePointRedeemTemplate):
	var redeem_data = {
		"title":redeem.title,
		"cost":redeem.cost
	}
	
	if (redeem.is_enabled):
		redeem_data.is_enabled = true
	
	if (redeem.background_color != null):
		redeem_data.background_color = "#%s" % redeem.background_color.to_html(false)
	
	if (redeem.is_user_input_required):
		redeem_data.is_user_input_required = true
	
	if (0 < redeem.max_per_stream):
		redeem_data.is_max_per_stream_enabled = true
		redeem_data.max_per_stream = redeem.max_per_stream
	
	if (0 < redeem.max_per_user_per_stream):
		redeem_data.is_max_per_user_per_stream_enabled = true
		redeem_data.max_per_user_per_stream = redeem.max_per_user_per_stream
	
	if (0 < redeem.global_cooldown_seconds):
		redeem_data.is_global_cooldown_enabled = true
		redeem_data.global_cooldown_seconds = redeem.global_cooldown_seconds
	
	if (!redeem.description.is_empty()):
		redeem_data.prompt = redeem.description
	
	if (redeem.auto_complete_redemption):
		redeem_data.should_redemptions_skip_queue = true
	
	var response = await twinge.api.query(
		self,
		"channel_points/custom_rewards",
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id
		},
		redeem_data,
		HTTPClient.METHOD_POST
	)
	
	if response.code == 200:
		return response.data.data[0]
		
	if (response.code == 400 and response.data.contains("CREATE_CUSTOM_REWARD_DUPLICATE_REWARD")):
		pass
	pass

func _update_redeem(redeem:TwingePointRedeemTemplate):
	var redeem_data = {
		"title":redeem.title,
		"cost":redeem.cost
	}
	
	redeem_data.is_enabled = redeem.is_enabled
	
	redeem_data.background_color = "#%s" % redeem.background_color.to_html(false)
	
	redeem_data.is_user_input_required = redeem.is_user_input_required

	redeem_data.is_max_per_stream_enabled = 0 < redeem.max_per_stream
	redeem_data.max_per_stream = redeem.max_per_stream
	
	redeem_data.is_max_per_user_per_stream_enabled = 0 < redeem.max_per_user_per_stream
	redeem_data.max_per_user_per_stream = redeem.max_per_user_per_stream

	redeem_data.is_global_cooldown_enabled = 0 < redeem.global_cooldown_seconds
	redeem_data.global_cooldown_seconds = redeem.global_cooldown_seconds
	
	redeem_data.prompt = redeem.description
	
	redeem_data.should_redemptions_skip_queue = redeem.auto_complete_redemption
	
	var response = await twinge.api.query(
		self,
		"channel_points/custom_rewards",
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"id":redeem.twitch_redeem_id
		},
		redeem_data,
		HTTPClient.METHOD_PATCH
	)
	response = response
	pass

func _delete_redeem(redeem:TwingePointRedeem):
	var response = await twinge.api.query(
		self,
		"channel_points/custom_rewards",
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"id":redeem.id
		},
		{},
		HTTPClient.METHOD_DELETE
	)
	pass

func _handle_channel_channel_points_custom_reward_redemption_add(details):
	var user = await twinge.get_user(details.user_id, true)
	for redeem in get_children():
		if not (redeem is TwingePointRedeemTemplate):
			continue
		redeem = redeem as TwingePointRedeemTemplate
		if (redeem.twitch_redeem_id != details.reward.id):
			continue

		_update_redemption_status(details.reward.id, details.id, await redeem.call("run", user, details))
	pass

func _update_redemption_status(redeem_id, redemption_id, fulfilled:bool = true):
	var response = await twinge.api.query(
		self,
		"channel_points/custom_rewards/redemptions",
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"reward_id" : redeem_id,
			"id":redemption_id
		},
		{
			"status": "FULFILLED" if fulfilled else "CANCELED"
		},
		HTTPClient.METHOD_PATCH
	)
	pass

extends TwingeModule
class_name TwingeMonetizationModule
## (AFFILIATE+) Implements events and endpoints related to features that generate streamer revenue. This includes ads, bits/cheers, subscription events, and hype trains.

@export_category("Twitch Capabilities")
@export_enum("None", "Read", "Read & Manage") var allow_ads = 0
@export_enum("None", "Read") var allow_bits = 0
@export_enum("None", "Read") var allow_subscriptions = 0
@export_enum("None", "Read") var allow_hype_trains = 0


var subscribers: Dictionary
var latest_subscriber: TwingeUser
var current_hype_train: Dictionary
var best_hype_train: Dictionary
var best_shared_hype_train: Dictionary

signal channel_ad_break_begin(details)
signal channel_ad_break_end(details)
signal channel_cheer(details)
signal channel_subscribe(details)
signal channel_subscription_end(details)
signal channel_subscription_gift(details)
signal channel_subscription_message(details)
signal channel_hype_train_begin(details)
signal channel_hype_train_progress(details)
signal channel_hype_train_end(details)

func get_scopes() -> Array[String]:
	var scopes:Array[String] = [
		"user:bot", "channel:bot"
	]
	if (0 < allow_ads):
		# Used to get the ad schedule and trigger on the start of an ad break.
		scopes.append("channel:read:ads")
	if (allow_ads == 2):
		# Weirdly only used for snoozing the next ad, not starting one.
		scopes.append("channel:manage:ads")
		# Used solely for starting an ad break.
		scopes.append("channel:edit:commercial")
	if (allow_bits):
		# Get bit events
		scopes.append("bits:read")
	if (allow_subscriptions):
		# Get subscription events
		scopes.append("channel:read:subscriptions")
	if (allow_hype_trains):
		# Get subscription events
		scopes.append("channel:read:hype_train")
	return scopes


func get_event_subscriptions() -> Array:
	twinge.eventsub.event_received.connect(_handle_event)
	var events:Array
	if (0 < allow_ads):
		events.append(
		{ 
			"event": "channel.ad_break.begin",
			"condition": {
			}
		})
	
	if (allow_bits):
		events.append(
		{ 
			"event": "channel.cheer",
			"condition": {
			}
		})
	
	if (allow_subscriptions):
		events.append_array([
		{ 
			"event": "channel.subscribe",
			"condition": {
			}
		},
		{ 
			"event": "channel.subscription.end",
			"condition": {
			}
		},
		{ 
			"event": "channel.subscription.gift",
			"condition": {
			}
		},
		{ 
			"event": "channel.subscription.message",
			"condition": {
			}
		},
		])
	if (allow_hype_trains):
		events.append_array([
		{ 
			"event": "channel.hype_train.begin",
			"version":2,
			"condition": {
			}
		},
		{ 
			"event": "channel.hype_train.progress",
			"version":2,
			"condition": {
			}
		},
		{ 
			"event": "channel.hype_train.end",
			"version":2,
			"condition": {
			}
		}
	])
	
	return events


func _ready():
	super()
	service_identifier = "Module-Monetization"
	if (0 < allow_ads ):
		create_hook("channel_ad_break_begin", channel_ad_break_begin)
		create_hook("channel_ad_break_end", channel_ad_break_end)
	if (allow_ads == 2):
		twinge.register_endpoint("start_ad_break", self, "_run_ads")
		twinge.register_endpoint("snooze_next_ad", self, "_snooze_next_ad")
		twinge.register_endpoint("get_ad_schedule", self, "_get_ad_schedule")
	if (allow_bits):
		create_hook("channel_cheer", channel_cheer)
		twinge.register_endpoint("get_bits_leaderboard", self, "_get_bits_leaderboard")
	if (allow_subscriptions):
		# First-time subscriptions and gift subs
		create_hook("channel_subscribe", channel_subscribe)
		# Subscription Ends
		create_hook("channel_subscription_end", channel_subscription_end)
		# Someone has gifted subs
		create_hook("channel_subscription_gift", channel_subscription_gift)
		# Resubscription
		create_hook("channel_subscription_message", channel_subscription_message)
		twinge.register_endpoint("get_subscribers", self, "_get_subscribers")
	if (allow_hype_trains):
		create_hook("channel_hype_train_begin", channel_hype_train_begin)
		create_hook("channel_hype_train_progress", channel_hype_train_progress)
		create_hook("channel_hype_train_end", channel_hype_train_end)
		twinge.register_endpoint("get_hype_train_events", self, "_get_hype_train_events")


func _on_twinge_connected():
	_update_subscribers()
	_update_hype_train_stats()
	# Updating every five minutes to ensure nothing has changed - Probably overkill but w/e
	_create_heartbeat(_update_metrics_info, 60 * 5)
	pass


func _update_metrics_info():
	_update_subscribers()
	_update_hype_train_stats()

func _handle_channel_ad_break_begin(details):
	channel_ad_break_begin.emit(details)
	await get_tree().create_timer(details.duration_seconds).timeout
	_handle_channel_ad_break_end({})
	pass


func _handle_channel_ad_break_end(details):
	pass


func _handle_channel_cheer(details):
	var user = await twinge.get_user(details.user_id)
	details.user = user
	channel_cheer.emit(details)
	pass


func _handle_channel_subscribe(details):
	var user = await twinge.get_user(details.user_id)
	details.user = user
	channel_subscribe.emit(details)
	pass


#func _handle_channel_subscribe_end(details):
	#pass


func _handle_channel_subscribe_gift(details):
	var user = await twinge.get_user(details.user_id)
	details.user = user
	channel_subscription_gift.emit(details)
	pass

func _handle_channel_subscription_message(details):
	var user = await twinge.get_user(details.user_id)
	details.user = user
	channel_subscription_message.emit(details)
	pass

func _handle_hype_train_begin(details):
	# Propagate user objects
	details = await _propagate_user_arrays(details)
	# Emit our signal
	channel_hype_train_begin.emit(details)
	pass

func _handle_hype_train_progress(details):
	# Propagate user objects
	details = await _propagate_user_arrays(details)
	# Emit our signal
	channel_hype_train_progress.emit(details)
	pass

func _handle_hype_train_end(details):
	# Propagate user objects
	details = await _propagate_user_arrays(details)
	# Emit our signal
	channel_hype_train_end.emit(details)
	pass

func _propagate_user_arrays(details):
	# Populate contributor array with TwingeUser data
	var top_contributors:Array = []
	for contribution in details.top_contributions:
		var contributor = {
			"user":await twinge.get_user(contribution.user_id),
			"type":contribution.type,
			"total":contribution.total
		}
		top_contributors.append(contributor)
	
	# Emit our signal
	details.user_top_contributions = top_contributors
	
	# Populate participant array with TwingeUser data
	if details.is_shared_train:
		var train_participants:Array = []
		for participant in details.shared_train_participants:
			train_participants.append(await twinge.get_user(participant.broadcaster_user_id))
		details.user_shared_train_participants = train_participants
	
	return details

func _run_ads(length:int = 60):
	# Only works if the user is live - Do not continue if stream is offline.
	if (!twinge.stream_status.live):
		debug_message("Stream is not live, skipping.")
		return
	
	var res = await twinge.api.query(
		self,
		"channels/commercial",
		{},
		{	
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"length" : length
		},
		HTTPClient.METHOD_POST
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	pass


func _snooze_next_ad():
	# Only works if the user is live - Do not continue if stream is offline.
	if (!twinge.stream_status.live):
		debug_message("Stream is not live, skipping.")
		return
	
	var res = await twinge.api.query(
		self,
		"channels/ads/schedule/snooze",
		{},
		{	
			"broadcaster_id" : twinge.credentials.broadcaster_user_id
		},
		HTTPClient.METHOD_POST
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	pass


func _get_ad_schedule():
	var res = await twinge.api.query(
		self,
		"channels/ads",
		{},
		{	
			"broadcaster_id" : twinge.credentials.broadcaster_user_id
		}
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	return null


func _get_bits_leaderboard(count:int=10, period="all"):
	var res = await twinge.api.query(
		self,
		"bits/leaderboard",
		{},
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"count":count,
			"period":period
		}
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	return null

func _get_subscribers():
	return subscribers
	
func _update_subscribers(after:String=""):
	var result = await twinge.api.query(
		self,
		"subscriptions", 
		{ 
			"broadcaster_id": twinge.credentials.broadcaster_user_id, 
			"first": 100, 
			"after" : after 
		})
	if result != null and result.code == 200:
		for subscriber in result.data.data:
			if (!subscribers.has(subscriber.user_id)):
				var subinfo = SubscriptionInfo.new()
				subinfo.gifter_id = subscriber.gifter_id
				subinfo.is_gift = subscriber.is_gift
				subinfo.tier = int(subscriber.tier) / 1000
				subscribers[subscriber.user_id] = subinfo
		
		# More than 100 subscribers
		if result.data.pagination.has("cursor"):
			await _update_subscribers(result.data.pagination.cursor)
	return null

func get_current_hype_train():
	return current_hype_train

func get_best_hype_train():
	return best_hype_train
	
func get_shared_best_hype_train():
	return best_shared_hype_train
	
func _update_hype_train_stats():
	var response = await twinge.api.query(
		self,
		"hypetrain/status",
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id
		},
		{}
	)

	if response.code < 300:
		current_hype_train = response.data.data[0].current if response.data.data[0].current != null else {}
		best_hype_train = response.data.data[0].all_time_high if response.data.data[0].all_time_high != null else {}
		best_shared_hype_train = response.data.data[0].shared_all_time_high if response.data.data[0].shared_all_time_high != null else {}
		return response.data.data[0]
	debug_message("Twitch returned invalid response: %s" % response.code, DebugType.ERROR)
	pass

func enrich_user(user: TwingeUser) -> TwingeUser:
	user.extra["subscription_tier"] = -1
	if subscribers.has(user.id):
		user.extra["subscription_tier"] = subscribers[user.id].tier
	
	return user

extends TwingeModule
class_name TwingeChatModule
## Implements chat-related functionalities.

@export_category("Twitch Capabilities")
## Allows the fetching of a list of users currently in chat.
@export_enum("None", "Read") var allow_chatters = 0
@export_enum("None", "Read", "Read & Manage") var allow_chat = 0
@export_enum("None", "Read", "Read & Manage") var allow_whisper = 0
@export_enum("None", "Read", "Read & Manage") var allow_shoutout = 0
@export_enum("None", "Read & Manage") var allow_announcements = 0

var first_chat_tracker:Array
var chatters:Array

signal chat_message(details)
signal chat_first_time_message(details)
signal chat_first_session_message(details)
signal chat_message_delete(details)
signal chat_clear_user_messages(details)
signal chat_whisper(details)
signal shoutout_created(details)
signal shoutout_received(details)

func get_scopes() -> Array[String]:
	# Required for read/write to chat. It's weird, I know.
	var scopes:Array[String] = [
		"user:bot", "channel:bot"
	]
	# Get chat events - requires user:bot and channel:bot.
	if (allow_chatters == 1):
		scopes.append("moderator:read:chatters")
	if (0 < allow_chat):
		scopes.append("user:read:chat")
	if (allow_chat == 2):
		scopes.append("user:write:chat")
	if (allow_whisper == 1):
		scopes.append("user:read:whispers")
	elif (allow_whisper == 2):
		scopes.append("user:manage:whispers")
	if (allow_shoutout == 1):
		scopes.append("moderator:read:shoutouts")
	elif (allow_shoutout == 2):
		scopes.append("moderator:manage:shoutouts")
	if allow_announcements:
		scopes.append("moderator:manage:announcements")
	return scopes


func get_event_subscriptions() -> Array:
	twinge.eventsub.event_received.connect(_handle_event)
	var events:Array
	if (0 < allow_chat):
		events.append({ 
			"event": "channel.chat.message",
			"condition": {
				"user_id": "user_id"
			}
		})
		# These two feel debatable - 
		# Events can be subscribed for multiple modules, obviously, but it's
		# included here expressly with the expectation you would need to know
		# if a message was removed just as much as if a message was added.
		events.append({ 
			"event": "channel.chat.message_delete",
			"condition": {
				"user_id": "user_id"
			}
		})
		events.append({
			"event": "channel.chat.clear_user_messages",
			"condition": {
				"user_id": "user_id"
			}
		})
	if (0 < allow_whisper):
		events.append({
			"event": "user.whisper.message",
			"condition": {
				"user_id": "user_id",
			}
		})
	if (0 < allow_shoutout):
		events.append({
			"event": "channel.shoutout.create",
			"condition": {
				"moderator_user_id": "user_id"
			}
		})
		events.append({
			"event": "channel.shoutout.receive",
			"condition": {
				"moderator_user_id": "user_id"
			}
		})
	if allow_announcements && 0 < allow_chat:
		events.append({
			"event": "channel.chat.notification",
			"condition": {
				"user_id": "user_id"
			}
		})
	return events

func _ready():
	service_identifier = "ChatModule"
	
	if 0 < allow_chat:
		twinge.register_hook("channel_chat_message", chat_message)
		signals["channel_chat_message"] = chat_message
		twinge.register_hook("chat_first_time_message", chat_first_time_message)
		twinge.register_hook("chat_first_session_message", chat_first_session_message)
	
	if (allow_chatters == 1):
		twinge.register_endpoint("get_chatters", self, "_get_chatters")
	if allow_chat == 2:
		twinge.register_endpoint("send_message", self, "_send_message")
	if allow_whisper == 2:
		twinge.register_endpoint("send_whisper", self, "_send_whisper")
	if allow_shoutout == 2:
		twinge.register_endpoint("send_shoutout", self, "_send_shoutout")
	if allow_announcements:
		twinge.register_endpoint("send_announcement", self, "_send_announcement")


func _on_twinge_connected():
	update_metrics_info()
	# Updating every five minutes to ensure nothing has changed - Probably overkill but w/e
	_create_heartbeat(update_metrics_info, 60 * 5)
	pass

func update_metrics_info():
	# Reset the list
	chatters = []
	await _update_chatters()

func _handle_channel_chat_message(details):
	var message = {
			"id":details.message_id,
			"text":details.message.text.to_lower()
		}
	
	var user = await twinge.get_user(details.chatter_user_id, true)
	debug_message("Got user info")
	# First session chat for this user
	if (!first_chat_tracker.has(details.chatter_user_id)):
		#TODO: Check to see if they're a first time chatter
		
		chat_first_session_message.emit({"user":user})
		first_chat_tracker.append(details.chatter_user_id)
		pass
	
	
	for trigger in get_children():
		if not (trigger is TwingeTriggerTemplate):
			debug_message(trigger.name + " is not a trigger template")
			continue
		if !trigger.active:
			debug_message(trigger.name + " is not active")
			continue
		message["alias_matches"] = trigger.matches_alias(message.text)
		if (message["alias_matches"] == 0):
			debug_message(trigger.name + " failed alias check")
			continue
		if (!trigger.has_permission(user)):
			debug_message(trigger.name + " failed user permissions")
			continue
		

		trigger.call("run", user, message)
	pass


func _get_chatters():
	return chatters

func _update_chatters(after:String = ""):
	var result = await twinge.api.query(
		self,
		"chat/chatters", 
		{ 
			"broadcaster_id": twinge.credentials.broadcaster_user_id,
			"moderator_id": twinge.credentials.user_id,
			"first": 100, 
			"after" : after 
		})
	if result != null:
		if len(result.data.data) > 0:
			for chatter in result.data.data:
				if (!chatters.has(chatter.user_id)):
					chatters.append(chatter.user_id)
			
			# More than 100 mods??
			if result.data.pagination.has("cursor"):
				await _update_chatters(result.data.pagination.cursor)

func _send_message(message:String, in_reply_to:String=""):
	var res = await twinge.api.query(
		self,
		"chat/messages",
		{},
		{	
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"sender_id" : twinge.credentials.user_id,
			"message": message,
			"reply_parent_message_id" : in_reply_to
		},
		HTTPClient.METHOD_POST
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	pass

func _send_whisper(to_user:String, message:String):
	debug_message("Send Whisper called")
	# Broadcaster username was passed in instead of ID, find their ID
	if (!to_user.is_valid_int()):
		#TODO: Get User ID from name
		pass
	var res = await twinge.api.query(
		self,
		"whispers",
		{
			"from_user_id" : twinge.credentials.user_id,
			"to_user_id" : to_user
		},
		{
			"message":message
		},
		HTTPClient.METHOD_POST
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	pass


func _send_shoutout(streamer:String):
	debug_message("Send Shoutout called")
	# Only works if the user is live - Do not continue if stream is offline.
	if (!twinge.stream_status.live):
		debug_message("Stream is not live, skipping shoutout")
		return
	
	# Broadcaster username was passed in instead of ID, find their ID
	if (!streamer.is_valid_int()):
		#TODO: Get User ID from name
		pass
	var res = await twinge.api.query(
		self,
		"chat/shoutouts",
		{
			"from_broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"moderator_id" : twinge.credentials.user_id,
			"to_broadcaster_id": streamer,
		},
		{},
		HTTPClient.METHOD_POST
	)

	if res.code < 300:
		return res.data
	
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	pass


func _send_announcement(message:String, color:String="primary"):
	var res = await twinge.api.query(
		self,
		"chat/announcements",
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"moderator_id" : twinge.credentials.user_id,
		},
		{
			"message":message,
			"color":color
		},
		HTTPClient.METHOD_POST
	)

	if res.code < 300:
		return res.data
	pass

extends Resource
class_name TwingeSettings

@export_category("Streamer Account Info")
@export_enum("None", "Read") var allow_see_follows = 0
@export_category("Chat & Chat Related")
@export_enum("None", "Read", "Read & Manage") var allow_chat = 0
@export_enum("None", "Read", "Read & Manage") var allow_announcements = 0
@export_enum("None", "Read", "Read & Manage") var allow_shoutout = 0
@export_enum("None", "Read", "Read & Manage") var allow_whispers = 0
@export_category("Affiliate/Partner Capabilities")
@export_enum("None", "Read") var allow_cheers_bits = 0
@export_enum("None", "Read", "Read & Manage") var allow_ads = 0
@export_enum("None", "Read", "Read & Manage") var allow_polls = 0
@export_enum("None", "Read", "Read & Manage") var allow_predictions = 0
@export_enum("None", "Read", "Read & Manage") var allow_redeems = 0
@export_enum("None", "Read") var allow_hype_trains = 0
@export_enum("None", "Read") var allow_goals = 0
@export_category("User Metrics")
@export_enum("None", "Read") var allow_chatter_list = 0
@export_enum("None", "Read") var allow_follower_list = 0
@export_enum("None", "Read") var allow_subscriber_list = 0
@export_enum("None", "Read") var allow_vip_list = 0
@export_enum("None", "Read") var allow_moderator_list = 0
@export_category("Moderation")
@export_enum("None", "Read", "Read & Manage") var allow_moderators = 0
@export_enum("None", "Read", "Read & Manage") var allow_warnings = 0
@export_enum("None", "Manage") var allow_automod = 0
@export_enum("None", "Read", "Read & Manage") var allow_automod_settings = 0
@export_enum("None", "Read", "Read & Manage") var allow_moderate_messages = 0
@export_enum("None", "Read", "Read & Manage") var allow_user_bans = 0
@export_enum("None", "Read", "Read & Manage") var allow_blocked_terms = 0
@export_enum("None", "Read", "Read & Manage") var allow_chat_mode = 0
@export_enum("None", "Read", "Read & Manage") var allow_shield_mode = 0
@export_enum("None", "Read", "Read & Manage") var allow_blocked_users = 0
@export_enum("None", "Read", "Read & Manage") var allow_stream_info = 0
@export_enum("None", "Read", "Read & Manage") var allow_raids = 0
@export_enum("None", "Read") var allow_suspicious_users = 0

func get_scopes() -> Array[String]:
	var scopes:Array[String] = [
		"user:bot", "channel:bot"
	]
	# Streamer Info
	# This is for getting who THIS USER follows
	if (allow_see_follows == 1):
		scopes.append("user:read:follows")
	
	# Chat & Chat Related - requires user:bot and channel:bot.
	if (0 < allow_chat):
		scopes.append("user:read:chat")
	
	if (allow_chat == 2):
		scopes.append("user:write:chat")
	
	if (allow_announcements == 2):
		scopes.append("moderator:manage:announcements")
	
	if (allow_shoutout == 1):
		scopes.append("moderator:read:shoutouts")
	elif (allow_shoutout == 2):
		scopes.append("moderator:manage:shoutouts")
	
	if (allow_whispers == 1):
		scopes.append("user:read:whispers")
	elif (allow_whispers == 2):
		scopes.append("user:manage:whispers")
	
	# Affiliate / Partner Features
	if (allow_cheers_bits == 1):
		scopes.append("bits:read")
	if (0 < allow_ads):
		# Used to get the ad schedule and trigger on the start of an ad break.
		scopes.append("channel:read:ads")
	
	if (allow_ads == 2):
		# Weirdly only used for snoozing the next ad, not starting one.
		scopes.append("channel:manage:ads")
		# Used solely for starting an ad break.
		scopes.append("channel:edit:commercial")
	
	if (allow_polls == 1):
		scopes.append("channel:read:polls")
	elif (allow_polls == 2):
		scopes.append("channel:manage:polls")
	
	if (allow_predictions == 1):
		scopes.append("channel:read:predictions")
	elif (allow_predictions == 2):
		scopes.append("channel:manage:predictions")
	
	if (allow_redeems == 1):
		scopes.append("channel:read:redemptions")
	elif (allow_redeems == 2):
		scopes.append("channel:manage:redemptions")
	
	if (allow_hype_trains == 1):
		scopes.append("channel:read:hype_train")
	
	if (allow_goals == 1):
		scopes.append("channel:read:goals")


	# User Metrics
	if (allow_chatter_list == 1):
		scopes.append("moderator:read:chatters")
	
	if (allow_follower_list == 1):
		scopes.append("moderator:read:followers")
	
	if (allow_subscriber_list == 1):
		scopes.append("channel:read:subscriptions")
	
	if (allow_vip_list == 1):
		scopes.append("channel:read:vips")
	elif (allow_vip_list == 2):
		scopes.append("channel:manage:vips")
	
	if (allow_moderator_list == 1 or allow_moderators == 1):
		scopes.append("moderation:read")
	
	
	# Moderation
	if (allow_moderators == 2):
		scopes.append("channel:manage:moderators")
	
	if (allow_warnings == 1):
		scopes.append("channel:read:warnings")
	elif (allow_warnings == 2):
		scopes.append("channel:manage:warnings")
	
	if (allow_automod == 1):
		scopes.append("channel:manage:automod")
	
	if (allow_automod_settings == 1):
		scopes.append("moderator:read:automod_settings")
	elif (allow_automod_settings == 2):
		scopes.append("moderator:manage:automod_settings")
	
	if (allow_moderate_messages == 1):
		scopes.append("moderator:read:chat_messages")
	elif (allow_moderate_messages == 2):
		scopes.append("moderator:manage:chat_messages")
	
	if (allow_user_bans == 1):
		scopes.append("moderator:read:banned_users")
	elif (allow_user_bans == 2):
		scopes.append("moderator:manage:banned_users")
	
	if (allow_blocked_terms == 1):
		scopes.append("moderator:read:blocked_terms")
	elif (allow_blocked_terms == 2):
		scopes.append("moderator:manage:blocked_terms")
	
	if (allow_chat_mode == 1):
		scopes.append("moderator:read:chat_settings")
	elif (allow_chat_mode == 2):
		scopes.append("moderator:manage:chat_settings")
	
	if (allow_shield_mode == 1):
		scopes.append("moderator:read:shield_mode")
	elif (allow_shield_mode == 2):
		scopes.append("moderator:manage:shield_mode")
	
	if (allow_blocked_users == 1):
		scopes.append("moderator:read:blocked_users")
	elif (allow_blocked_users == 2):
		scopes.append("moderator:manage:blocked_users")
	
	if (allow_stream_info == 1):
		scopes.append("moderator:read:broadcast")
	elif (allow_stream_info == 2):
		scopes.append("moderator:manage:broadcast")
	
	if (allow_stream_info == 1):
		scopes.append("moderator:read:broadcast")
	
	if (allow_suspicious_users == 1):
		scopes.append("moderator:read:suspicious_users")
		
	# Listening for raids doesn't actually have a scope requirement??
	if (allow_raids == 2):
		scopes.append("channel:manage:raids")
		
	return scopes

extends TwingeModule
class_name TwingeChairtyModule
## (AFFILIATE+) Implements events and endpoints related to features that generate streamer revenue. This includes ads, bits/cheers, subscription events, and hype trains.

@export_category("Twitch Capabilities")
## Allows the reading of Charity EventSub events and API points.
@export_enum("None", "Read") var allow_charity = 0

var donations:Dictionary

signal channel_charity_campaign_donate(details)
signal channel_charity_campaign_start(details)
signal channel_charity_campaign_progress(details)
signal channel_charity_campaign_stop(details)

func get_scopes() -> Array[String]:
	var scopes:Array[String] = [
		"user:bot", "channel:bot"
	]
	if (0 < allow_charity):
		# Used to get charity campaign information.
		scopes.append("channel:read:charity")
	return scopes


func get_event_subscriptions() -> Array:
	twinge.eventsub.event_received.connect(_handle_event)
	var events:Array
	if (0 < allow_charity):
		events.append(
		{ 
			"event": "channel.charity_campaign.donate",
			"condition": {
			}
		})
		events.append(
		{ 
			"event": "channel.charity_campaign.start",
			"condition": {
			}
		})
		events.append(
		{ 
			"event": "channel.charity_campaign.progress",
			"condition": {
			}
		})
		events.append(
		{ 
			"event": "channel.charity_campaign.stop",
			"condition": {
			}
		})
	
	return events


func _ready():
	super()
	service_identifier = "Module-Monetization"
	if (0 < allow_charity ):
		create_hook("channel_charity_campaign_donate", channel_charity_campaign_donate)
		create_hook("channel_charity_campaign_start", channel_charity_campaign_start)
		create_hook("channel_charity_campaign_progress", channel_charity_campaign_progress)
		create_hook("channel_charity_campaign_stop", channel_charity_campaign_stop)
		twinge.register_endpoint("get_charity_campaign", self, "_get_campaign")
		twinge.register_endpoint("get_charity_campaign_donations", self, "_get_campaign_donations")

func _on_twinge_connected():
	update_metrics_info()
	# Updating every five minutes to ensure nothing has changed - Probably overkill but w/e
	_create_heartbeat(update_metrics_info, 60 * 5)
	pass


func update_metrics_info():
	# Reset the list
	donations = {}
	await _update_campaign_donations()


func _handle_channel_charity_campaign_donate(details):
	var user = await twinge.get_user(details.user_id)
	details.user = user
	
	var charity_logo = await utilities.fetch_image(self, details.charity_logo, "user://charity_%s.%s" % [details.campaign_id, details.charity_logo.get_extension()])
	details.charity_logo_image = charity_logo
	
	channel_charity_campaign_donate.emit(details)
	pass


func _handle_channel_charity_campaign_start(details):
	var charity_logo = await utilities.fetch_image(self, details.charity_logo, "user://charity_%s.%s" % [details.campaign_id, details.charity_logo.get_extension()])
	details.charity_logo_image = charity_logo
	
	channel_charity_campaign_start.emit(details)
	pass


func _handle_channel_charity_campaign_progress(details):
	var charity_logo = await utilities.fetch_image(self, details.charity_logo, "user://charity_%s.%s" % [details.campaign_id, details.charity_logo.get_extension()])
	details.charity_logo_image = charity_logo
	
	channel_charity_campaign_progress.emit(details)
	pass


func _handle_channel_charity_campaign_stop(details):
	var charity_logo = await utilities.fetch_image(self, details.charity_logo, "user://charity_%s.%s" % [details.campaign_id, details.charity_logo.get_extension()])
	details.charity_logo_image = charity_logo
	
	channel_charity_campaign_stop.emit(details)
	pass




func _get_campaign():
	var res = await twinge.api.query(
		self,
		"charity/campaigns",
		{},
		{	
			"broadcaster_id" : twinge.credentials.broadcaster_user_id
		}
	)

	if res.code < 300:
		return res.data
	debug_message("Twitch returned invalid response: %s" % res.code, DebugType.ERROR)
	return null

func _get_campaign_donations():
	return donations

func _update_campaign_donations(after:String = ""):
	var result = await twinge.api.query(
		self,
		"charity/donations",
		{},
		{
			"broadcaster_id" : twinge.credentials.broadcaster_user_id,
			"first":100,
			"after":after
		}
	)

	if result != null:
		if len(result.data.data) > 0:
			for donation in result.data.data:
				if (!donations.has(donation.id)):
					donations.set(donation.id, donation)
			
			# More than 100 donations
			if result.data.pagination.has("cursor"):
				await _update_campaign_donations(result.data.pagination.cursor)
				
	debug_message("Twitch returned invalid response: %s" % result.code, DebugType.ERROR)
	return null

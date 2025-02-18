extends TwingeModule
class_name TwingeHeatModule
## Enables functionality from the Heat Twitch extension.
# Scott Garner's Heatmap extension
# This must also be enabled on your channel via https://dashboard.twitch.tv/extensions/cr20njfkgll4okyrhag7xxph270sqk-2.1.1
# See https://github.com/scottgarner/Heat/ for documentation, though this module handles the connection aspects.

var socket = WebSocketPeer.new()


signal view_click_registered(details)


func _ready():
	super()
	service_identifier = "Module-SGarnerHeat"
	set_process(false)

func _on_twinge_connected():
	debug_message("Listening for Heat input.")
	twinge.register_hook("heat_event", view_click_registered)
	set_process(true)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var response = socket.get_packet().get_string_from_ascii()
			var json = JSON.parse_string(response)
			if json.type == "click":
				debug_message("Click Event")
				var profile = {}
				profile.id = json.id
				# Anonymous - No idea how this works
				if (json.id.begins_with("A")):
					profile.display_name = "Anonymous"
					profile.color = Color.WHITE
					profile.extra = {}
					pass
				# Unverified - User is logged in but has not given this extension access
				elif (json.id.begins_with("U")):
					profile.display_name = "Unverified"
					profile.color = Color.ORANGE
					profile.extra = {}
					pass
				# User is logged in and has given the extension access, so we have their user ID
				else:
					profile = await twinge.get_user(json.id, true)
				
				var screen_pos = Vector2(float(json.x), float(json.y)) * Vector2(get_viewport().size)
				
				debug_message("Captured click from %s" % profile.display_name)
				view_click_registered.emit(
					{
						"user": {
							"id": profile.id,
							"display_name": profile.display_name,
							"color": profile.color,
							"profile_image": profile.extra["profile_image"] if profile.extra.has("profile_image") else null
						},
						"position": screen_pos
					}
				)
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		# Attempt to reconnect
		socket.connect_to_url("wss://heat-api.j38.net/channel/%s" % twinge.credentials.broadcaster_user_id)

extends TwingeModule
class_name TwingeGreenHeatModule
## Enables functionality from the GreenHeat Twitch extension.
# Prodzpod's Heatmap extension
# This must also be enabled on your channel via https://dashboard.twitch.tv/extensions/yvswtbzy4fj9h89rk06e0wuw2ghfwv
# See https://heat.prod.kr/tutorial for documentation, though this module handles the connection aspects.

## If enabled, this module will treat clicks inside the Godot window as Heat events for debug purposes.
@export var capture_input:bool
## If enabled, this module will send Greenheat interactions as native InputEventMouse events.
@export var simulate_input:bool = false
var socket = WebSocketPeer.new()
var cursor_position_history:Dictionary[String, Vector2] = {}

#  (message.time + (message.latency * 1000)) + (some extra global latency from you to twitch)
# you could see the source if you know how to read javascript but essentially yeah, every object's position is snapshotted and saved for 30? seconds and fetched when a "slice" happens to compare against

signal view_hover_registered(details:Dictionary)
signal view_click_registered(details:Dictionary)
signal view_drag_registered(details:Dictionary)
signal view_release_registered(details:Dictionary)


func _ready():
	super()
	service_identifier = "Module-ProdzpodGreenHeat"
	set_process(false)

func _on_twinge_connected():
	debug_message("Listening for GreenHeat input.")
	twinge.register_hook("greenheat_hover_event", view_hover_registered)
	twinge.register_hook("greenheat_click_event", view_click_registered)
	twinge.register_hook("greenheat_drag_event", view_drag_registered)
	twinge.register_hook("greenheat_release_event", view_release_registered)
	set_process(true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and capture_input:
		var profile = {}
		view_click_registered.emit(
			{
				"user": {
					"id": "00000001",
					"display_name": "TEST_CLICK",
					"color": Color.MAGENTA,
					"profile_image": null
				},
				"position": event.position / Vector2(get_viewport().size),
				"screen_position": event.position,
				"button":"left",
				"handled":false
			}
		)
	pass

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var response = socket.get_packet().get_string_from_utf8()
			var json = JSON.parse_string(response)
			if json == null:
				return
			
			var profile = {}
			profile.id = json.id
			profile.extra = {}
			# Anonymous - No idea how this happens
			if (json.id.begins_with("A")):
				profile.display_name = "Anonymous"
				profile.color = Color.WHITE
				pass
			# Unverified - User is logged in but has not given this extension access
			elif (json.id.begins_with("U")):
				profile.display_name = "Unverified"
				profile.color = Color.ORANGE
				pass
			# User is logged in and has given the extension access, so we have their user ID
			else:
				profile = await twinge.get_user(json.id, true)
			
			var screen_pos = Vector2(float(json.x), float(json.y)) * Vector2(get_viewport().size)

			var event_object = {
				"user": {
					"id": profile.id,
					"display_name": profile.display_name,
					"color": profile.color,
					"profile_image": profile.extra["profile_image"] if profile.extra.has("profile_image") else null
				},
				"position": Vector2(json.x, json.y),
				"button": json.button,
				"shift":json.shift,
				"alt":json.alt,
				"control":json.ctrl,
				"latency":json.latency,
				"time":json.time,
				"screen_position": screen_pos
			}
			
			match json.type:
				"hover":
					_handle_hover(event_object)
				"click":
					_handle_click(event_object)
				"drag":
					_handle_drag(event_object)
				"release":
					_handle_release(event_object)
				pass
			
			
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		# Attempt to reconnect
		socket.connect_to_url("wss://heat.prod.kr/%s" % twinge.credentials.channel)


func _base_values(event:InputEventMouse, packet):
	# User Data
	event.set_meta("id", packet.user.id)
	event.set_meta("color", packet.user.color)
	event.set_meta("display_name", packet.user.display_name)
	event.set_meta("profile_picture", packet.user.profile_image)
	# Input data
	event.set_meta("time", packet.time)
	event.set_meta("latency", packet.time)
	event.ctrl_pressed = packet.ctrl
	event.alt_pressed = packet.alt
	event.shift_pressed = packet.shift
	pass

func _handle_click(packet):
	if simulate_input:
		var event:InputEventMouseButton = _create_mouse_button(packet)
		event.pressed = true
		Input.parse_input_event(event)
	else:
		view_click_registered.emit(packet)
	pass

func _handle_release(packet):
	if simulate_input:
		var event:InputEventMouseButton = _create_mouse_button(packet)
		Input.parse_input_event(event)
	else:
		view_release_registered.emit(packet)
	pass

func _create_mouse_button(packet)->InputEventMouseButton:
	var event:InputEvent = InputEventMouseButton.new()
	_base_values(event, packet)
	event.position = packet.screen_pos
	match packet.button:
		"left":
			event.button_index = MOUSE_BUTTON_LEFT
		"right":
			event.button_index = MOUSE_BUTTON_RIGHT
		"middle":
			event.button_index = MOUSE_BUTTON_MIDDLE
	cursor_position_history.set(packet.user.id, packet.screen_position)
	return event

func _handle_drag(packet):
	if simulate_input:
		var event:InputEventMouseMotion = _create_mouse_motion(packet)
		Input.parse_input_event(event)
	else:
		view_drag_registered.emit(packet)
	pass

func _handle_hover(packet):
	if simulate_input:
		var event:InputEventMouseMotion = _create_mouse_motion(packet)
		Input.parse_input_event(event)
	else:
		view_hover_registered.emit(packet)
	pass

func _create_mouse_motion(packet)->InputEventMouseMotion:
	var event:InputEvent = InputEventMouseMotion.new()
	_base_values(event, packet)
	
	var current_position = packet.screen_position
	var last_position = cursor_position_history.get(packet.user.id, current_position)
	event.relative = current_position - last_position
	cursor_position_history.set(packet.user.id, packet.screen_position)
	return event

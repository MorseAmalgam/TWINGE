extends TwingeService
class_name TwingeEventSub

enum ConnectionState {
	OFFLINE,
	CONNECTING,
	FAILED,
	CONNECTED,
	SESSION_ACTIVE,
	LISTENING
}
var _connection_status:ConnectionState = ConnectionState.OFFLINE
signal connection_change
func change_status(new_status:ConnectionState):
	if (new_status != _connection_status):
		connection_change.emit(new_status)
	_connection_status = new_status

# Connection Handlers
var socket: WebSocketPeer
var reconnect_socket: WebSocketPeer
var session_id: String
var heartbeat_watchdog: Timer

# Event handlers
var event_subscriptions:Dictionary
class EventSubListener:
	var event
	var version
	var condition
	var callables:Array


signal event_received


func _ready() -> void:
	service_identifier = "EventSub"
	pass


func _aggregate_subscriptions():
	# Compile list of necessary event subscriptions from modules
	for child in twinge.get_children():
		if (child.has_method("get_event_subscriptions")):
			var events = child.get_event_subscriptions()
			for event in events:
				if !event_subscriptions.has(event):
					event_subscriptions[event.event] = EventSubListener.new()
					event_subscriptions[event.event].event = event.event
					event_subscriptions[event.event].version = 1
					if (event.has("version")):
						debug_message("Event has version, setting")
						event_subscriptions[event.event].version = event.version
					event_subscriptions[event.event].condition = event.condition
				#event_subscriptions[event].callables.append(events[event].callable)


func connect_to_eventsub():
	_aggregate_subscriptions()
	_connect_websocket()
	pass


func _connect_websocket():
	# Don't connect if we're already connected
	if socket != null:
		return false
	
	# Do not attempt to connect if we're in the middle of reconnecting already
	if reconnect_socket:
		return false
	
	change_status(ConnectionState.CONNECTING)
	debug_message("Connecting to EventSub.")
	socket = WebSocketPeer.new()
	
	# Create websocket connection to Twitch EventSub
	socket.connect_to_url("wss://eventsub.wss.twitch.tv/ws")
	
	# Create heartbeat watchdog timer
	heartbeat_watchdog = Timer.new()
	heartbeat_watchdog.name = "KeepAlive"
	heartbeat_watchdog.timeout.connect(
		func():
			if _connection_status == ConnectionState.OFFLINE:
				# attempt reconnect process for new session
				# if this one has reached its expiration
				_connect_websocket()
	)
	add_child(heartbeat_watchdog)


func _disconnect_websocket():
	if socket:
		debug_message("Closing stream.")
		socket.close()
		socket = null
		heartbeat_watchdog.stop()
		
	if _connection_status != ConnectionState.FAILED:
		change_status(ConnectionState.OFFLINE)


func connect_to_event(event, details, callback):
	pass


#TODO: REFACTOR
func _process(delta: float) -> void:
	for socket in [self.socket, reconnect_socket]:
		if socket == null:
			continue
		
		socket.poll()

		var state = socket.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			# read current received packets until end of buffer
			while socket.get_available_packet_count():
				_handle_packet(socket.get_packet())
				
		elif state == WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			debug_message("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			heartbeat_watchdog.stop()
			set_process(false) # Stop processing.


func _set_up_subscriptions():
	debug_message("Attempting to subscribe to all existing requested events.")
	
	# request all permissions necessary
	for event in event_subscriptions:
		var version = event_subscriptions[event].version
		var condition = event_subscriptions[event].condition
		var success = await _subscribe_to_event(event, version, condition)
		if not success[0]:
			debug_message("Authentication failed for %s, disabling message type" % event, DebugType.WARNING)
			if success[1] == 401 or success[1] == 403:
				debug_message("Invalid token, consider refreshing or clearing credentials", DebugType.WARNING)
				change_status(ConnectionState.FAILED)
				_disconnect_websocket()
				return

	debug_message("TWINGE is fully connected and listening for events!")
	
	change_status(ConnectionState.LISTENING)


func _subscribe_to_event(event, version, details)->Array:
	var conditions = {
		"broadcaster_user_id": twinge.credentials.broadcaster_user_id
	}
		
	for condition in details:
		conditions[condition] = twinge.credentials.get(details[condition])
	
	var result = await twinge.api.query(
		self,
		"eventsub/subscriptions",
		{},
		{
			"type": event,
			"version": version,
			"condition": conditions,
			"transport": {
				"method": "websocket",
				"session_id": session_id
			}
		},
		HTTPClient.METHOD_POST
	)
	
	return [result.code < 300 or result.code == 409, result.code]


func _handle_packet(packet: PackedByteArray):
	# parse packet as list of json messages
	var event = packet.get_string_from_utf8()
	
	for message in event.strip_edges().split("\n", false):
		var data = JSON.parse_string(message)
		if data:
			handle_websocket_message(data)


func handle_websocket_message(command: Dictionary):
	match command.metadata.message_type:
		"session_keepalive":
			if not heartbeat_watchdog.paused:
				heartbeat_watchdog.start(heartbeat_watchdog.wait_time)
		"session_welcome":
			session_id = command.payload.session.id
			# twitch's keep alive is a bit too aggressive
			heartbeat_watchdog.start(command.payload.session.keepalive_timeout_seconds + 5.0) 
			
			if reconnect_socket:
				socket.close()
				socket = reconnect_socket
				reconnect_socket = null
			else:
				change_status(ConnectionState.CONNECTED)
				debug_message("Eventsub connected! Getting event subscriptions ready.")
				_set_up_subscriptions()
		"session_reconnect":
			reconnect_socket = WebSocketPeer.new()
			reconnect_socket.connect_to_url(command.payload.session.reconnect_url)
		"notification":
			if not heartbeat_watchdog.paused:
				heartbeat_watchdog.start(heartbeat_watchdog.wait_time)
			
			#TODO: compare payload subscription event ID to most recent messages to prevent double-event triggers
			event_received.emit(command.metadata.subscription_type, command.payload.event)

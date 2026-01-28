@icon("res://addons/twinge/core/icons/twinge.png")
extends Node
class_name TwingeCore
## TWitch INtegration for Godot Engine
## A library designed to try to make Twitch integration for games 1% more convenient.

enum ConnectionState {
	OFFLINE,
	CONNECTING,
	FAILED,
	CONNECTED
}
var _connection_status:ConnectionState = ConnectionState.OFFLINE
signal connection_change
func change_status(new_status:ConnectionState):
	if (new_status != _connection_status):
		connection_change.emit(new_status)
	_connection_status = new_status


var credentials:
	get:
		return oauth.credentials

@export var credential_filename:String
@export var broadcaster_id:String
@export var primary_instance:TwingeCore

@onready var oauth:TwingeOAuth = $OAuth
@onready var eventsub:TwingeEventSub = $EventSub
@onready var api:TwingeAPI = $API

var scopes:Array[String] = []
var endpoints = {}
var hooks = {}
var pending_hooks = {}

var user_cache:Dictionary = {}
var stream_status:Dictionary = {
	"live":false,
	"category":"Unknown",
	"start_time":"",
	"uptime":0
}

const utilities = preload("twinge_utilities.gd")

var broadcaster_user

func _ready():
	oauth.credential_filename = credential_filename
	oauth.authentication_change.connect(func(status:TwingeOAuth.AuthenticationState):
		if status == TwingeOAuth.AuthenticationState.AUTHENTICATED:
			debug_message("OAuth success! Moving to EventSub stage.")
			eventsub.connect_to_eventsub()
			# Connected, get stream status
			var status_poller = Timer.new()
			#status_poller.timeout.connect(update_stream_status)
			status_poller.name = "StatusPollTimer"
			add_child(status_poller)
			status_poller.start(60.0)
	)
	eventsub.connection_change.connect(func(status:TwingeEventSub.ConnectionState):
		if status == TwingeEventSub.ConnectionState.LISTENING:
			change_status(ConnectionState.CONNECTED)
	)
	debug_message("Populating expected scopes.")
	populate_scopes()
	debug_message("Beginning OAuth initialization.")
	
	oauth.initialize(true)
	pass

func connect_to_twitch():
	change_status(ConnectionState.CONNECTING)
	await oauth.login()
	pass

func register_endpoint(endpoint:String, target, callback):
	if !endpoints.has(endpoint):
		debug_message("Registered '%s' as a request endpoint." % endpoint)
		endpoints[endpoint] = Callable(target, callback)

func endpoint(call_name:String, arguments:Array=[]):
	if endpoints.has(call_name):
		debug_message("Calling '%s' endpoint." % call_name)
		return await endpoints[call_name].callv(arguments)
	else:
		debug_message("Endpoint '%s' has not been registered." % call_name)

func register_hook(event_name:String, call_signal):
	if (!hooks.has(event_name)):
		hooks[event_name] = call_signal
		
		# Check if there are things waiting to connect to this hook and connect them if there are
		if (pending_hooks.has(event_name)):
			debug_message("Hook %s has %s connections waiting, attempting to connect those now." % [event_name, pending_hooks[event_name].size()])
			for hook in pending_hooks[event_name]:
				connect_to_hook(event_name, hook)
			pending_hooks.erase(event_name)
	pass

func connect_to_hook(event_name, callback):
	if (!hooks.has(event_name)):
		if !pending_hooks.has(event_name):
			pending_hooks[event_name] = []
		pending_hooks[event_name].append(callback)
		debug_message("Attempted to connect to hook '%s' which is not currently registered. Put in queue to connect if/when it is registered." % event_name, TwingeCore.DebugType.WARNING)
	
	else:
		hooks[event_name].connect(callback)

func disconnect_from_hook(event_name, callback)->bool:
	if (!hooks.has(event_name)):
		return false
		
	hooks[event_name].disconnect(callback)
	return true

func populate_scopes():
	scopes = []
	for node in get_children():
		if (node is TwingeModule):
			scopes.append_array(node.get_scopes())
			pass
	return scopes

func update_stream_status():
	var result = await api.query(
		self,
		"streams",
		{},
		{
			"user_id":credentials.user_id
		}
	)
	
	if result == null or result.data == "" or result.code != 200:
		return
	
	if result.data.size() == 1:
		stream_status.live = true
		stream_status.category = result.data.game_name
		stream_status.start_time = Time.get_unix_time_from_datetime_dict(
			Time.get_datetime_dict_from_datetime_string(result.data.started_at.substring(0, -1), false)
		)
	else:
		stream_status.live = false
	pass

func get_user(user_id:String, enrich:bool=false)->TwingeUser:
	# Secondary instances should not perform their own queries and instead rely on the primary.
	if (primary_instance != null):
		return await primary_instance.get_user(user_id, enrich)
	
	var user = TwingeUser.new()
	if user_cache.has(user_id):
		user = user_cache[user_id]
	else:
		user = TwingeUser.load_from_file(user_id)
	
	if (!user.cache_expirations.has("twitch") or 
		user.cache_expirations["twitch"] < Time.get_unix_time_from_system()):
		debug_message("Twitch info cache expired for %s, updating..." % user_id)
		# User info
		var user_response = await api.query(
			self,
			"users",
			{
				"id": user_id
			}
		)
		if user_response == null:
			return null
		
		var found_data = user_response.data.data.front()
		
		if found_data == null or found_data.id != user_id:
			return null
		
		user.id = user_id
		user.login = found_data.login
		user.display_name = found_data.display_name
		user.is_broadcaster = (user_id == credentials.broadcaster_user_id)
		
		# Chat color
		var color_response = await api.query(
			self,
			"chat/color", 
			{ 
				"user_id": user_id 
			}
		)
		user.color = Color.from_string(color_response.data.data.front().color, Color.DARK_GRAY)
		
		# Get user profile picture
		await utilities.fetch_image(self, found_data.profile_image_url, "user://profile_images/%s.%s" % [user.id, found_data.profile_image_url.get_extension()])
		
		# Set cache for one hour
		user.cache_expirations["twitch"] = floor(Time.get_unix_time_from_system()) + 3600
		user.save_to_file()
		pass
	
	if (enrich):
		for child in get_children():
			if child != null and child.has_method("enrich_user"):
				user = await child.enrich_user(user)
		user.save_to_file()
		pass
	
	user_cache[user_id] = user
	return user

func update_user_cache(user:TwingeUser):
	user_cache[user.id] = user

enum DebugType {MESSAGE, WARNING, ERROR}
@export_enum("None", "Errors", "Warnings & Errors", "Everything") var debug_level = 2
var service_identifier:String = "Core"

func debug_message(message:String, type:DebugType=DebugType.MESSAGE):
	var time_dict = Time.get_time_dict_from_system()
	if (type == DebugType.MESSAGE and debug_level == 3):
		print("[%s:%s:%s][TWINGE-%s] %s" % [time_dict["hour"], time_dict["minute"], time_dict["second"], service_identifier, message])
	elif (type == DebugType.WARNING and debug_level >= 2):
		push_warning("[%s:%s:%s][TWINGE-%s] %s" % [time_dict["hour"], time_dict["minute"], time_dict["second"], service_identifier, message])
	elif (type == DebugType.ERROR and debug_level >= 1):
		push_error("[%s:%s:%s][TWINGE-%s] %s" % [time_dict["hour"], time_dict["minute"], time_dict["second"], service_identifier, message])

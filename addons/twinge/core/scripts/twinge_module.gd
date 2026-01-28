@icon("res://addons/twinge/core/icons/twinge-module.png")
extends TwingeService
class_name TwingeModule

var signals:Dictionary = {}

func _ready():
	service_identifier = "Module"
	twinge.connection_change.connect(func(state):
		if state == twinge.ConnectionState.CONNECTED:
			_on_twinge_connected()
		pass
		)


func get_scopes() -> Array[String]:
	return []


func get_event_subscriptions() -> Array:
	return []

func create_hook(hook_name:String, callback:Signal):
	twinge.register_hook(hook_name, callback)
	signals[hook_name] = callback
	pass

func _handle_event(event:String, details:Dictionary):
	var formatted_event_name = event.replace(".", "_")
	var method_name = "_handle_%s" % formatted_event_name
	if has_method(method_name):
		call(method_name, details)
	elif (signals.has(formatted_event_name)):
		signals[formatted_event_name].emit(details)
	pass

func _on_twinge_connected():
	pass

func _create_heartbeat(callback:Callable, period:float = 60):
	for node in get_children():
		if (node.name == service_identifier+"HeartbeatTimer"):
			return
	var heartbeat_timer = Timer.new()
	heartbeat_timer.timeout.connect(callback)
	heartbeat_timer.name = service_identifier+"HeartbeatTimer"
	add_child(heartbeat_timer)
	heartbeat_timer.start(period)

extends Node
class_name TwingeService

enum DebugType {MESSAGE, WARNING, ERROR}

@onready var twinge:TwingeCore = get_parent()
const utilities = preload("twinge_utilities.gd")
var service_identifier:String = "Service"

func debug_message(message:String, type:DebugType=DebugType.MESSAGE):
	match(type):
		DebugType.MESSAGE:
			print("[TWINGE-%s] %s" % [service_identifier, message])
		DebugType.WARNING:
			push_warning("[TWINGE-%s] %s" % [service_identifier, message])
		DebugType.ERROR:
			push_error("[TWINGE-%s] %s" % [service_identifier, message])

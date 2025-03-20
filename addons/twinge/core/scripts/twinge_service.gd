extends Node
class_name TwingeService

enum DebugType {MESSAGE, WARNING, ERROR}
@export_enum("None", "Errors", "Warnings & Errors", "Everything") var debug_level = 2

@onready var twinge:TwingeCore = get_parent()
const utilities = preload("twinge_utilities.gd")
var service_identifier:String = "Service"

func debug_message(message:String, type:DebugType=DebugType.MESSAGE):
	if (type == DebugType.MESSAGE and debug_level == 3):
		print("[TWINGE-%s] %s" % [service_identifier, message])
	elif (type == DebugType.WARNING and debug_level >= 2):
		push_warning("[TWINGE-%s] %s" % [service_identifier, message])
	elif (type == DebugType.ERROR and debug_level >= 1):
		push_error("[TWINGE-%s] %s" % [service_identifier, message])

@icon("res://addons/twinge/core/icons/twinge-submodule.png")
extends TwingeService
class_name TwingeSubmodule

func _ready():
	twinge = get_parent().twinge
	service_identifier = "Submodule"
	twinge.connection_change.connect(func(state):
		if state == twinge.ConnectionState.CONNECTED:
			_on_twinge_connected()
		pass
	)

func _on_twinge_connected():
	pass

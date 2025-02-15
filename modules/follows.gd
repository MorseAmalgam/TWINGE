extends TwingeModule
## Implements features related to follows.


func get_scopes() -> Array[String]:
	return [
		# Used to get list of followers - can also trigger for a new follower.
		"moderator:read:followers", 
	]

func _ready():
	service_identifier = "Module-Follows"

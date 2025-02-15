@icon("res://addons/twinge/core/icons/twinge-trigger.png")
extends Node
class_name TwingeTriggerTemplate

const utilities = preload("twinge_utilities.gd")

@export var active:bool = true
@export_flags("Follower", "Subscriber (Prime)", "Subscriber (Tier 1)", "Subscriber (Tier 2)", "Subscriber (Tier 3)", "VIP", "Mod", "Streamer") var access_required = 128
## If no values are selected, this will default to allowing all users to trigger it.


func run(_user, _parameters):
	pass


func has_permission(user:TwingeUser):
	return ((access_required == 0)
			|| (access_required & 1 and user.extra["is_follower"])
			|| (access_required & 2 and 0 <= user.extra["subscription_tier"]) # Currently don't have support for detecting prime subs
			|| (access_required & 4 and 1 <= user.extra["subscription_tier"]) 
			|| (access_required & 8 and 2 <= user.extra["subscription_tier"]) 
			|| (access_required & 16 and 3 <= user.extra["subscription_tier"]) 
			|| (access_required & 32 and user.extra["is_vip"])
			|| (access_required & 64 and user.extra["is_mod"])
			|| (access_required & 128 and user.is_broadcaster)
			)

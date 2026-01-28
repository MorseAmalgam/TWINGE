extends TwingeSubmodule
class_name TwingeEmoteService

var emote_cache:Dictionary = {}

func _on_twinge_connected():
	preload_emotes(twinge.broadcaster_id)
	pass
	
func preload_emotes(channel_id:String):
	pass

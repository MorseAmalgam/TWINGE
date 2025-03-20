extends TwingeModule
class_name TwingeModerationModule

var mods: Array

func get_scopes() -> Array[String]:
	return [
		"moderation:read"
	]

func _ready():
	super()
	service_identifier = "Moderation"
	twinge.register_endpoint("get_mods", self, "get_mods")
	pass

func _on_twinge_connected():
	update_metrics_info()
	# Updating every five minutes to ensure nothing has changed - Probably overkill but w/e
	_create_heartbeat(update_metrics_info, 60 * 5)
	pass

func update_metrics_info():
	# Reset the list
	mods = []
	await _update_mods()
	
func _update_mods(after:String = ""):
	var result = await twinge.api.query(
		self,
		"moderation/moderators", 
		{ 
			"broadcaster_id": twinge.credentials.broadcaster_user_id, 
			"first": 100, 
			"after" : after 
		})
	if result != null:
		if len(result.data.data) > 0:
			for mod in result.data.data:
				if (!mods.has(mod.user_id)):
					mods.append(mod.user_id)
			
			# More than 100 mods??
			if result.data.pagination.has("cursor"):
				await _update_mods(result.data.pagination.cursor)

func enrich_user(user: TwingeUser) -> TwingeUser:
	user.extra["is_mod"] = mods.has(user.id)
	return user

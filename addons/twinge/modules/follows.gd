extends TwingeModule
class_name TwingeFollowsModule
## Implements features related to follows.

var followers: Array
var latest_follower: TwingeUser

signal new_follower(details)

func get_scopes() -> Array[String]:
	return [
		# Used to get list of followers - can also trigger for a new follower.
		"moderator:read:followers", 
	]

func _ready():
	super()
	service_identifier = "Module-Follows"
	# Register hooks
	twinge.register_hook("channel_follow", new_follower)
	signals["channel_follow"] = new_follower
	
	twinge.register_endpoint("get_followers", self, "get_followers")
	twinge.register_endpoint("get_latest_follower", self, "get_latest_follower")

func _on_twinge_connected():
	update_metrics_info()
	# Updating every five minutes to ensure nothing has changed - Probably overkill but w/e
	_create_heartbeat(update_metrics_info, 60 * 5)
	pass

func update_metrics_info():
	# Reset the list
	followers = []
	await update_followers()


func handle_new_follower(details):
	latest_follower = await twinge.get_user(details.user_id)
	pass

func get_followers()->Array:
	return followers

func get_latest_follower():
	return latest_follower

func update_followers(after:String = ""):
	var result = await twinge.api.query(
		self,
		"channels/followers",
		{
			"broadcaster_id": twinge.credentials.broadcaster_user_id, 
			"first": 100, 
			"after" : after 
		}
	)
	if result != null:
		if len(result.data) > 0:
			if result.data.total == 0:
				return
			# Set latest follower
			if (latest_follower == null):
				var user =  result.data.data.front()
				latest_follower = await twinge.get_user(user.user_id)
			
			for follower in result.data.data:
				if (!followers.has(follower.user_id)):
					followers.append(follower.user_id)
			
			# More than 100 Followers
			if result.data.pagination.has("cursor"):
				await update_followers(result.data.pagination.cursor)


func enrich_user(user: TwingeUser) -> TwingeUser:
	user.extra["is_follower"] = followers.has(user.id)
	return user

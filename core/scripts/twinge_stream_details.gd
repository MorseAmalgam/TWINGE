extends TwingeModule
class_name StreamDetailsModule


var following: Array
var following_live_ids: Array
var following_live: Dictionary

var followers: Array
var latest_follower: TwingeUser

var subscribers: Dictionary
var latest_subscriber: TwingeUser

class StreamerInfo:
	var username:String
	var game_name:String
	var start_time:String
	var thumbnail_url:String

var vips: Array

var mods: Array

signal updated

func get_scopes() -> Array[String]:
	return [
		"moderator:read:followers",
		"user:read:follows",
		"channel:read:vips",
		"channel:read:subscriptions",
		"moderation:read"
	]


# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	service_identifier = "StreamDetails"
	twinge.register_endpoint("get_followers", self, "get_follower")
	twinge.register_endpoint("get_latest_follower", self, "get_latest_follower")
	twinge.register_endpoint("get_vips", self, "get_vips")
	twinge.register_endpoint("get_mods", self, "get_mods")
	twinge.register_endpoint("get_subscribers", self, "get_subscribers")
	twinge.register_endpoint("get_latest_subscriber", self, "get_latest_subscriber")
	twinge.register_endpoint("get_following_live", self, "get_following_live")
	pass

func _on_twinge_connected():
	update_metrics_info()
	# Updating every five minutes to ensure nothing has changed - Probably overkill but w/e
	_create_heartbeat(update_metrics_info, 60 * 5)
	pass

	
func update_metrics_info():
	# Reset the list
	followers = []
	latest_follower = null
	await update_followers()

	vips = []
	await update_vips()
	
	subscribers = {}
	latest_subscriber = null
	await update_subscribers()
	
	mods = []
	await update_mods()
	
	following = []
	await update_following()
	
	following_live_ids = []
	following_live = {}
	await update_following_live()


func get_followers()->Array:
	return followers

func get_latest_follower():
	return latest_follower

func update_followers(after:String = ""):
	var result = await twinge.api.query(
		self,
		"channels/followers",
		{
			"broadcaster_id": twinge.credentials.user_id, 
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


func get_vips()->Array:
	return vips

func update_vips(after:String = ""):
	var result = await twinge.api.query(
		self,
		"channels/vips", 
		{
			"broadcaster_id": twinge.credentials.user_id,
			"first": 100, 
			"after" : after 
		})
	if result != null:
		if len(result.data.data) > 0:
			for vip in result.data.data:
				if (!vips.has(vip.user_id)):
					vips.append(vip.user_id)
			
			if result.data.pagination.has("cursor"):
				await update_vips(result.data.pagination.cursor)
	pass

func get_subscribers()->Dictionary:
	return subscribers

func get_latest_subscriber():
	return latest_subscriber

func update_subscribers(after:String = ""):
	var result = await twinge.api.query(
		self,
		"subscriptions", 
		{ 
			"broadcaster_id": twinge.credentials.user_id, 
			"first": 100, 
			"after" : after 
		})
	if result != null:
		if len(result.data.data) > 0:
			# Set latest subscriber
			if (latest_subscriber == null):
				var user =  result.data.data.front()
				var profile = await twinge.get_user(user.user_id)
				
				latest_subscriber = profile
			
			for subscriber in result.data.data:
				if (!subscribers.has(subscriber.user_id)):
					var subinfo = SubscriptionInfo.new()
					subinfo.gifter_id = subscriber.gifter_id
					subinfo.is_gift = subscriber.is_gift
					subinfo.tier = int(subscriber.tier) / 1000
					subscribers[subscriber.user_id] = subinfo
			
			# More than 100 subscribers
			if result.data.pagination.has("cursor"):
				await update_subscribers(result.data.pagination.cursor)


func update_mods(after:String = ""):
	var result = await twinge.api.query(
		self,
		"moderation/moderators", 
		{ 
			"broadcaster_id": twinge.credentials.user_id, 
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
				await update_mods(result.data.pagination.cursor)


func update_following(after:String=""):
	var result = await twinge.api.query(
		self,
		"channels/followed", 
		{
			"user_id": twinge.credentials.user_id,
			"first": 100, 
			"after" : after 
		})
	if result != null:
		if len(result.data.data) > 0:
			for user in result.data.data:
				if (!following.has(user.broadcaster_id)):
					following.append(user.broadcaster_id)
			
			# Following more than 100 users
			if result.data.pagination.has("cursor"):
				await update_following(result.data.pagination.cursor)
	pass

func get_following_live():
	return following_live_ids

func update_following_live(index:int = 0):
	var count_per_request = 75
	# Twitch does a weird thing and allows you to include the same parameter over and over. 
	# This messes with all logical implementations of how to handle inputting a list of user ids.
	# It also completely conflicts with how tmi.gd handles requests, making all of this VERY problematic.
	var user_ids = "&user_id=".join(following.slice(index, index + count_per_request))
	var result = await twinge.api.query(
		self,
		"streams?first=%s&type=live&user_id=%s" % [count_per_request, user_ids]
		)
	if result != null:
		if len(result.data.data) > 0:
			for user in result.data.data:
				if (!following_live.has(user.user_id)):
					following_live_ids.append(user.user_id)
					
					var stream_info = StreamerInfo.new()
					stream_info.username = user.user_name
					stream_info.game_name = user.game_name
					stream_info.start_time = user.started_at
					stream_info.thumbnail_url = user.thumbnail_url
					following_live[user.user_id] = stream_info
			
		# Not reliant on the number of responses - If we get a response, continue to the next chunk of our list
		if index + count_per_request < following.size():
			await update_following_live(index + count_per_request)
	pass


func enrich_user(user: TwingeUser) -> TwingeUser:
	user.extra["is_follower"] = followers.has(user.id)
	user.extra["is_mod"] = mods.has(user.id)
	user.extra["is_vip"] = vips.has(user.id)
	user.extra["subscription_tier"] = -1
	if subscribers.has(user.id):
		user.extra["subscription_tier"] = subscribers[user.id].tier
	
	return user

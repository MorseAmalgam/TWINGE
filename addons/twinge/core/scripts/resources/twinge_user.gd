extends Resource
class_name TwingeUser

const utilities = preload("../twinge_utilities.gd")

var id: String
var login: String
var display_name: String
var color: Color = Color.WEB_PURPLE
var is_broadcaster:bool = false
var cache_expirations: Dictionary
var first_chat_timestamp:int = -1
var session_chat_timestamp:int = -1
var extra: Dictionary = {}

static func load_from_file(user_id:String) -> TwingeUser:
	var path = "user://profiles/%s.profile" % user_id
	if !FileAccess.file_exists(path):
		return TwingeUser.new()
	
	var user = TwingeUser.new()
	var file_data = FileAccess.get_file_as_string(path)
	var file_json = JSON.parse_string(file_data)
	user.id = file_json.get("id")
	user.login = file_json.get("login")
	user.display_name = file_json.get("display_name")
	user.color = Color.from_string(file_json.get("color"), Color.WEB_PURPLE)
	user.cache_expirations = file_json.get("cache_expirations", {})
	user.is_broadcaster = file_json.get("is_broadcaster", false)
	user.first_chat_timestamp = file_json.get("is_broadcaster", -1)
	user.session_chat_timestamp = file_json.get("is_broadcaster", -1)
	user.extra = file_json.get("extra", {})
	return user

func profile_picture()->Texture2D:
	return utilities.load_image("user://profile_images/%s.png" % id)

static func from_json(json: String) -> TwingeUser:
	var user = TwingeUser.new()
	var data = JSON.parse_string(json)
	
	user.id = data.get("id")
	user.login = data.get("login")
	user.display_name = data.get("display_name")
	user.color = Color.from_string(data.get("color"), Color.WEB_PURPLE)
	user.cache_expirations = data.get("cache_expirations")
	user.first_chat_timestamp = data.get("first_chat", -1)
	user.session_chat_timestamp = data.get("session_chat", -1)
	user.extra = data.get("extra", {})
	return user

func to_json() -> String:
	return JSON.stringify({
		"id": id,
		"login": login,
		"display_name": display_name,
		"color": color.to_html(),
		"cache_expirations": cache_expirations,
		"is_broadcaster": is_broadcaster,
		"first_chat": first_chat_timestamp,
		"session_chat": session_chat_timestamp,
		"extra": extra
	}, "  ")

func save_to_file():
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("user://profiles")
	)
	var json = to_json()
	var out = FileAccess.open("user://profiles/%s.profile" % id, FileAccess.WRITE_READ)
	out.store_string(json)
	out.close()
	pass

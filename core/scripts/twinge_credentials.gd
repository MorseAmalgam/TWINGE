extends Resource
class_name TwingeCredentials

@export var user_login: String
@export var user_id: String
@export var channel: String
@export var broadcaster_user_id: String
@export var token: String
@export var refresh_token: String

func to_json() -> String:
	return JSON.stringify({
		"user_login": user_login,
		"user_id": user_id,
		"broadcaster_user_id": broadcaster_user_id,
		"channel": channel,
		"access_token": token,
		"refresh_token": refresh_token,
	}, "  ")


static func load_from_env() -> TwingeCredentials:
	var credentials = TwingeCredentials.new()

	credentials.user_login = OS.get_environment("TWITCH_LOGIN")
	credentials.channel = OS.get_environment("TWITCH_CHANNEL")
	credentials.token = OS.get_environment("TWITCH_TOKEN")
	credentials.refresh_token = OS.get_environment("TWITCH_REFRESH_TOKEN")
	
	return credentials

static func load_from_file(filename:String, key:String) -> TwingeCredentials:
	if not FileAccess.file_exists("user://%s.cfg" % filename):
		return null
	
	var config = ConfigFile.new()
	config.load_encrypted_pass("user://%s.cfg" % filename, key)
	
	var credentials = TwingeCredentials.new()
	credentials.user_login = config.get_value("user", "user_login")
	credentials.user_id = config.get_value("user", "user_id")
	credentials.channel = config.get_value("user", "channel")
	credentials.broadcaster_user_id = config.get_value("target", "broadcaster_id")
	credentials.token = config.get_value("session", "access_token")
	credentials.refresh_token = config.get_value("session", "refresh_token")
	return credentials

func save_to_file(filename:String, key:String):
	var config = ConfigFile.new()
	config.set_value("user", "user_login", user_login)
	config.set_value("user", "user_id", user_id)
	config.set_value("user", "channel", channel)
	config.set_value("target", "broadcaster_id", broadcaster_user_id)
	config.set_value("session", "access_token", token)
	config.set_value("session", "refresh_token", refresh_token)
	
	config.save_encrypted_pass("user://%s.cfg" % filename, key)

static func load_from_json(filename: String) -> TwingeCredentials:
	if not FileAccess.file_exists("user://%s.json" % filename):
		return null
	
	var contents = FileAccess.get_file_as_string("user://%s.json" % filename)
	var body = JSON.parse_string(contents)
	
	var credentials = TwingeCredentials.new()
	credentials.user_login = body.get("user_login", "")
	credentials.user_id = body.get("user_id", "")
	credentials.channel = body.get("channel", "")
	credentials.broadcaster_user_id = body.get("broadcaster_user_id", "")
	credentials.token = body.get("access_token", "")
	credentials.refresh_token = body.get("refresh_token", "")
	return credentials

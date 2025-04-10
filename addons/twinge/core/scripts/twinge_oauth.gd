extends TwingeService
class_name TwingeOAuth

var required_scopes:Array[String]

# OAuth Login Management
var peer : StreamPeerTCP
var server : TCPServer


enum AuthenticationState {
	OFFLINE,
	AUTHENTICATING,
	AWAITING_REAUTHENTICATION,
	FAILED,
	AUTHENTICATED
}
var _authentication_status:AuthenticationState = AuthenticationState.OFFLINE
signal authentication_change

func set_status(new_status:AuthenticationState):
	if new_status != _authentication_status:
		self.authentication_change.emit(new_status)
	_authentication_status = new_status

@export var timeout : int = 60.0
@export var tcp_port : int = 3000
var timer: SceneTreeTimer
var redirect_url: String: 
	get:
		return "http://localhost:%d" % tcp_port

var HTTP_HEADER = """HTTP/1.1 %s
Server: TWINGE (Godot Engine 4)
Content-Length: %d
Connection: close
Content-Type: text/html; charset=UTF-8

%s"""

var RETRY_PAGE = """<html>
  <head>
	<title>%s [twitch login]</title>
	<script>
		javascript:window.location = window.location.toString().replace('#','?')
	</script>
  </head>
</html>
""" % [ProjectSettings.get_setting_with_override("application/config/name")]
var REDIRECT_PAGE = """<html>
  <head>
	<title>%s [twitch login]</title>
  </head>
  <body onload="javascript:close();">
	Authorization complete, you may now close this page.
  </body>
</html>
""" % [ProjectSettings.get_setting_with_override("application/config/name")]
signal completed

var credentials:TwingeCredentials = TwingeCredentials.new()
var credential_filename:String

func _ready():
	service_identifier = "OAuth"
	# Stop processing since we have no server response to listen for
	set_process(false)

# TODO RECONFIGURE LOGIN 
func initialize(prompt_login:bool = false):
	required_scopes = twinge.scopes
	
	if (ProjectSettings.get_setting("TWINGE/oauth/client_ID") == null or
		ProjectSettings.get_setting("TWINGE/oauth/client_secret") == null):
			debug_message("The client ID and/or client secret are currently not set.\nYou must follow the instructions at https://dev.twitch.tv/docs/authentication/register-app/ and fill in these fields before you can make an authorization request.")
			return false
		
	credentials = TwingeCredentials.load_from_file(credential_filename, ProjectSettings.get_setting("TWINGE/encryption/key"))
	#credentials = TwingeCredentials.load_from_json(credential_filename) #, ProjectSettings.get_setting("TWINGE/encryption/key"))
	if (credentials != null):
		if credentials.token:
			# Validate Token for freshness & proper scopes
			var result = await utilities.request(
				self,
				"https://id.twitch.tv/oauth2/validate",
				{
					"Authorization": "OAuth %s" % credentials.token
				}
			)
			if result != null:
				# Invalid OAuth Token, Attempt Refresh
				if (result.code == 401):
					debug_message("Token invalid, attempting refresh.", DebugType.WARNING)
					var refresh = await refresh_token()
					# Refresh successful
					if (refresh):
						set_status(AuthenticationState.AUTHENTICATED)
						debug_message("Token successfully refreshed!")
						credentials.save_to_file(credential_filename, ProjectSettings.get_setting("TWINGE/encryption/key"))
					# Refresh Failed
					else:
						set_status(AuthenticationState.AWAITING_REAUTHENTICATION)
						debug_message("Could not refresh token - Will require full re-authorization.", DebugType.ERROR)
						if (prompt_login):
							login()
					pass
				else:
					for scope in required_scopes:
						if (!result.data.scopes.has(scope)):
							set_status(AuthenticationState.AWAITING_REAUTHENTICATION)
							debug_message("Missing required scope", DebugType.ERROR)
							if (prompt_login):
								login()
							return
					debug_message("Scope check seems clear.")
					set_status(AuthenticationState.AUTHENTICATED)
					# Since we know we have a valid token with desired scopes, we can make sure it stays fresh
					var token_refresher = Timer.new()
					token_refresher.timeout.connect(refresh_token)
					add_child(token_refresher)
					token_refresher.start(30.0 * 60.0) # refresh every 30 minutes
				pass
			else:
				set_status(AuthenticationState.FAILED)
				debug_message("Failed to connect to server", DebugType.ERROR)
		# Access Token doesn't exist
		else:
			if (prompt_login):
				login()
	# File does not exist - Not technically a failure, but means they need to authenticate
	else:
		debug_message("Unable to load credential file %s - check that the file exists and is valid." % credential_filename, DebugType.WARNING)
	pass

# VVV UNTESTED VVV
func login():
	_start_tcp_server()
	query_oauth()
	await completed



func _start_tcp_server():
	if server != null:
		return
		
	debug_message("Beginning login flow")
	server = TCPServer.new()
	if server.listen(tcp_port) != OK:
		debug_message("Could not listen to port %d" % tcp_port, DebugType.ERROR)
		server = null
		return
	else:
		debug_message("Server is listening on %s" % redirect_url)
		
	set_process(true)
		
	timer = get_tree().create_timer(timeout)
	timer.timeout.connect(
		_stop_server,
		CONNECT_ONE_SHOT
	)


func query_oauth():
	set_status(AuthenticationState.AUTHENTICATING)
	var query = utilities.query_string({
		"response_type": " ".join(["token", "id_token"]) if not ProjectSettings.get_setting("TWINGE/oauth/client_secret") else "code",
		"client_id": ProjectSettings.get_setting("TWINGE/oauth/client_ID"),
		"scope": " ".join(required_scopes),
		"redirect_uri": redirect_url,
		"force_verify": "false",
		"state": randi(),
		"nonce": randi(),
		"claims": JSON.stringify({
			"userinfo": {
				"picture": null,
				"preferred_username": null,
			}
		}),
	})
	var auth_url = "https://id.twitch.tv/oauth2/authorize?%s" % query
	
	OS.shell_open(auth_url)

func _stop_server():
	if server == null:
		return
	if peer == null:
		return
	
	peer.disconnect_from_host()
	peer = null

	server.stop()
	server = null
	
	set_process(false)
	
	completed.emit()

func refresh_token()->bool:
	if credentials == null:
		return false
	if credentials.refresh_token == "":
		return false
	
	var result = await utilities.request(
		self,
		"https://id.twitch.tv/oauth2/token",
		{
			"Content-Type": "application/x-www-form-urlencoded"
		},
		{},
		{
			"grant_type": "refresh_token",
			"client_id": ProjectSettings.get_setting("TWINGE/oauth/client_ID"),
			"client_secret": ProjectSettings.get_setting("TWINGE/oauth/client_secret"),
			"refresh_token": credentials.refresh_token
		},
		HTTPClient.METHOD_POST
	)
	
	if result.code != 200:
		return false
	
	credentials.token = result.data.access_token
	credentials.refresh_token = result.data.refresh_token
	
	return true


func _process(_delta):
	if peer == null:
		peer = server.take_connection()
		return
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	
	peer.poll()
	if peer.get_available_bytes() == 0:
		return
		
	var response = peer.get_utf8_string(peer.get_available_bytes())
	if response == "":
		return
		
	_process_response(response)

func _process_response(response : String):
	if response.contains("favicon"):
		_send_response("404 NOT FOUND", "Not Found")
		return
	
	# parse out the query string parameters
	var start : int = response.strip_escapes().find("?")

	if start < 0:
		print("[tmi/oauth]: Invalid Response received, expecting required data in query parameters.")
		# in case the 
		_send_response("200 OK", RETRY_PAGE)
		return
		
	response = response.substr(start + 1, response.find(" ", start) - start)
	var data = utilities.qs_split(response)
	if (data.has("error")):
		_send_response("400 BAD REQUEST", data["error"])
	elif "code" in data:
		_send_response("200 OK", REDIRECT_PAGE)
		await _code_to_token(data["code"])
	elif "id_token" in data:
		# This is for OIDC authorization which I'm not currently using
		# Feels like it should be disabled just so I don't break anything
		await _idtoken_credentials(data["id_token"], data["access_token"])
		_send_response("200 OK", REDIRECT_PAGE)

	_stop_server()

func _send_response(status_code: String, body: String):
	var buf = body.to_utf8_buffer()
	var data = HTTP_HEADER % [status_code, buf.size(), body]
	
	peer.put_data(data.to_utf8_buffer())
	
	peer.disconnect_from_host()
	peer = null

func _code_to_token(code: String):
	var result = await utilities.request(
		self,
		"https://id.twitch.tv/oauth2/token",
		{
			"Content-Type": "application/x-www-form-urlencoded",
		},
		{},
		{
			"grant_type": "authorization_code",
			"client_id": ProjectSettings.get_setting("TWINGE/oauth/client_ID"),
			"client_secret": ProjectSettings.get_setting("TWINGE/oauth/client_secret"),
			"code": code,
			"redirect_uri": redirect_url
		},
		HTTPClient.METHOD_POST
	)

	if result.code != 200:
		return
	var body = result.data
	
	if credentials == null:
		credentials = TwingeCredentials.new()
	credentials.token = body.access_token
	credentials.refresh_token = body.refresh_token
	
	var payload = await utilities.request(
		self,
		"https://id.twitch.tv/oauth2/userinfo",
		{
			"Authorization": "Bearer %s" % body.access_token,
		}
	)
	
	# The credentials do a lot of things I can't really explain at the moment.
	# 	channel, user_name and user_login all store the same information but I believe 
	# they might differ if getting permission for another channel? But it's hard to tell.
	
	credentials.user_id = payload.data.sub
	credentials.user_login = payload.data.get("preferred_username", "")
	credentials.channel = payload.data.get("preferred_username", "").to_lower()
	
	if !twinge.broadcaster_id.is_empty():
		credentials.broadcaster_user_id = twinge.broadcaster_id
	else:
		credentials.broadcaster_user_id = await _lookup_channel(body.access_token, credentials.channel)
	credentials.save_to_file(credential_filename, ProjectSettings.get_setting("TWINGE/encryption/key"))
	debug_message("Login successful, credentials have been updated.")
	set_status(AuthenticationState.AUTHENTICATED)

func _lookup_channel(access_token, channel):
	var broadcaster = await twinge.api.query(
		self,
		"users",
		{
			"login": channel,
		}
	)

	return broadcaster.data.data[0].id


func oauth_request():
	pass


# This is for OIDC - I don't have anything to test this with so it could be VERY BROKEN
func _idtoken_credentials(id_token, access_token):
	var body = id_token.split(".")[1] + "==" # add padding to base64 so godot can parse it
	var jwt = Marshalls.base64_to_utf8(body)
	var payload = JSON.parse_string(jwt)
	assert(payload != null, "unable to parse id token")
	
	var newCredentials = TwingeCredentials.new()
	newCredentials.user_id = payload.sub
	newCredentials.user_login = payload.get("preferred_username" ,"").to_lower()
	newCredentials.profile = {
		"display_name": payload.get("preferred_username" ,""),
		"image": payload.get("picture", ""),
	}
	if twinge.credentials.channel:
		newCredentials.channel = twinge.credentials.channel
		newCredentials.broadcaster_user_id = await _lookup_channel(access_token, newCredentials.channel)
	else:
		newCredentials.channel = payload.preferred_username
		newCredentials.broadcaster_user_id = payload.sub
	newCredentials.token = access_token
	
	await twinge.set_credentials(newCredentials)
	

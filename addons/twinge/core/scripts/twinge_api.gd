extends TwingeService
class_name TwingeAPI

func _ready():
	service_identifier = "API"

func query(requester:Node, endpoint:String, uri={}, body={}, method=HTTPClient.METHOD_GET):
	var header = {
		"Authorization": "Bearer %s" % twinge.credentials.token,
		"Client-Id": ProjectSettings.get_setting("TWINGE/oauth/client_ID")
	}
	if (method == HTTPClient.METHOD_POST && body != {}):
		header["Content-Type"] = "application/json"

	return await utilities.request(
		requester,
		"https://api.twitch.tv/helix/%s" % endpoint,
		header,
		uri,
		body,
		method
	)

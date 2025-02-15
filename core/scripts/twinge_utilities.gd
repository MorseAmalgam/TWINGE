extends TwingeService

static var magick_loader

func _ready():
	service_identifier = "HTTPUtils"


static func http_headers(headers: Dictionary):
	var out = []
	for header in headers.keys():
		var value = headers[header]
		out.append(
			"%s: %s" % [header, value]
		)
	return out


static func qs_split(query: String) -> Dictionary:
	var data : Dictionary = {}
	for entry in query.split("&"):
		var pair = entry.split("=")
		data[pair[0]] = "" if pair.size() < 2 else pair[1]
	return data


static func query_string(params: Dictionary = {}) -> String:
	var string = []
	for key in params.keys():
		# Support for Twitch's ridiculous user id arrays
		if (params[key] is Array):
			for param in params[key]:
				var value = "%s" % param
				string.append("%s=%s" % [key.uri_encode(), value.uri_encode()])
			pass
		else:
			var value = "%s" % params[key]
			string.append("%s=%s" % [key.uri_encode(), value.uri_encode()])
	return "&".join(string)


static func fetch_image(requester:Node, url:String, filepath:String):
	requester.debug_message("Fetching %s" % url)
	var http_request = HTTPRequest.new()
	http_request.name = url
	requester.add_child(http_request)
	var error = http_request.request(
		url
	)
	if error != OK:
		requester.debug_message("An error occurred in the HTTP request.", DebugType.ERROR)
		
	var result = await http_request.request_completed
	http_request.queue_free()
	
	var extension = url.get_extension()
	match extension:
		"png":
			await save_static(filepath, result[3])
		_:
			await save_animated(filepath, result[3])
	pass


static func save_static(filepath: String, buffer: PackedByteArray):
	var image = Image.new()

	if not DirAccess.dir_exists_absolute(filepath.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(filepath.get_base_dir())

	if filepath.ends_with("png"):
		var error = image.load_png_from_buffer(buffer)
		if error != OK:
			push_error("[TWINGE-Utils] Unable to load image '%s'." % filepath)
			return null
		image.save_png(filepath)
	elif filepath.ends_with("webp"):
		var error = image.load_webp_from_buffer(buffer)
		if error != OK:
			push_error("[TWINGE-Utils] Unable to load image '%s'." % filepath)
			return null
		image.save_webp(filepath)
	else:
		push_error("[TWINGE-Utils] Unsupported format: %s" % filepath)
		return
		
	print("[TWINGE-Utils]: Static image saved to '%s'." % filepath)


static func save_animated(path: String, buffer: PackedByteArray = []) -> Texture2D:
	if not DirAccess.dir_exists_absolute(path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		
	if ResourceLoader.exists("res://addons/magick_dumps/magick.gd"):
		if magick_loader == null:
			magick_loader = load("res://addons/magick_dumps/magick.gd").new()
		var tex = await magick_loader.dump_and_convert(path, buffer, "%s.res" % path, true)
		return tex
	return null


static func load_image(filepath: String) -> Texture2D:
	var tex: Texture2D
	
	if not DirAccess.dir_exists_absolute(filepath.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(filepath.get_base_dir())
		
	if not FileAccess.file_exists(filepath):
		return null
	
	if ResourceLoader.has_cached(filepath):
		tex = load(filepath)

	if tex != null:
		return tex
	
	var extension = filepath.get_extension()
	match extension:
		"png":
			var image = Image.new()
			var error = image.load(filepath)
			if error != OK:
				return null
			tex = ImageTexture.create_from_image(image)
			tex.take_over_path(filepath)
			return tex
		_:
			if not FileAccess.file_exists(filepath + ".res"):
				return null
			
			# load frames into AnimatedTexture
			return load(filepath + ".res") as AnimatedTexture


static func request(requester:Node, url: String, headers = {}, uri= {}, body = {}, method: HTTPClient.Method = HTTPClient.METHOD_GET):
	var http_request = HTTPRequest.new()
	http_request.name = url
	requester.add_child(http_request, false, Node.INTERNAL_MODE_BACK)
	
	var formatted_headers = http_headers(headers)
	if (0 < uri.size()):
		url = "%s?%s" % [
			url,
			query_string(uri)
		]
	
	var body_string = ""
	if (0 < body.size()):
		match headers.get("Content-Type", "application/json"):
			"application/json":
				body_string = JSON.stringify(body)
			"application/x-www-form-urlencoded":
				body_string = query_string(body)
			_:
				body_string = ""
	
	var error = http_request.request(
		url,
		PackedStringArray(formatted_headers),
		method,
		body_string,
	)
	if error != OK:
		requester.debug_message("An error occurred in the HTTP request.", DebugType.ERROR)
		return null
	
	var result = await http_request.request_completed
	http_request.queue_free()
	
	error = result[0]
	var status = result[1]
	
	var response_body = (result[3] as PackedByteArray).get_string_from_utf8()
	
	if status == 200 && !response_body.is_empty():
		var json = JSON.new()
		if json.parse(response_body) == OK:
			response_body = json.data
		else:
			requester.debug_message("JSON parse error. URL: %s\nBody: %s\nParse Error: %s" % [url, response_body,json.get_error_message()])
		
	
	if (400 <= status):
		requester.debug_message("Request failed, url:%s, status: %d, body: %s, data:%s" % [url, status, response_body, body], DebugType.WARNING)
	
	return {
		"code": status,
		"data": response_body
	}

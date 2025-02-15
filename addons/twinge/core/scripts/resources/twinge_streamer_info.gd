extends Resource
class_name TwingeStreamerInfo

const utilities = preload("../twinge_utilities.gd")

var game_name:String="Unknown"
var game_id:String
var live:bool=false
var title:String
var tags:Array[String]
var viewer_count:int=0
var start_time:String
var language:String
var thumbnail_url:String
var mature:bool

func stream_thumbnail()->Texture2D:
	return utilities.load_image(thumbnail_url)

static func from_json(json: String) -> TwingeStreamerInfo:
	var stream = TwingeStreamerInfo.new()
	var data = JSON.parse_string(json)
	
	stream.id = data.get("id")
	stream.login = data.get("login")
	stream.display_name = data.get("display_name")
	stream.color = Color.from_string(data.get("color"), Color.WEB_PURPLE)
	stream.cache_expirations = data.get("cache_expirations")
	stream.extra = data.get("extra", {})
	return stream

extends TwingeTriggerTemplate
class_name ChatTrigger

const emote_suffixes = ["_BW", "_HF", "_SG", "_SQ", "_TK"]
@export var case_sensitive:bool = false
@export_enum("At Start", "Anywhere", "Anywhere (Exact)") var where_to_match = 0
@export var aliases:String = ""
var aliases_array:PackedStringArray

func _ready() -> void:
	aliases_array = aliases.split(",")
	for i in range(aliases_array.size()):
		if !case_sensitive:
			aliases_array[i] = aliases_array[i].strip_edges().to_lower()
		else:
			aliases_array[i] = aliases_array[i].strip_edges()
	pass

func matches_alias(message:String)->int:
	if !case_sensitive:
		message = message.to_lower()
	var words = message.split(" ")
	if (where_to_match == 0 and aliases_array.has(words[0])):
		return 1
	for alias in aliases_array:
		if (where_to_match == 1):
			return message.count(alias)
		elif (where_to_match == 2):
			var regex = RegEx.new()
			regex.compile("\\W(%s)\\W" % alias)
			var results = regex.search_all(message)
			return results.size()
	return 0

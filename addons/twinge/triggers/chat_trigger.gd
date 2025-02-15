extends TwingeTriggerTemplate
class_name ChatTrigger

@export_enum("At Start", "Anywhere") var where_to_match = 0
@export var aliases:String = ""
var aliases_array:PackedStringArray

func _ready() -> void:
	aliases_array = aliases.split(",")
	for i in range(aliases_array.size()):
		aliases_array[i] = aliases_array[i].strip_edges()
	pass

func matches_alias(message)->bool:
	var words = message.split(" ")
	for alias in aliases_array:
		if ((where_to_match == 0 and words[0] == alias) or
			(where_to_match == 1 and message.contains(alias))):
				return true
	return false

extends TwingeTriggerTemplate
class_name ChatTrigger

const EMOTE_SUFFIXES = ["_BW", "_HF", "_SG", "_SQ", "_TK"]
## Whether to trigger off all case formats for the message, IE if "yes" will also trigger off "Yes" or "yES".
@export var case_sensitive:bool = false
## Where to match the alias.
## [br][b]At Start:[/b] Only works at the start of the message, IE "yes it is," not "it is, yes".
## [br][b]Anywhere:[/b] Anywhere in the message. [i]Note: This will match to matches within other words, IE "yes" matching to "e[/i]yes[i]."[/i]
## [br][b]Anywhere (Exact):[/b] Matches to any word in the message, but the match must be the complete word, and will not match if it is part of another word.
@export_enum("At Start", "Anywhere", "Anywhere (Exact)") var where_to_match = 0
## A comma- or line-separated list of aliases for the trigger to look for, IE "yes, yeah, yup."
@export_multiline var aliases:String = ""
var aliases_array:PackedStringArray

func _ready() -> void:
	aliases_array = aliases.replace("\n", ",").split(",", false)
	for i in range(aliases_array.size()):
		if !case_sensitive:
			aliases_array[i] = aliases_array[i].strip_edges().to_lower()
		else:
			aliases_array[i] = aliases_array[i].strip_edges()
	pass

func matches_alias(message:String)->int:
	if !case_sensitive:
		message = message.to_lower()
	var words:Array = message.split(" ")
	if (where_to_match == 0 and aliases_array.has(words[0])):
		return 1
	var count = 0
	for alias in aliases_array:
		if (where_to_match == 1):
			count += message.count(alias)
		elif (where_to_match == 2):
			var regex = RegEx.new()
			regex.compile("\\W(%s)\\W" % alias)
			var results = regex.search_all(message)
			count += results.size()
	return count

extends TwingeModule

var _pronouns = []

func _ready():
	service_identifier = "Module-AlejoPronouns"
	_pronouns = (await utilities.request(
		self, 
		"https://api.pronouns.alejo.io/v1/pronouns"
	)).data

func enrich_user(user:TwingeUser)->TwingeUser:
	if (!user.cache_expirations.has("pronouns") or 
		user.cache_expirations["pronouns"] < Time.get_unix_time_from_system()):
			debug_message("Cache has expired for Alejo Pronouns, making request")
			var result = await utilities.request(self, "https://api.pronouns.alejo.io/v1/users/%s" % user.display_name)
			
			# Alejo has requested a cache of at least 5 minutes - We'll go with 10 to reduce impact on their server
			user.cache_expirations["pronouns"] = floor(Time.get_unix_time_from_system()) + 600
			
			if result.code != 200 || result.data.is_empty():
				debug_message("Failed to get pronoun data for %s." % user.display_name)
				return user
			
			var user_pronoun = result.data
			var primary = _pronouns.get(user_pronoun.pronoun_id)
			var secondary = _pronouns.get(user_pronoun.alt_pronoun_id, primary)
			user.extra["pronouns"] = "%s/%s" % [
				primary.subject,
				secondary.subject if secondary != primary else secondary.object
			]
	return user

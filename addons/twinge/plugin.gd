@tool
extends EditorPlugin


func _enter_tree():
	# Register Settings
	if (!ProjectSettings.has_setting("TWINGE/oauth/client_ID")):
		ProjectSettings.get_setting("TWINGE/oauth/client_ID", "")
	if (!ProjectSettings.has_setting("TWINGE/oauth/client_secret")):
		ProjectSettings.set_setting("TWINGE/oauth/client_secret", "")
	if (!ProjectSettings.has_setting("TWINGE/encryption/key")):
		ProjectSettings.set_setting("TWINGE/encryption/key", "712bt3789t98astrd6r2193b81725")
	
	# Register Modules
	#add_custom_type("Ads Module", "Node", preload("modules/ads.gd"), preload("core/icons/twinge-module.png"))
	pass

func _exit_tree():
	# Unregister Settings
	ProjectSettings.set_setting("TWINGE/oauth/client_ID", null)
	ProjectSettings.set_setting("TWINGE/oauth/client_secret", null)
	ProjectSettings.set_setting("TWINGE/encryption/key", null)
	
	# Unregister Modules
	#remove_custom_type("Ads Module")
	pass

extends TwingePointRedeemTemplate
class_name TwingeSoundRedeemTemplate

@export_range(-30, 0, 0.1, "suffix:dB") var volume
var player:AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.max_polyphony = 10
	player.volume_db = volume
	add_child(player)
	pass

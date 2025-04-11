@icon("res://addons/twinge/core/icons/twinge-reward.png")
extends Node
class_name TwingePointRedeemTemplate

## The custom reward’s title. The title may contain a maximum of 45 characters and it must be unique amongst all of the broadcaster’s custom rewards.
@export var title:String
## A Boolean value that determines whether the reward is enabled. Viewers see only enabled rewards. The default is true.
@export var is_enabled:bool
## The cost of the reward, in Channel Points. The minimum is 1 point.
@export var cost:int
## The prompt shown to the viewer when they redeem the reward. Specify a prompt if is_user_input_required is true. The prompt is limited to a maximum of 200 characters.
@export_multiline() var description:String
## The background color to use for the reward. Specify the color using Hex format (for example, #9147FF).
@export_color_no_alpha var background_color:Color
## A Boolean value that determines whether the user needs to enter information when redeeming the reward. See the prompt field. The default is false.
@export var is_user_input_required:bool
## The maximum number of redemptions allowed per live stream. Applied only if is_max_per_stream_enabled is true. The minimum value is 1.
@export var max_per_stream:int
## The maximum number of redemptions allowed per user per stream. Applied only if is_max_per_user_per_stream_enabled is true. The minimum value is 1.
@export var max_per_user_per_stream:int
## The cooldown period, in seconds. Applied only if the is_global_cooldown_enabled field is true. The minimum value is 1; however, the minimum value is 60 for it to be shown in the Twitch UX.
@export var global_cooldown_seconds:int
## A Boolean value that determines whether redemptions should be set to FULFILLED status immediately when a reward is redeemed. If false, status is set to UNFULFILLED and follows the normal request queue process. The default is false.
@export var auto_complete_redemption:bool

## ID assigned to the redeem on Twitch's side after it's created. Should be returned/set by the handler.
var twitch_redeem_id:String

func run(_user, _details)->bool:
	return false

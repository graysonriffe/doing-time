# WeightButton class - A button that activates if an Actor puts its weight on it
class_name WeightButton
extends Activator

const CLASS_NAME = "WeightButton"

var noSetter: bool

var animationTime: float:
	set(value):
		if noSetter:
			animationTime = value
			return
		
		animationPlayer.active = true
		animationPlayer.seek(value, true)
		animationPlayer.active = false
		animationTime = value

@onready var area: Area3D = $Area3D
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $"../WeightButton2/AudioStreamPlayer3D"


func _ready() -> void:
	super()
	noSetter = true
	animationTime = 0.0
	noSetter = false


func _physics_process(_delta: float) -> void:
	if not animationPlayer.active:
		return
	
	_checkActors()
	
	if animationPlayer.is_playing():
		noSetter = true
		animationTime = animationPlayer.current_animation_position
		noSetter = false


# Update's button state based on if there are any actors in the area3D
func _checkActors():
	for body in area.get_overlapping_bodies():
		if body is Actor:
			if not isActivated():
				_activate()
			
			return
		
	if isActivated():
		_deactivate()


func _activate():
	activated = true
	animationPlayer.speed_scale = 1.0
	animationPlayer.play("activate")
	audio_stream_player_3d.play()

func _deactivate():
	activated = false
	animationPlayer.speed_scale = -2.0
	animationPlayer.play("activate", -1.0, 1.0, true)

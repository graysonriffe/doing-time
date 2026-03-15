# WeightButton class - A button that activates if an Actor puts its weight on it
class_name WeightButton
extends StaticBody3D

const CLASS_NAME = "WeightButton"

# Is the button pressed?
var activated: bool

var noSetter: bool

var animationTime: float:
    set(value):
        if noSetter:
            animationTime = value
            return
        
        var temp = animationPlayer.active
        animationPlayer.active = true
        animationPlayer.seek(value, true)
        animationPlayer.active = temp
        animationTime = value

@onready var area: Area3D = $Area3D
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    area.body_entered.connect(_bodyEntered)
    area.body_exited.connect(_bodyExited)
    
    activated = false
    noSetter = true
    animationTime = 0.0
    noSetter = false


func _physics_process(_delta: float) -> void:
    if not animationPlayer.active:
        return
    
    if animationPlayer.is_playing():
        noSetter = true
        animationTime = animationPlayer.current_animation_position
        noSetter = false


func _bodyEntered(body: Node):
    if body is Actor and animationPlayer.active:
        _checkActors()


func _bodyExited(body: Node):
    if body is Actor and animationPlayer.active:
        _checkActors()


# Update's button state based on if there are any actors in the area3D
func _checkActors():
    for body in area.get_overlapping_bodies():
        if body is Actor and not activated:
            _activate()
            return
        
    if activated:
        _deactivate()


func _activate():
    activated = true
    animationPlayer.play("activate")


func _deactivate():
    activated = false
    animationPlayer.play_backwards("activate")

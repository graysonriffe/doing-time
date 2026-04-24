# Door class - Something that can move when something tells it to
class_name Door
extends Node3D

const CLASS_NAME = "Door"

enum ActivatableType {AllActivators, AnyActivator}

# Variables
var open: bool

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

@export var type: ActivatableType
@export var activators: Array[Activator]
@export var deactivators: Array[Activator]

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    open = false
    noSetter = true
    animationTime = 0.0
    noSetter = false


func _physics_process(_delta: float) -> void:
    if not animationPlayer.active:
        return
    
    _checkActivators()
    
    if animationPlayer.is_playing():
        noSetter = true
        animationTime = animationPlayer.current_animation_position
        noSetter = false


func _checkActivators():
    var shouldBeOpen: bool = true
    
    # Check activators
    for activator: Activator in activators:
        if activator.isActivated() and type == ActivatableType.AnyActivator:
            shouldBeOpen = true
            break
            
        shouldBeOpen = shouldBeOpen and activator.isActivated()
    
    # Check deactivators
    for deactivator: Activator in deactivators:
        if deactivator.isActivated():
            shouldBeOpen = false
            break
    
    if shouldBeOpen and not open:
        _open()
    elif not shouldBeOpen and open:
        _close()


func _open():
    open = true
    animationPlayer.speed_scale = 1.0
    animationPlayer.play("open")


func _close():
    open = false
    animationPlayer.speed_scale = -1.0
    animationPlayer.play("open", -1.0, 1.0, true)

# Clone class - An Actor controlled by a CloneData resource
class_name Clone
extends Actor

var shouldReset: bool

# The CloneData that describes the clone's movements
@export var cloneData: CloneData

# onready variables
# TODO: Not a fan of how Clone accesses the timePassing variable
@onready var cloneGame: CloneGame = get_tree().root.find_child("CloneGame", true, false)

func _ready() -> void:
    hide() # Prevents the clone from briefly appearing at the world origin before reset() is called
    shouldReset = true


func _physics_process(delta: float) -> void:
    if shouldReset:
        reset()
        shouldReset = false
    
    # Set the look vector if time is passing
    if cloneGame.timePassing:
        var nextLookVector: Vector2 = cloneData.getLookVector(timeIndex)
        global_rotation.y = nextLookVector.y
        head.global_rotation.x = nextLookVector.x
        
        if cloneData.getJumpButton(timeIndex):
            jump()
    
    super(delta)
    
    if cloneGame.timePassing:
        timeIndex = cloneData.getNextTimeIndex(timeIndex)



func _getInputDirection() -> Vector2:
    if cloneGame.timePassing:
        return cloneData.getMovementVector(timeIndex)
    else:
        return Vector2.ZERO


# Resets the clone to its initial state when time is reset
func reset():
    show()
    timeIndex = 0
    position = cloneData.initialPosition
    var firstLookVector: Vector2 = cloneData.getLookVector(0)
    global_rotation.y = firstLookVector.y
    head.global_rotation.x = firstLookVector.x
    velocity = Vector3.ZERO
    movementDirectionSmoothed = Vector3.ZERO
    reset_physics_interpolation()

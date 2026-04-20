# Clone class - An Actor controlled by a CloneData resource
class_name Clone
extends Actor

var initialPosition: Vector3
var initialLookVector: Vector2
var initialVelocity: Vector3
var initialMovementDirectionSmoothed: Vector3

# Who "created" this clone?
var parentActor: Actor

# Collisions between Actors
var collisionsEnabled: bool:
    set(value):
        collisionsEnabled = value
        _enableCollisions(value)

# The color that should be set when the clone is reset
var defaultColor: ActorColor

# If a clone is disabled, it is invisible and does not process (happens before it exists in the timeline)
var enabled: bool

# The CloneData that describes the clone's movements
var cloneData: CloneData

@onready var cloneGame: CloneGame = get_tree().root.find_child("CloneGame", true, false)

func _ready() -> void:
    super()
    
    collisionsEnabled = false
    enabled = true
    reset()


func _physics_process(delta: float) -> void:
    # Set the look vector if time is passing
    if paused:
        return
    
    var nextLookVector: Vector2 = cloneData.getLookVector(cloneGame.getTimeIndex())
    global_rotation.y = nextLookVector.y
    head.global_rotation.x = nextLookVector.x
    
    if cloneData.getJumpButton(cloneGame.getTimeIndex()):
        _jump()
    
    if cloneData.getCrouchButton(cloneGame.getTimeIndex()) and not crouching:
        _crouch()
    elif not cloneData.getCrouchButton(cloneGame.getTimeIndex()) and crouching:
        _uncrouch()
    
    if cloneData.getInteractButton(cloneGame.getTimeIndex()):
        _interact()
    
    super(delta)
    
    if isOnFloor and not crouching and velocity.length() < 0.1:
        if not animationPlayer.is_playing():
            animationPlayer.play("idle")
    elif animationPlayer.current_animation == "idle":
        animationPlayer.stop()
    
    if not collisionsEnabled:
        _checkCollisions()


func getInputDirection() -> Vector2:
    if not paused:
        return cloneData.getMovementVector(cloneGame.getTimeIndex())
    else:
        return Vector2.ZERO


func getLookVector() -> Vector2:
    if not paused:
        return cloneData.getLookVector(cloneGame.getTimeIndex())
    else:
        return Vector2.ZERO


# Resets the clone to its initial state when the clone begins its lifetime
func reset():
    position = parentActor.position
    global_rotation.y = parentActor.getLookVector().y
    head.global_rotation.x = parentActor.getLookVector().x
    velocity = parentActor.velocity
    movementDirectionSmoothed = parentActor.movementDirectionSmoothed
    isOnFloorOverride = parentActor.isOnFloor
    color = defaultColor
    
    collisionsEnabled = false


func _checkCollisions():
    var bodies: Array[Node3D] = collisionDetector.get_overlapping_bodies()
    
    for eachBody: Node3D in bodies:
        if eachBody is Actor and eachBody != self:
            return
    
    _enableCollisions()


func _enableCollisions(shouldEnable: bool = true):
    set_collision_layer_value(3, shouldEnable)
    set_collision_mask_value(3, shouldEnable)

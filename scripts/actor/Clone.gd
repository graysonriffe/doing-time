# Clone class - An Actor controlled by a CloneData resource
class_name Clone
extends Actor

var shouldResetInterpolation: bool

var initialPosition: Vector3
var initialLookVector: Vector2
var initialVelocity: Vector3
var initialMovementDirectionSmoothed: Vector3

# Who "created" this clone?
var parentActor: Actor

# If a clone is disabled, it is invisible and does not process (happens before it exists in the timeline)
var enabled: bool

# The CloneData that describes the clone's movements
var cloneData: CloneData

@onready var cloneGame: CloneGame = get_tree().root.find_child("CloneGame", true, false)

@onready var collisionDetector: Area3D = $CollisionDetector

func _ready() -> void:
	super()
	collisionDetector.body_exited.connect(_collisionDetectorExited)
	
	paused = true
	enabled = true
	reset()


func _physics_process(delta: float) -> void:
	if shouldResetInterpolation:
		reset_physics_interpolation()
		shouldResetInterpolation = false
	
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


func getInputDirection() -> Vector2:
	if not paused:
		return cloneData.getMovementVector(cloneGame.getTimeIndex())
	else:
		return Vector2.ZERO


# Resets the clone to its initial state when the clone begins its lifetime
func reset():
	position = initialPosition
	global_rotation.y = initialLookVector.y
	head.global_rotation.x = initialLookVector.x
	velocity = initialVelocity
	movementDirectionSmoothed = initialMovementDirectionSmoothed
	
	shouldResetInterpolation = true
	
	add_collision_exception_with(parentActor)


func _collisionDetectorExited(body: Node):
	if body == parentActor:
		remove_collision_exception_with(body)

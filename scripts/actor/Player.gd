# Player script - An Actor that handles FPS movement and basic gameplay
class_name Player
extends Actor

# Constants
const MOUSE_SENSITIVITY = 0.3
const GAMEPAD_SENSITIVITY = 200

# FPS controller variables
var headBobbingVector: Vector2
var headBobbingTheta: float

var currentFrameInputDirection: Vector2
var currentFrameLookVector: Vector2
var currentFrameJumpButton: bool
var currentFrameCrouchButton: bool
var currentFrameInteractButton: bool

@onready var eyes: Node3D = $Head/EyesOffset/Eyes
@onready var viewModel: Node3D = $Head/EyesOffset/Eyes/Camera3D/RemoteViewModel

func _ready() -> void:
    super()


func _process(delta: float) -> void:
    if not paused:
        _handleGamepadLook(delta)


func _physics_process(delta: float) -> void:
    # Get Player movement inputs
    currentFrameInputDirection = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
    currentFrameLookVector = Vector2(head.global_rotation.x, global_rotation.y)
    currentFrameJumpButton = Input.is_action_pressed("jump")
    currentFrameCrouchButton = Input.is_action_pressed("crouch")
    currentFrameInteractButton = Input.is_action_just_pressed("interact")
    
    if not paused:
        if getJumpButton():
            _jump()
        
        if getCrouchButton() and not crouching:
            _crouch()
        elif not getCrouchButton() and crouching:
            _uncrouch()
            
        if getInteractButton():
            _attemptInteract()
    
    # Do headbobbing when walking on a floor, and reset when not
    if not paused and (velocity.length() > 2.0 and isOnFloor) or velocity.length() > WALKING_SPEED * 2:
        var thetaDelta: float
        var eyesAmplitude: float
        var viewModelAmplitude: float
        if not crouching:
            thetaDelta = 14.0
            eyesAmplitude = 0.1
            viewModelAmplitude = 0.01
        elif crouching:
            thetaDelta = 8.0
            eyesAmplitude = 0.05
            viewModelAmplitude = 0.005
        
        headBobbingTheta += thetaDelta * delta
        headBobbingVector = Vector2(sin(headBobbingTheta / 2) + 0.5, sin(headBobbingTheta))
        eyes.position.x = lerp(eyes.position.x, headBobbingVector.x * eyesAmplitude, 10.0 * delta)
        eyes.position.y = lerp(eyes.position.y, headBobbingVector.y * eyesAmplitude / 2.0, 10.0 * delta)
        viewModel.position.x = lerp(viewModel.position.x, headBobbingVector.x * viewModelAmplitude, 10.0 * delta)
        viewModel.position.y = lerp(viewModel.position.y, headBobbingVector.y * viewModelAmplitude / 2.0, 10.0 * delta)
    else:
        eyes.position.x = lerp(eyes.position.x, 0.0, 10.0 * delta)
        eyes.position.y = lerp(eyes.position.y, 0.0, 10.0 * delta)
        headBobbingTheta = 0.0
    
    # View model bobbing and sway - always tend toward home position
    var viewModelHomeY: float = 0.0 if not paused else 0.04
    viewModel.position.x = lerp(viewModel.position.x, 0.0, 5.0 * delta)
    viewModel.position.y = lerp(viewModel.position.y, viewModelHomeY, 5.0 * delta)
    
    super(delta)


func _unhandled_input(event: InputEvent) -> void:
    # When mouse is captured, mouse movement -> FPS head movement
    if event is InputEventMouseMotion:
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            _handleLook(event.relative * MOUSE_SENSITIVITY, 1e-4)


func _handleGamepadLook(delta: float):
    var lookVector: Vector2 = Input.get_vector("lookLeft", "lookRight", "lookUp", "lookDown")
    _handleLook(lookVector * GAMEPAD_SENSITIVITY * delta, 1e-3)


func _handleLook(change: Vector2, swayMultiplier: float):
    rotate_y(-deg_to_rad(change.x))
    head.rotate_x(-deg_to_rad(change.y))
    head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
    
    # View model sway
    viewModel.position.x -= change.x * swayMultiplier
    viewModel.position.y += change.y * swayMultiplier


# Called when seting up a new level
func reset(newTransform: Transform3D):
    global_transform = newTransform
    head.rotation = Vector3.ZERO
    velocity = Vector3.ZERO
    movementDirectionSmoothed = Vector3.ZERO
    eyes.position = Vector3.ZERO
    viewModel.position = Vector3.ZERO
    reset_physics_interpolation()
    
    color = ActorColor.White


func getInputDirection() -> Vector2:
    return currentFrameInputDirection


func getLookVector() -> Vector2:
    return currentFrameLookVector


func getJumpButton() -> bool:
    return currentFrameJumpButton


func getCrouchButton() -> bool:
    return currentFrameCrouchButton


func getInteractButton() -> bool:
    return currentFrameInteractButton

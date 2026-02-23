# Player script - An Actor that handles FPS movement and basic gameplay
class_name Player
extends Actor

# Constants
const MOUSE_SENSITIVITY = 0.3

# FPS controller variables
var headBobbingVector: Vector2
var headBobbingTheta: float

# Recording variables
# TODO: Maybe move recording logic to CloneGame, but it makes sense to be here for now
var recordingCurrently: bool
var recordingCloneData: CloneData

@onready var eyes: Node3D = $Head/Eyes
@onready var viewModel: Node3D = $Head/Eyes/Camera3D/RemoteViewModel

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    recordingCurrently = false
    recordingCloneData = CloneData.new()


func _physics_process(delta: float) -> void:
    # Record input_dir if recording is enabled
    if recordingCurrently:
        recordingCloneData.pushBackMovementVector(_getInputDirection())
        var currentLookVector = Vector2(head.global_rotation.x, global_rotation.y)
        recordingCloneData.pushBackLookVector(currentLookVector)
        recordingCloneData.pushBackJump(Input.is_action_pressed("jump"))
    
    # Do headbobbing when walking, and reset when not
    if velocity.length() > 2.0:
        headBobbingTheta += 14.0 * delta
        headBobbingVector = Vector2(sin(headBobbingTheta / 2) + 0.5, sin(headBobbingTheta))
        eyes.position.x = lerp(eyes.position.x, headBobbingVector.x * 0.1, 10.0 * delta)
        eyes.position.y = lerp(eyes.position.y, headBobbingVector.y * 0.05, 10.0 * delta)
        viewModel.position.x = lerp(viewModel.position.x, headBobbingVector.x * 0.01, 10.0 * delta)
        viewModel.position.y = lerp(viewModel.position.y, headBobbingVector.y * 0.005, 10.0 * delta)
    else:
        eyes.position.x = lerp(eyes.position.x, 0.0, 10.0 * delta)
        eyes.position.y = lerp(eyes.position.y, 0.0, 10.0 * delta)
        headBobbingTheta = 0.0
    
    # View model bobbing and sway - always tend toward home position
    viewModel.position.x = lerp(viewModel.position.x, 0.0, 5.0 * delta)
    viewModel.position.y = lerp(viewModel.position.y, 0.0, 5.0 * delta)
    
    super(delta)


# Handle all other inputs
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_released("pause"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    # Click -> capture mouse
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    # When mouse is captured, mouse movement -> FPS head movement
    if event is InputEventMouseMotion:
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            rotate_y(-deg_to_rad(event.relative.x * MOUSE_SENSITIVITY))
            head.rotate_x(-deg_to_rad(event.relative.y * MOUSE_SENSITIVITY))
            head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
            
            # View model sway
            viewModel.position.x -= event.relative.x * 1e-4
            viewModel.position.y += event.relative.y * 1e-4
    
    if event.is_action_pressed("jump"):
        jump()


func teleport(newTransform: Transform3D):
    global_transform = newTransform
    head.rotation = Vector3.ZERO
    reset_physics_interpolation()


func _getInputDirection() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

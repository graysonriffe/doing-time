# Player script - An Actor that handles FPS movement and basic gameplay
class_name Player
extends Actor

# Constants
const MOUSE_SENSITIVITY = 0.3

# FPS controller variables
var headBobbingVector: Vector2
var headBobbingTheta: float

var currentFrameInputDirection: Vector2
var currentFrameJumpButton: bool

@onready var eyes: Node3D = $Head/Eyes
@onready var viewModel: Node3D = $Head/Eyes/Camera3D/RemoteViewModel

# Process is used for jump so we can check it every frame instead of when key events happen
func _process(_delta: float) -> void:
    if not paused:
        if getJumpButton():
            _jump()


func _physics_process(delta: float) -> void:
    # Get Player movement inputs
    currentFrameInputDirection = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    currentFrameJumpButton = Input.is_action_pressed("jump")
    
    # Do headbobbing when walking, and reset when not
    if velocity.length() > 2.0 and not paused:
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


# Handle mouse
func _unhandled_input(event: InputEvent) -> void:
    # When mouse is captured, mouse movement -> FPS head movement
    if event is InputEventMouseMotion:
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            rotate_y(-deg_to_rad(event.relative.x * MOUSE_SENSITIVITY))
            head.rotate_x(-deg_to_rad(event.relative.y * MOUSE_SENSITIVITY))
            head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
            
            # View model sway
            viewModel.position.x -= event.relative.x * 1e-4
            viewModel.position.y += event.relative.y * 1e-4


func teleport(newTransform: Transform3D):
    global_transform = newTransform
    head.rotation = Vector3.ZERO
    velocity = Vector3.ZERO
    movementDirectionSmoothed = Vector3.ZERO
    reset_physics_interpolation()


func getInputDirection() -> Vector2:
    return currentFrameInputDirection


func getLookVector() -> Vector2:
    return Vector2(head.global_rotation.x, global_rotation.y)


func getJumpButton() -> bool:
    return currentFrameJumpButton

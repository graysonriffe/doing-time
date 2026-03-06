# Actor class - Abstract base class of Player and Clone
@abstract
class_name Actor
extends CharacterBody3D

# Constants
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Variables
var movementDirectionSmoothed: Vector3

# State variables
# Pauses and unpauses the actor
var paused: bool

var isOnFloor: bool
var isOnFloorOverride: bool

# onready variables
@onready var head: Node3D = $Head

func _init() -> void:
    paused = true
    isOnFloorOverride = false


func _physics_process(delta: float) -> void:
    if paused:
        return

    # Add the gravity.
    if not is_on_floor() or isOnFloorOverride:
        velocity += get_gravity() * delta
    
    # Get direction vector from either the Player or Clone
    var inputDirection: Vector2 = getInputDirection()
    var direction: Vector3 = (transform.basis * Vector3(inputDirection.x, 0, inputDirection.y)).normalized()
    
    # Smooth the movement, and differently depending on if the actor is mid-air
    if is_on_floor() or isOnFloorOverride:
        movementDirectionSmoothed = lerp(movementDirectionSmoothed, direction, 10.0 * delta)
    elif inputDirection != Vector2.ZERO:
        movementDirectionSmoothed = lerp(movementDirectionSmoothed, direction, 3.0 * delta)
    
    # Apply the movement
    velocity.x = movementDirectionSmoothed.x * SPEED
    velocity.z = movementDirectionSmoothed.z * SPEED
    
    # Apply collision forces to physics objects
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        if collision.get_collider() is RigidBody3D and movementDirectionSmoothed.length() > 0.5:
            collision.get_collider().apply_central_impulse(-collision.get_normal())
    
    move_and_slide()
    
    isOnFloor = is_on_floor()
    isOnFloorOverride = false


func pause():
    paused = true


func unpause():
    paused = false


@abstract
func getInputDirection() -> Vector2


func _jump():
    if is_on_floor():
        velocity.y = JUMP_VELOCITY

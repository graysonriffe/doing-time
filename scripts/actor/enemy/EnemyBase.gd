class_name EnemyBase
extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var fsm: EnemyFSM = $EnemyFSM

var player: CharacterBody3D = null
var last_known_position: Vector3 = Vector3.ZERO

var chase_speed := 4.0
var vision_interval := 0.15
var path_update_interval := 0.25
var search_duration := 2.0
var vision_angle := 90.0  # Total cone width in degrees.
var vision_range := 15.0  # Max detection distance in world units.
# Must include both the player's layer AND any occluding geometry layers
# so the ray is blocked by walls. e.g. 0b11 = layers 1 and 2.
var vision_mask := 0b11

func _ready() -> void:
    player = get_tree().get_first_node_in_group("Player")
    nav_agent.path_desired_distance = 0.5
    nav_agent.target_desired_distance = 1.0
    nav_agent.path_max_distance = 3.0
    nav_agent.avoidance_enabled = true
    nav_agent.radius = 0.5

func _physics_process(delta: float) -> void:
    if player == null:
        return
    fsm.physics_update(delta)
    move_and_slide()

func player_in_line_of_sight() -> bool:
    if player == null:
        return false

    var to_player := player.global_position - global_position

    # Distance check — skip the raycast entirely if too far away.
    if to_player.length() > vision_range:
        return false

    # Vision cone check. Forward is -basis.z in Godot's right-hand coordinate system.
    var forward := -global_transform.basis.z
    var dot := forward.dot(to_player.normalized())
    if dot < cos(deg_to_rad(vision_angle * 0.5)):
        return false

    # Raycast to check for occluding geometry.
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(
        global_position,
        player.global_position,
        vision_mask,
        [self]
    )
    var result := space.intersect_ray(query)
    if result and result.collider.is_in_group("Player"):
        last_known_position = player.global_position
        return true
    return false

func on_hearing_entered(body: Node3D) -> void:
    fsm.on_hearing_entered(body)

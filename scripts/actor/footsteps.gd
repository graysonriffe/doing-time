extends AudioStreamPlayer3D

@export var surface_sounds: Dictionary = {}

const STEP_INTERVAL: float = 1.6

var step_distance: float = 0.0
var player: CharacterBody3D

@onready var ray: RayCast3D = get_parent().get_node("GroundRay")

func _ready() -> void:
	player = get_parent() as CharacterBody3D
	assert(player != null, "FootstepSFX must be a child of CharacterBody3D")
	surface_sounds = {
		"default": preload("res://assets/Audio/sfx/steps/metal_steps.tres"),
		"concrete": preload("res://assets/Audio/sfx/steps/concrete_steps.tres"),
		"metal": preload("res://assets/Audio/sfx/steps/metal_steps.tres"),
	}

func _physics_process(delta: float) -> void:
	if player.is_on_floor() and player.velocity.length() > 0.1:
		step_distance += player.velocity.length() * delta
		if step_distance >= STEP_INTERVAL:
			step_distance = 0.0
			_play_footstep()
	else:
		step_distance = 0.0

func _get_surface_type() -> String:
	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider.has_meta("surface_type"):
			return collider.get_meta("surface_type")
	return "default"

func _play_footstep() -> void:
	var surface := _get_surface_type()
	stream = surface_sounds.get(surface, surface_sounds.get("default"))
	pitch_scale = randf_range(0.9, 1.1)
	play()

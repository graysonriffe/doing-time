class_name EnemyFSM
extends Node

var current_state: State = null

# Cached references so state transitions are refactor-safe and type-checked.
# These names must match the actual node names in the scene tree.
@onready var idle_state: State = $IdleState
@onready var alert_state: State = $AlertState
@onready var chase_state: State = $ChaseState
@onready var search_state: State = $SearchState

func _ready() -> void:
    await get_parent().ready
    for child in get_children():
        if child is State:
            child.enemy = get_parent()
            child.fsm = self
    current_state = idle_state
    current_state.enter()

func change_state(new_state: State) -> void:
    if new_state == current_state:
        return
    current_state.exit()
    current_state = new_state
    current_state.enter()

func physics_update(_delta: float) -> void:
    current_state.physics_update(_delta)

func on_hearing_entered(_body: Node3D) -> void:
    current_state.on_hearing_entered(_body)

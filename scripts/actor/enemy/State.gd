class_name State
extends Node
 
var enemy: EnemyBase
var fsm: EnemyFSM
 
func enter() -> void: pass
func exit() -> void: pass
func physics_update(_delta: float) -> void: pass
func on_hearing_entered(_body: Node3D) -> void: pass
 

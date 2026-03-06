# CloneData - A resource that contains everything a clone needs to replicate player actions
class_name CloneData
extends Resource

# The first and last timeIndex of the CloneData (when does this data begin and end?)
@export var startingTimeIndex: int
@export var endingTimeIndex: int

# A vector of Input.getVector Vector2s from player inputs on physics frames
@export var recordedMovement: Dictionary[int, Vector2]

# A vector of pitch and yaw pairs of the player's camera view on physics frames
@export var recordedLookVectors: Dictionary[int, Vector2]

# A boolean of the state of the jump button on physics frames
@export var recordedJumpButton: Dictionary[int, bool]

func _init() -> void:
    startingTimeIndex = -1
    endingTimeIndex = -1


func getRecordSize() -> int:
    return recordedMovement.size()


func pushBackMovementVector(timeIndex: int, vec: Vector2):
    recordedMovement[timeIndex] = vec


func pushBackLookVector(timeIndex: int, vec: Vector2):
    recordedLookVectors[timeIndex] = vec


func pushBackJump(timeIndex: int, jump: bool):
    recordedJumpButton[timeIndex] = jump


func setStartingTimeIndex(firstTimeIndex: int):
    startingTimeIndex = firstTimeIndex


func setEndingTimeIndex(lastTimeIndex: int):
    endingTimeIndex = lastTimeIndex


func getMovementVector(timeIndex: int) -> Vector2:
    assert(startingTimeIndex != -1, "StartingTimeIndex not defined for CloneData!")
    assert(endingTimeIndex != -1, "EndingTimeIndex not defined for CloneData!")
    
    if not (timeIndex >= startingTimeIndex and timeIndex <= endingTimeIndex):
        return Vector2.ZERO
    
    return recordedMovement[timeIndex]


func getLookVector(timeIndex: int) -> Vector2:
    assert(startingTimeIndex != -1, "StartingTimeIndex not defined for CloneData!")
    assert(endingTimeIndex != -1, "EndingTimeIndex not defined for CloneData!")
    
    if not (timeIndex >= startingTimeIndex and timeIndex <= endingTimeIndex):
        return recordedLookVectors[endingTimeIndex]
    
    return recordedLookVectors[timeIndex]


func getJumpButton(timeIndex: int) -> bool:
    assert(startingTimeIndex != -1, "StartingTimeIndex not defined for CloneData!")
    assert(endingTimeIndex != -1, "EndingTimeIndex not defined for CloneData!")
    
    if not (timeIndex >= startingTimeIndex and timeIndex <= endingTimeIndex):
        return false
    
    return recordedJumpButton[timeIndex]

# CloneGame class - Main game manager. Handles level changing, level time, and clones
class_name CloneGame
extends Node

# Enums
enum Gamestate {
    Playing, # Time is passing, player is moving
    Paused, # Time is paused, player is moving timeline or in the menu
    Loading # Level is changing
}

# Constants
const NUM_LEVELS: int = 1
const LEVEL_PATH: String = "res://scenes/levels/"

const CLONE_SCENE: PackedScene = preload("res://scenes/actor/clone.tscn")

# Gamestate variables
var gamestate: Gamestate

# Level variables
var currentLevel: int

# Time variables
var timeIndex: int

var timelineData: TimelineData;

var currentCloneData: CloneData

# onready variables
@onready var player: Player = $Player
@onready var levelContainer: Node = $Level
@onready var cloneContainer: Node = $Clones

@onready var pauseUI: Control = find_child("PauseUI", true, false)
@onready var tempRemoteLabel: Label = find_child("ScreenPlaceholderLabel", true, false)
@onready var timelineSlider: HSlider = find_child("TimelineSlider", true, false)
@onready var timelineTimeLabel: Label = find_child("TimelineTimeLabel", true, false)

func _ready() -> void:
    process_physics_priority = 1 # Makes CloneGame update after other stuff like Actors each physics process
    # Load main menu level
    _changeLevel(1)
    
    # Show main menu UI
    pauseUI.hide()
    timelineSlider.value_changed.connect(_timelineSliderChanged)
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    player.unpause()
    tempRemoteLabel.text = "Level Name and Info"


func _physics_process(_delta: float) -> void:
    if gamestate == Gamestate.Playing:
        _enableNewClones() # Clones spawned by other clones, if any
        _record()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.keycode == KEY_O and not event.pressed and gamestate == Gamestate.Playing:
            _changeLevel(1)
        
        if event.keycode == KEY_P and not event.pressed and gamestate == Gamestate.Playing:
            _changeLevel(2)
    
    if event.is_action_released("time_pause_unpause"):
        _attemptTogglePause()
    
    if event.is_action("time_forward") and event.is_pressed():
        if gamestate == Gamestate.Paused:
            timelineSlider.value = timelineSlider.value + 5
    
    if event.is_action("time_backward") and event.is_pressed():
        if gamestate == Gamestate.Paused:
            timelineSlider.value = timelineSlider.value - 5
    
    if event.is_action_released("branch"):
        _attemptBranch()


# Unloads current level and loads new level
func _changeLevel(newLevelNumber: int):
    gamestate = Gamestate.Loading
    
    # TODO: Move clone deletion somewhere else later
    _deleteAllClones()
    
    var levelScene: PackedScene = load(LEVEL_PATH + "level_" + str(newLevelNumber) + ".tscn")
    
    # Unload current level
    for child in levelContainer.get_children():
        child.queue_free()
        await child.tree_exited
    
    # Instantiate new level scene and add it to the level container node
    var levelSceneInstance: Level = levelScene.instantiate()
    levelContainer.add_child(levelSceneInstance)
    
    # Teleport player to PlayerStart marker
    # TODO: Probably move this later to another function
    var playerStart: Node3D = levelSceneInstance.find_child("PlayerStart")
    player.teleport(playerStart.global_transform)
    
    timeIndex = 0
    timelineData = TimelineData.new()
    timelineData.registerActor(player)
    timelineData.registerObjects(levelContainer)
    
    currentCloneData = CloneData.new()
    
    # Record timeIndex = 0 as the initial state of the level
    _record()
    
    gamestate = Gamestate.Playing


func getTimeIndex() -> int:
    return timeIndex


func _record():
    timelineData.recordData(timeIndex)
    _recordCloneData()
    
    timeIndex += 1


func _attemptTogglePause():
    if gamestate == Gamestate.Playing or gamestate == Gamestate.Paused:
        _togglePause()


func _togglePause():
    if gamestate == Gamestate.Playing:
        _doPause()
    elif gamestate == Gamestate.Paused:
        _doUnpause()
        _deleteDiscardedClones()


func _doPause():
    gamestate = Gamestate.Paused
    
    player.pause()
    _pauseClones()
    _pausePhysicsObjects()
    
    var lastTimeIndex: int = timeIndex - 1 # Current timeIndex doesn't have data yet
    currentCloneData.setEndingTimeIndex(lastTimeIndex)
    timelineSlider.max_value = lastTimeIndex
    timelineSlider.set_value_no_signal(lastTimeIndex)
    timelineSlider.grab_focus()
    _setTimelineTimeLabel(lastTimeIndex)
    
    pauseUI.show()
    tempRemoteLabel.text = "Pause Menu"
    
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _doUnpause():
    gamestate = Gamestate.Playing
    
    for tween in get_tree().get_processed_tweens():
        await tween.finished
    
    timeIndex = int(timelineSlider.value) + 1 # Resume recording on the next timeIndex, not the one paused on
    
    player.unpause()
    _disableHiddenClones()
    _pauseClones(false) # Unpause
    _pausePhysicsObjects(false) # Unpause
    
    pauseUI.hide()
    tempRemoteLabel.text = "Level Name and Info"
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _pausePhysicsObjects(pause : bool = true):
    var levelNodes : Array[Node] = _getAllChildren(levelContainer)
    
    for node : Node in levelNodes:
        if node is RigidBody3D:
            node.process_mode = Node.PROCESS_MODE_DISABLED if pause else Node.PROCESS_MODE_INHERIT


func _getAllChildren(node: Node, array: Array[Node] = []) -> Array[Node]:
    for child in node.get_children():
        array.append(child)
        
        if child.get_child_count() > 0:
            array = _getAllChildren(child, array)
    
    return array


func _pauseClones(pause: bool = true):
    for clone: Clone in cloneContainer.get_children():
        if pause:
            clone.pause()
        else:
            clone.unpause()


func _deleteClone(clone: Clone):
    clone.queue_free()
    timelineData.deregisterActor(clone)


func _deleteAllClones():
    for clone: Clone in cloneContainer.get_children():
        _deleteClone(clone)


func _deleteDiscardedClones():
    for clone: Clone in cloneContainer.get_children():
        if not clone.enabled and clone.parentActor == player:
            _deleteCloneAndChildren(clone)


func _deleteCloneAndChildren(clone: Clone):
    for eachClone: Clone in cloneContainer.get_children():
        if not eachClone.enabled and eachClone.parentActor == clone:
            _deleteCloneAndChildren(eachClone)
        
        _deleteClone(clone)


func _attemptBranch():
    if gamestate == Gamestate.Paused:
        _doBranch()


func _doBranch():
    _doUnpause()
    
    var newClone: Clone = CLONE_SCENE.instantiate()
    
    newClone.initialPosition = player.position
    newClone.initialLookVector = player.getLookVector()
    newClone.initialVelocity = player.velocity
    newClone.initialMovementDirectionSmoothed = player.movementDirectionSmoothed
    
    newClone.isOnFloorOverride = player.isOnFloor
    
    newClone.parentActor = player
    
    currentCloneData.setStartingTimeIndex(timeIndex)
    newClone.cloneData = currentCloneData.duplicate(true)
    
    cloneContainer.add_child(newClone)
    timelineData.registerActor(newClone)
    
    newClone.unpause()
    
    # Update Clone parents
    for clone: Clone in cloneContainer.get_children():
        if clone.parentActor == player and timeIndex < clone.cloneData.startingTimeIndex:
            clone.parentActor = newClone


func _timelineSliderChanged(value: float):
    var previewTimeIndex = int(value)
    
    timelineData.setData(int(previewTimeIndex))
    
    _showOrHideClonesInPreview(previewTimeIndex)
    
    _setTimelineTimeLabel(value)


func _showOrHideClonesInPreview(previewTimeIndex: int):
    for clone: Clone in cloneContainer.get_children():
        if previewTimeIndex < clone.cloneData.startingTimeIndex - 1:
            clone.hide()
        elif previewTimeIndex >= clone.cloneData.startingTimeIndex:
            clone.show()


func _disableClone(clone: Clone):
    clone.process_mode = Node.PROCESS_MODE_DISABLED
    timelineData.deregisterActor(clone)
    clone.enabled = false


func _enableClone(clone: Clone):
    clone.reset()
    clone.show()
    clone.process_mode = Node.PROCESS_MODE_INHERIT
    timelineData.registerActor(clone)
    clone.enabled = true


func _disableHiddenClones():
    for clone: Clone in cloneContainer.get_children():
        if not clone.visible:
            _disableClone(clone)


func _enableShownClones():
    for clone: Clone in cloneContainer.get_children():
        if clone.visible:
            _enableClone(clone)


func _enableNewClones():
    for clone: Clone in cloneContainer.get_children():
        if not clone.enabled and timeIndex >= clone.cloneData.startingTimeIndex - 1:
            _enableClone(clone)


func _setTimelineTimeLabel(value: float):
    var physicsTicksPerSecond: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
    var minutes: int = int(value / (60 * physicsTicksPerSecond))
    var seconds: int = int(float(int(value) % int(60 * physicsTicksPerSecond)) / physicsTicksPerSecond)
    timelineTimeLabel.text = "%d:%02d" % [minutes, seconds]


func _recordCloneData():
    currentCloneData.pushBackMovementVector(timeIndex, player.getInputDirection())
    currentCloneData.pushBackLookVector(timeIndex, player.getLookVector())
    currentCloneData.pushBackJump(timeIndex, player.getJumpButton())

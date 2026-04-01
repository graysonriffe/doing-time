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

var scrubTime: float

# onready variables
@onready var player: Player = $Player
@onready var levelContainer: Node = $Level
@onready var cloneContainer: Node = $Clones

@onready var pauseUI: Control = find_child("PauseUI", true, false)
@onready var remoteLabel: RichTextLabel = find_child("ScreenLabel", true, false)
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
    
    player.pause(false) # Unpause


func _physics_process(delta: float) -> void:
    _handleInput(delta)
    
    if gamestate == Gamestate.Playing:
        _enableNewClones() # Clones spawned by other clones, if any
        _record()
        
        timeIndex += 1


# Non-player action inputs
func _handleInput(delta: float):
    if Input.is_action_just_pressed("tempLoadLevel1"):
        if gamestate == Gamestate.Playing:
            _changeLevel(1)
    
    if Input.is_action_just_pressed("tempLoadLevel2"):
        if gamestate == Gamestate.Playing:
            _changeLevel(4)
    
    if Input.is_action_just_released("pauseUnpause"):
        _attemptTogglePause()
    
    var shouldScrubForward: bool = Input.is_action_pressed("timelineScrubForward")
    var shouldScrubBackward: bool = Input.is_action_pressed("timelineScrubBackward")
    
    _handleScrub(shouldScrubForward, shouldScrubBackward, delta)
    
    if Input.is_action_just_released("branch"):
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
    player.reset(playerStart.global_transform)
    
    timeIndex = 0
    timelineData = TimelineData.new()
    timelineData.registerActor(player)
    timelineData.registerObjects(levelContainer)
    
    currentCloneData = CloneData.new()
    
    # Record timeIndex = 0 as the initial state of the level
    _record()
    
    gamestate = Gamestate.Playing
    
    _updateRemoteLabel()


func getTimeIndex() -> int:
    return timeIndex


func _record():
    timelineData.recordData(timeIndex)
    _recordCloneData()


func _attemptTogglePause():
    if gamestate == Gamestate.Playing or gamestate == Gamestate.Paused:
        _togglePause()


func _togglePause():
    if gamestate == Gamestate.Playing:
        _doPause()
    elif gamestate == Gamestate.Paused:
        if _doUnpause():
            # Exception for unpausing a the beginning of the timeline
            if timeIndex == 1:
                _deleteAllClones()
            else:
                _deleteDiscardedClones()


func _doPause():
    gamestate = Gamestate.Paused
    
    player.pause()
    _pauseClones()
    _pausePhysicsObjects()
    _pauseAnimations()
    
    var lastTimeIndex: int = timeIndex - 1 # Current timeIndex doesn't have data yet
    currentCloneData.setEndingTimeIndex(lastTimeIndex)
    timelineSlider.max_value = lastTimeIndex
    timelineSlider.set_value_no_signal(lastTimeIndex)
    timelineSlider.grab_focus()
    _setTimelineTimeLabel(lastTimeIndex)
    
    pauseUI.show()
    _updateRemoteLabel()
    
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _doUnpause() -> bool:
    if get_tree().get_processed_tweens().size() > 0:
        return false
    
    gamestate = Gamestate.Playing
    
    timeIndex = int(timelineSlider.value) + 1 # Resume recording on the next timeIndex, not the one paused on
    
    player.pause(false) # Unpause
    _disableHiddenClones()
    _pauseClones(false) # Unpause
    _pausePhysicsObjects(false) # Unpause
    _pauseAnimations(false) # Unpause
    
    pauseUI.hide()
    _updateRemoteLabel()
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    return true


func _pauseClones(pause: bool = true):
    for clone: Clone in cloneContainer.get_children():
        clone.pause(pause)


func _pausePhysicsObjects(pause: bool = true):
    var levelNodes: Array[Node] = _getAllChildren(levelContainer)
    
    for node: Node in levelNodes:
        if node is RigidBody3D:
            node.process_mode = Node.PROCESS_MODE_DISABLED if pause else Node.PROCESS_MODE_INHERIT


func _getAllChildren(node: Node, array: Array[Node] = []) -> Array[Node]:
    for child in node.get_children():
        array.append(child)
        
        if child.get_child_count() > 0:
            array = _getAllChildren(child, array)
    
    return array


func _pauseAnimations(pause: bool = true):
    var levelNodes: Array[Node] = _getAllChildren(levelContainer)
    
    for node: Node in levelNodes:
        if node is AnimationPlayer:
            node.active = not pause


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
        if _playerIsNotRed():
            _doBranch()
        else:
            # Some sort of feedback
            pass


func _playerIsNotRed():
    return player.getColor() != Actor.ActorColor.Red


func _doBranch():
    if not _doUnpause():
        return
    
    var newClone: Clone = CLONE_SCENE.instantiate()
    
    # TODO: Remove this later with new crouching animations
    newClone.get_node("BodyCollision1").shape = newClone.get_node("BodyCollision1").shape.duplicate()
    newClone.get_node("BodyMesh").mesh = newClone.get_node("BodyMesh").mesh.duplicate()
    
    # TODO: Initial conditions might be better to be inherited from the parent in real time
    # instead of being manually set once when the clone is first created
    newClone.initialPosition = player.position
    newClone.initialLookVector = player.getLookVector()
    newClone.initialVelocity = player.velocity
    newClone.initialMovementDirectionSmoothed = player.movementDirectionSmoothed
    newClone.isOnFloorOverride = player.isOnFloor
    
    newClone.parentActor = player
    
    currentCloneData.setStartingTimeIndex(timeIndex)
    newClone.cloneData = currentCloneData.duplicate(true)
    
    cloneContainer.add_child(newClone)
    
    var playerColor: Actor.ActorColor = player.getColor()
    newClone.color = playerColor
    
    timelineData.registerActor(newClone)
    
    newClone.pause(false) # Unpause
    
    # Update Clone parents
    for clone: Clone in cloneContainer.get_children():
        if clone.parentActor == player and timeIndex < clone.cloneData.startingTimeIndex:
            clone.parentActor = newClone
    
    # Increment player color
    match playerColor:
        Actor.ActorColor.White:
            player.color = Actor.ActorColor.Green
        Actor.ActorColor.Green:
            player.color = Actor.ActorColor.Yellow
        Actor.ActorColor.Yellow:
            player.color = Actor.ActorColor.Red
    
    _updateRemoteLabel()


func _handleScrub(shouldScrubForward: bool, shouldScrubBackward: bool, delta: float):
    if shouldScrubForward:
        if gamestate == Gamestate.Paused:
            _scrub(true)
    
    if shouldScrubBackward:
        if gamestate == Gamestate.Paused:
            _scrub(false)
    
    if (shouldScrubForward or shouldScrubBackward) and gamestate == Gamestate.Paused:
        scrubTime += delta
    elif ((not shouldScrubForward) and (not shouldScrubBackward)) or gamestate == Gamestate.Playing:
        scrubTime = 0


func _scrub(forward: bool):
    var scrubDelta: int = 2
    
    if scrubTime > 1.5:
        scrubDelta *= 5
    
    timelineSlider.value += scrubDelta if forward else -scrubDelta


func _timelineSliderChanged(value: float):
    var previewTimeIndex = int(value)
    
    timelineData.setData(int(previewTimeIndex))
    
    _showOrHideClonesInPreview(previewTimeIndex)
    
    _setTimelineTimeLabel(value)
    
    _updateRemoteLabel()


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


func _enableNewClones():
    for clone: Clone in cloneContainer.get_children():
        if not clone.enabled and timeIndex >= clone.cloneData.startingTimeIndex - 1:
            clone.parentActor.color = clone.parentActor.getColor() + 1
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
    currentCloneData.pushBackCrouch(timeIndex, player.getCrouchButton())
    currentCloneData.pushBackInteract(timeIndex, player.getInteractButton())


func _updateRemoteLabel():
    match gamestate:
        Gamestate.Playing, Gamestate.Paused:
            var playerColor: Actor.ActorColor = player.getColor()
            var colorString: String
            match playerColor:
                Actor.ActorColor.White:
                    colorString = "[color=white]WHITE[/color]"
                Actor.ActorColor.Green:
                    colorString = "[color=green]GREEN[/color]"
                Actor.ActorColor.Yellow:
                    colorString = "[color=yellow]YELLOW[/color]"
                Actor.ActorColor.Red:
                    colorString = "[color=red]RED[/color]"
            
            remoteLabel.text = "You are:\n" + colorString

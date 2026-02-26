# CloneGame class - Main game manager. Handles level changing, level time, and clones
class_name CloneGame
extends Node

# Enums
enum Gamestate {
    Playing, # Time is passing, player is moving
    Paused # Time is paused, player is moving timeline or in the menu
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

var timelineData : TimelineData;

# onready variables
@onready var player: Player = $Player
@onready var levelContainer: Node = $Level
@onready var cloneContainer: Node = $Clones

@onready var pauseUI: Control = find_child("PauseUI", true, false)
@onready var tempRemoteLabel: Label = find_child("ScreenPlaceholderLabel", true, false)
@onready var timelineSlider: HSlider = find_child("TimelineSlider", true, false)
@onready var timelineTimeLabel: Label = find_child("TimelineTimeLabel", true, false)

func _ready() -> void:
    # Load main menu level
    timelineData = TimelineData.new()
    _changeLevel(1)
    
    # Show main menu UI
    pauseUI.hide()
    timelineSlider.value_changed.connect(_timelineSliderChanged)
    
    gamestate = Gamestate.Playing
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    player.enable()
    tempRemoteLabel.text = "Level Name and Info"
    
    timeIndex = 0
    timelineData.registerActor(player)
    timelineData.registerObjects(levelContainer)


func _physics_process(delta: float) -> void:
    if gamestate == Gamestate.Playing:
        timelineData.recordData(timeIndex)
        
        timeIndex += 1
    else:
        pass


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
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


# Unloads current level and loads new level
func _changeLevel(newLevelNumber: int):
    # TODO: Move clone deletion somewhere else later
    # _deleteAllClones()
    
    timelineData.clear()
    timeIndex = 0
    
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
    
    timelineData.registerActor(player)
    timelineData.registerObjects(levelContainer)


func _attemptTogglePause():
    if gamestate == Gamestate.Playing or gamestate == Gamestate.Paused:
        _togglePause()


func _togglePause():
    if gamestate == Gamestate.Playing:
        gamestate = Gamestate.Paused
        _doPause()
        tempRemoteLabel.text = "Pause Menu"
    else:
        gamestate = Gamestate.Playing
        _doUnpause()
        tempRemoteLabel.text = "Level Name and Info"


func _doPause():
    _disablePhysicsObjects()
    player.disable()
    
    pauseUI.show()
    
    timelineSlider.max_value = timeIndex - 1
    timelineSlider.set_value_no_signal(timeIndex - 1)
    _setTimelineTimeLabel(timeIndex - 1)
    
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _doUnpause():
    _disablePhysicsObjects(false)
    player.enable()
    
    pauseUI.hide()
    
    timeIndex = int(timelineSlider.value)
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _disablePhysicsObjects(disable : bool = true):
    var levelNodes : Array[Node] = _getAllChildren(levelContainer)
    
    for node : Node in levelNodes:
        if node is RigidBody3D:
            node.process_mode = Node.PROCESS_MODE_DISABLED if disable else Node.PROCESS_MODE_INHERIT


func _getAllChildren(node: Node, array: Array[Node] = []) -> Array[Node]:
    for child in node.get_children():
        array.append(child)
        
        if child.get_child_count() > 0:
            array = _getAllChildren(child, array)
    
    return array


func _timelineSliderChanged(value: float):
    timelineData.setData(int(value))
    
    _setTimelineTimeLabel(value)


func _setTimelineTimeLabel(value: float):
    var physicsTicksPerSecond: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
    var minutes: int = int(value / (60 * physicsTicksPerSecond))
    var seconds: int = int(float(int(value) % int(60 * physicsTicksPerSecond)) / physicsTicksPerSecond)
    timelineTimeLabel.text = "%d:%02d" % [minutes, seconds]


func _attemptToggleRecord():
    if ((gamestate == Gamestate.Paused and player.is_on_floor()) or player.recordingCurrently):
        _toggleRecording()


func _toggleRecording():
    player.recordingCurrently = not player.recordingCurrently
    
    if player.recordingCurrently == true:
        player.recordingCloneData.clear()
        player.recordingCloneData.initialPosition = player.position
        _togglePause()
    else:
        _togglePause()
        var newClone: Clone = CLONE_SCENE.instantiate()
        newClone.cloneData = player.recordingCloneData
        player.recordingCloneData = CloneData.new()
        cloneContainer.add_child(newClone)
        timelineData.registerActor(newClone)
    
    tempRemoteLabel.text = "Status: Recording" if player.recordingCurrently else "Status: Time Stopped"

# CloneGame class - Main game manager. Handles level changing, level time, and clones
class_name CloneGame
extends Node

# Enums
enum Gamestate {
    MainMenu, # Main menu
    Loading, # Level is changing
    Playing, # Time is passing, player is moving
    Paused, # Time is paused, player is moving timeline or in the pause menu
    Transition # On level win screen
}

enum InputMethod {
    MouseAndKeyboard,
    Gamepad
}

# Constants
const NUM_LEVELS: int = 4
const LEVEL_PATH: String = "res://scenes/levels/"

const CLONE_SCENE: PackedScene = preload("res://scenes/actor/clone.tscn")

# Gamestate variables
var gamestate: Gamestate

# Level variables
var currentLevel: int

# Current level state variables
var timeIndex: int

var timelineData: TimelineData;

var currentCloneData: CloneData

var scrubTime: float

# Keeps track of available clones of each clone
var availableClonesHistory: Dictionary[int, int]

var goal: Area3D

# All NoBranchZones in the current level
var noBranchZones: Array[Area3D]

var lastMousePosition: Vector2i

var inputMethod: InputMethod

# Main menu variables
var mainMenuRemoteMouseArea: Area3D
var mainMenu: PanelContainer
var mainMenuPlayButton: Button
var mainMenuSettingsButton: Button
var mainMenuCreditsButton: Button
var mainMenuQuitButton: Button

var credits: PanelContainer
var creditsBackButton: Button

var settings: PanelContainer
var settingsDisplayMode: OptionButton
var settingsMasterVolume: HSlider
var settingsMusicVolume: HSlider
var settingsBackButton: Button

var mainMenuPause: PanelContainer

# SFX
var pauseSFX: AudioStream = preload("res://assets/audio/sfx/pause.mp3")
var unpauseSFX: AudioStream = preload("res://assets/audio/sfx/unpause.mp3")
var branchSFX: AudioStream = preload("res://assets/audio/sfx/branch.mp3")
var branchFailSFX: AudioStream = preload("res://assets/audio/sfx/branch_fail.mp3")

var levelEndSFX: AudioStream = preload("res://assets/audio/sfx/level_end.mp3")
var gameWinSFX: AudioStream = preload("res://assets/audio/sfx/game_win.mp3")

# onready variables
@onready var player: Player = $Player
@onready var sceneContainer: Node = $Scene
@onready var cloneContainer: Node = $Clones

@onready var remoteSFXPlayer: AudioStreamPlayer = $Audio/RemoteSFXPlayer
@onready var noBranchZoneSFXPlayer: AudioStreamPlayer = $Audio/NoBranchZoneSFXPlayer
@onready var winSFXPlayer: AudioStreamPlayer = $Audio/WinSFXPlayer

@onready var timelineUI: Control = find_child("TimelineUI", true, false)
@onready var timelineSlider: HSlider = find_child("TimelineSlider", true, false)

@onready var interactPrompt: PanelContainer = find_child("InteractPrompt", true, false)
@onready var interactKeyHint: MarginContainer = find_child("InteractKeyLabelMargin", true, false)
@onready var interactGamepadHint: MarginContainer = find_child("InteractGamepadIconMargin", true, false)

@onready var levelWin: PanelContainer = find_child("LevelWin", true, false)
@onready var levelWinNextLevelButton: Button = find_child("LevelWinNextLevelButton", true, false)
@onready var levelWinExitButton: Button = find_child("LevelWinExitButton", true, false)

@onready var gameWin: PanelContainer = find_child("GameWin", true, false)
@onready var gameWinExitButton: Button = find_child("GameWinExitButton", true, false)

@onready var remoteMouseArea: Area3D = find_child("MouseArea", true, false)
@onready var remoteViewport: SubViewport = find_child("RemoteViewport", true, false)

@onready var remoteMainMenu: PanelContainer = find_child("MainMenu", true, false)

@onready var remoteCredits: PanelContainer = find_child("Credits", true, false)

@onready var remotePauseMenu: PanelContainer = find_child("PauseMenu", true, false)
@onready var remotePauseSettingsButton: Button = find_child("PauseSettingsButton", true, false)
@onready var remotePauseExitButton: Button = find_child("PauseExitButton", true, false)

@onready var remoteSettings: PanelContainer = find_child("Settings", true, false)
@onready var remoteSettingsDisplayMode: OptionButton = find_child("DisplayModeSelector", true, false)
@onready var remoteSettingsMasterVolume: HSlider = find_child("MasterVolumeSlider", true, false)
@onready var remoteSettingsMusicVolume: HSlider = find_child("MusicVolumeSlider", true, false)
@onready var remoteSettingsBackButton: Button = find_child("SettingsBackButton", true, false)

@onready var remoteTimeLabel: RichTextLabel = find_child("RemoteTimeLabel", true, false)
@onready var remotePaused: PanelContainer = find_child("RemotePaused", true, false)
@onready var remoteAvailableClonesLabel: RichTextLabel = find_child("AvailableClonesLabel", true, false)
@onready var remoteNoBranch: PanelContainer = find_child("NoBranch", true, false)

@onready var remotePlaySprite: Sprite3D = find_child("PlaySprite", true, false)
@onready var remotePauseSprite: Sprite3D = find_child("PauseSprite", true, false)
@onready var remotePauseUnpauseKeyLabel: Label3D = find_child("PauseUnpauseKeyLabel", true, false)
@onready var remotePauseUnpauseGamepadSprite: Sprite3D = find_child("PauseUnpauseGamepadSprite", true, false)
@onready var remoteReverseKeyLabel: Label3D = find_child("ReverseKeyLabel", true, false)
@onready var remoteReverseGamepadSprite: Sprite3D = find_child("ReverseGamepadSprite", true, false)
@onready var remoteForwardKeyLabel: Label3D = find_child("ForwardKeyLabel", true, false)
@onready var remoteForwardGamepadSprite: Sprite3D = find_child("ForwardGamepadSprite", true, false)
@onready var remoteBranchKeyLabel: Label3D = find_child("BranchKeyLabel", true, false)
@onready var remoteBranchGamepadSprite: Sprite3D = find_child("BranchGamepadSprite", true, false)
@onready var remoteAnimationPlayer: AnimationPlayer = find_child("RemoteAnimationPlayer", true, false)

func _ready() -> void:
    process_physics_priority = 1 # Makes CloneGame update after other stuff like Actors each physics process
    
    timelineUI.hide()
    interactPrompt.hide()
    levelWin.hide()
    gameWin.hide()
    
    remoteMainMenu.hide()
    remotePauseMenu.hide()
    remoteCredits.hide()
    remoteSettings.hide()
    
    # Level win menu setup
    levelWinNextLevelButton.pressed.connect(_nextLevel)
    levelWinExitButton.pressed.connect(_setupMainMenu)
    
    # Game win menu setup
    gameWinExitButton.pressed.connect(_setupMainMenu)
    
    # Remote pause menu setup
    remotePauseSettingsButton.pressed.connect(_remoteSettingsButtonPressed)
    remotePauseExitButton.pressed.connect(_setupMainMenu)
    
    # Remote settings menu setup
    remoteSettingsDisplayMode.item_selected.connect(_displayModeChanged)
    remoteSettingsMasterVolume.value_changed.connect(_masterVolumeChanged)
    remoteSettingsMusicVolume.value_changed.connect(_musicVolumeChanged)
    remoteSettingsBackButton.pressed.connect(_remoteSettingsBackButtonPressed)
    
    timelineSlider.value_changed.connect(_timelineSliderChanged)
    
    _setKeyLabels()
    
    remoteMouseArea.input_event.connect(_remoteInputEvent)
    
    lastMousePosition = get_viewport().get_visible_rect().size / 2
    
    inputMethod = InputMethod.MouseAndKeyboard
    
    await _setupMainMenu()


func _physics_process(delta: float) -> void:
    if gamestate == Gamestate.Playing:
        _enableNewClones() # Clones spawned by other clones, if any
        _record()
        
        timeIndex += 1
    
    _handleInput(delta)
    
    _checkInputMethod()
    
    if gamestate == Gamestate.Playing or gamestate == Gamestate.Paused:
        _updateUI()


func _setupMainMenu():
    if gamestate == Gamestate.Paused:
        RenderingServer.global_shader_parameter_set("pause_effect", false);
        MusicPlayer.pauseEffect(false) # Unpause
        timelineUI.hide()
        
        noBranchZoneSFXPlayer.stop()
    
    gamestate = Gamestate.MainMenu
    
    player.hide()
    
    RenderingServer.global_shader_parameter_set("remote_bulb_color", Color.WHITE)
    
    player.process_mode = Node.PROCESS_MODE_DISABLED
    
    await _changeScene("res://scenes/main_menu_scene.tscn")
    
    var mainMenuCamera: Camera3D = sceneContainer.find_child("MainMenuCamera", true, false)
    
    mainMenuCamera.current = true
    
    interactPrompt.hide()
    levelWin.hide()
    gameWin.hide()
    
    remoteViewport = sceneContainer.find_child("RemoteViewport", true, false)
    mainMenuRemoteMouseArea = sceneContainer.find_child("MouseArea", true, false)
    mainMenuRemoteMouseArea.input_event.connect(_mainMenuRemoteInputEvent)
    
    mainMenu = sceneContainer.find_child("MainMenu", true, false)
    
    mainMenu.show()
    
    mainMenuPlayButton = sceneContainer.find_child("MainPlayButton", true, false)
    mainMenuPlayButton.pressed.connect(_play)
    
    mainMenuSettingsButton = sceneContainer.find_child("MainSettingsButton", true, false)
    mainMenuSettingsButton.pressed.connect(_mainSettingsButtonPressed)
    
    mainMenuCreditsButton = sceneContainer.find_child("MainCreditsButton", true, false)
    mainMenuCreditsButton.pressed.connect(_creditsButtonPressed)
    
    mainMenuQuitButton = sceneContainer.find_child("MainQuitButton", true, false)
    mainMenuQuitButton.pressed.connect(func (): get_tree().quit())
    
    settings = sceneContainer.find_child("Settings", true, false)
    settings.hide()
    
    settingsDisplayMode = sceneContainer.find_child("DisplayModeSelector", true, false)
    settingsDisplayMode.item_selected.connect(_displayModeChanged)
    
    settingsMasterVolume = sceneContainer.find_child("MasterVolumeSlider", true, false)
    settingsMasterVolume.value_changed.connect(_masterVolumeChanged)
    
    settingsMusicVolume = sceneContainer.find_child("MusicVolumeSlider", true, false)
    settingsMusicVolume.value_changed.connect(_musicVolumeChanged)
    
    settingsBackButton = sceneContainer.find_child("SettingsBackButton", true, false)
    settingsBackButton.pressed.connect(_mainSettingsBackButtonPressed)
    
    credits = sceneContainer.find_child("Credits", true, false)
    credits.hide()
    
    creditsBackButton = sceneContainer.find_child("CreditsBackButton", true, false)
    creditsBackButton.pressed.connect(_creditsBackButtonPressed)
    
    mainMenuPause = sceneContainer.find_child("PauseMenu", true, false)
    mainMenuPause.hide()
    
    settingsDisplayMode.selected = get_window().mode == Window.MODE_FULLSCREEN
    settingsMasterVolume.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
    settingsMusicVolume.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")) * 4
    
    mainMenuPlayButton.grab_focus()


# Non-player movement inputs
func _handleInput(delta: float):
    if Input.is_action_just_released("pauseUnpause"):
        _attemptTogglePause()
    
    var shouldScrubForward: bool = Input.is_action_pressed("timelineForward")
    var shouldScrubBackward: bool = Input.is_action_pressed("timelineReverse")
    
    _handleScrub(shouldScrubForward, shouldScrubBackward, delta)
    
    if Input.is_action_just_released("branch"):
        _attemptBranch()
    
    if Input.is_action_just_pressed("ui_cancel") and gamestate == Gamestate.MainMenu:
        _handleBackButton()


# Changes levels and resets state variables
func _setupLevel(newLevelNumber: int):
    gamestate = Gamestate.Loading
    
    await _changeScene(LEVEL_PATH + "level_" + str(newLevelNumber) + ".tscn")
    
    # Teleport player to PlayerStart marker
    var playerStart: Node3D = sceneContainer.find_child("PlayerStart", true, false)
    player.reset(playerStart.global_transform)
    player.show()
    
    timeIndex = 0
    timelineData = TimelineData.new()
    timelineData.registerActor(player)
    timelineData.registerObjects(sceneContainer)
    
    currentCloneData = CloneData.new()
    
    # Record timeIndex = 0 as the initial state of the level
    _record()
    
    _resetAvailableClonesHistory()
    
    goal = sceneContainer.find_child("Goal", true, false)
    goal.body_entered.connect(_goalEntered)
    
    # Get all NoBranchZones
    noBranchZones.clear()
    var allNodes: Array[Node] = _getAllChildren(sceneContainer)
    
    for node: Node in allNodes:
        if node is Area3D and node.get("CLASS_NAME") == "NoBranchZone":
            noBranchZones.append(node)
    
    remoteViewport = player.find_child("RemoteViewport", true, false)
    
    remotePauseMenu.hide()
    
    remoteSettingsDisplayMode.selected = get_window().mode == Window.MODE_FULLSCREEN
    remoteSettingsMasterVolume.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
    remoteSettingsMusicVolume.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")) * 4
    
    player.pause(false) # Unpause
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    gamestate = Gamestate.Playing


func _resetAvailableClonesHistory():
    availableClonesHistory.clear()
    availableClonesHistory[0] = 2


func _changeScene(scene: String):
    _deleteAllClones()
    
    var levelScene: PackedScene = load(scene)
    
    # Unload current level
    for child in sceneContainer.get_children():
        child.queue_free()
        await child.tree_exited
    
    # Instantiate new level scene and add it to the level container node
    var levelSceneInstance: Node = levelScene.instantiate()
    sceneContainer.add_child(levelSceneInstance)


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
                _resetAvailableClonesHistory()
            else:
                _deleteDiscardedClones()


func _doPause():
    gamestate = Gamestate.Paused
    
    RenderingServer.global_shader_parameter_set("pause_effect", true);
    MusicPlayer.pauseEffect()
    
    remoteSFXPlayer.stream = pauseSFX
    remoteSFXPlayer.play()
    
    remoteAnimationPlayer.play("pauseUnpausePress")
    
    player.pause()
    _pauseClones()
    _pausePhysicsObjects()
    _pauseAnimations()
    
    var lastTimeIndex: int = timeIndex - 1 # Current timeIndex doesn't have data yet
    currentCloneData.setEndingTimeIndex(lastTimeIndex)
    timelineSlider.max_value = lastTimeIndex
    timelineSlider.set_value_no_signal(lastTimeIndex)
    
    timelineUI.show()
    remotePauseMenu.show()
    remotePauseSettingsButton.grab_focus()
    
    _checkInputMethod()
    
    if inputMethod == InputMethod.MouseAndKeyboard:
        get_viewport().warp_mouse(lastMousePosition)


func _doUnpause() -> bool:
    if get_tree().get_processed_tweens().size() > 0:
        if get_tree().get_processed_tweens().size() == 1 and get_tree().get_processed_tweens()[0] == MusicPlayer.pauseTween:
            pass
        else:
            return false
    
    gamestate = Gamestate.Playing
    
    RenderingServer.global_shader_parameter_set("pause_effect", false);
    MusicPlayer.pauseEffect(false) # Unpause
    
    remoteSFXPlayer.stream = unpauseSFX
    remoteSFXPlayer.play()
    
    remoteAnimationPlayer.play("pauseUnpausePress")
    
    timeIndex = int(timelineSlider.value) + 1 # Resume recording on the next timeIndex, not the one paused on
    
    player.pause(false) # Unpause
    _disableHiddenClones()
    _pauseClones(false) # Unpause
    _pausePhysicsObjects(false) # Unpause
    _pauseAnimations(false) # Unpause
    
    timelineUI.hide()
    remotePauseMenu.hide()
    remoteSettings.hide()
    
    lastMousePosition = get_viewport().get_mouse_position()
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    return true


func _pauseClones(pause: bool = true):
    for clone: Clone in cloneContainer.get_children():
        clone.pause(pause)


func _pausePhysicsObjects(pause: bool = true):
    var levelNodes: Array[Node] = _getAllChildren(sceneContainer)
    
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
    var levelNodes: Array[Node] = _getAllChildren(sceneContainer)
    
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
            
            availableClonesHistory[_getCurrentCloneIndex(timeIndex)] = 2
            _removeFutureAvailableCloneEntries()


func _deleteCloneAndChildren(clone: Clone):
    for eachClone: Clone in cloneContainer.get_children():
        if not eachClone.enabled and eachClone.parentActor == clone:
            _deleteCloneAndChildren(eachClone)
        
        _deleteClone(clone)


func _attemptBranch():
    if gamestate == Gamestate.Paused:
        if _clonesAvailable() and not _inNoBranchZone():
            _doBranch()
        else:
            remoteSFXPlayer.stream = branchFailSFX
            remoteSFXPlayer.play()


func _clonesAvailable():
    var timelineTimeIndex = timelineSlider.value # + 1?
    
    var currentClone: int = _getCurrentCloneIndex(timelineTimeIndex)
    
    return availableClonesHistory.get(currentClone, 0) > 0


func _getCurrentCloneIndex(currentTimeIndex: int) -> int:
    var returnVal: int = -1
    for index in availableClonesHistory.keys():
        if index <= currentTimeIndex:
            returnVal = index
    
    return returnVal


func _inNoBranchZone() -> bool:
    for noBranchZone: Area3D in noBranchZones:
        if noBranchZone.get_overlapping_bodies().find(player) != -1:
            return true
    
    return false


func _doBranch():
    if not _doUnpause():
        return
    
    remoteAnimationPlayer.play("branchPress")
    
    player.branchPlayer.play()
    
    var newClone: Clone = CLONE_SCENE.instantiate()
    
    # TODO: Remove this later with new crouching animations
    newClone.get_node("BodyCollision1").shape = newClone.get_node("BodyCollision1").shape.duplicate()
    newClone.get_node("BodyMesh").mesh = newClone.get_node("BodyMesh").mesh.duplicate()
    
    newClone.parentActor = player
    
    currentCloneData.setStartingTimeIndex(timeIndex)
    newClone.cloneData = currentCloneData.duplicate(true)
    
    var playerColor: Actor.ActorColor = player.getColor()
    newClone.defaultColor = playerColor
    
    cloneContainer.add_child(newClone)
    
    timelineData.registerActor(newClone)
    
    newClone.pause(false) # Unpause
    
    # Update Clone parents
    for clone: Clone in cloneContainer.get_children():
        if clone.parentActor == player and timeIndex < clone.cloneData.startingTimeIndex:
            clone.parentActor = newClone
    
    _incrementColor(player)
    
    _updateAvailableCloneHistory()


func _incrementColor(actor: Actor):
    match actor.color:
        Actor.ActorColor.White:
            actor.color = Actor.ActorColor.Green
        Actor.ActorColor.Green:
            actor.color = Actor.ActorColor.Yellow
        Actor.ActorColor.Yellow:
            actor.color = Actor.ActorColor.Red


func _updateAvailableCloneHistory():
    # Subtract 1 from current clone
    # Add new clone to history with 2
    # Remove all future entries
    var currentClone: int = _getCurrentCloneIndex(timeIndex)
    
    availableClonesHistory[currentClone] -= 1
    
    if not _isPlayerRed():
        availableClonesHistory[timeIndex] = 2
    else:
        availableClonesHistory[timeIndex] = 0
    
    _removeFutureAvailableCloneEntries()


func _removeFutureAvailableCloneEntries():
    for index in availableClonesHistory.keys():
        if index > timeIndex:
            availableClonesHistory.erase(index)


func _isPlayerRed() -> bool:
    return player.getColor() == Actor.ActorColor.Red


func _handleScrub(shouldScrubForward: bool, shouldScrubBackward: bool, delta: float):
    if gamestate == Gamestate.Paused:
        if shouldScrubForward:
            if not remoteAnimationPlayer.current_animation.contains("forward"):
                remoteAnimationPlayer.play("RESET")
                remoteAnimationPlayer.play("forwardPress")
                remoteAnimationPlayer.queue("forwardHold")
            _scrub(true)
        elif remoteAnimationPlayer.current_animation == "forwardHold":
            remoteAnimationPlayer.play("forwardRelease")
    
        if shouldScrubBackward:
            if not remoteAnimationPlayer.current_animation.contains("reverse"):
                remoteAnimationPlayer.play("RESET")
                remoteAnimationPlayer.play("reversePress")
                remoteAnimationPlayer.queue("reverseHold")
            _scrub(false)
        elif remoteAnimationPlayer.current_animation == "reverseHold":
            remoteAnimationPlayer.play("reverseRelease")
    
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
            _incrementColor(clone.parentActor)
            clone.parentActor.branchPlayer.play()
            _enableClone(clone)
            clone.reset_physics_interpolation()


func _getTimeString(value: float) -> String:
    var physicsTicksPerSecond: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
    var minutes: int = int(value / (60 * physicsTicksPerSecond))
    var seconds: int = int(float(int(value) % int(60 * physicsTicksPerSecond)) / physicsTicksPerSecond)
    return "%02d:%02d" % [minutes, seconds]


func _recordCloneData():
    currentCloneData.pushBackMovementVector(timeIndex, player.getInputDirection())
    currentCloneData.pushBackLookVector(timeIndex, player.getLookVector())
    currentCloneData.pushBackJump(timeIndex, player.getJumpButton())
    currentCloneData.pushBackCrouch(timeIndex, player.getCrouchButton())
    currentCloneData.pushBackInteract(timeIndex, player.getInteractButton())


func _goalEntered(body: Node3D):
    if gamestate == Gamestate.Playing and body == player and timeIndex > 10:
        _endLevel()


func _endLevel():
    gamestate = Gamestate.Transition
    
    _checkInputMethod()
    
    player.pause()
    
    if currentLevel == NUM_LEVELS: # All levels complete
        winSFXPlayer.stream = gameWinSFX
        winSFXPlayer.play()
            
        gameWin.show()
        gameWinExitButton.grab_focus()
        
    else:
        winSFXPlayer.stream = levelEndSFX
        winSFXPlayer.play()
        
        levelWin.show()
        levelWinNextLevelButton.grab_focus()


func _nextLevel():
    levelWin.hide()
    
    currentLevel += 1
    _setupLevel(currentLevel)


func _checkInputMethod():
    if not (gamestate != Gamestate.Playing and gamestate != Gamestate.Loading):
        return
    
    match inputMethod:
        InputMethod.MouseAndKeyboard:
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        
        InputMethod.Gamepad:
                Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _updateUI():
    if gamestate == Gamestate.Loading:
        return
    
    var sourceTimeIndex: int = timeIndex if gamestate == Gamestate.Playing else (timelineSlider.value as int)
    
    var playerColor: Actor.ActorColor = player.getColor()
    var numAvailableClones: int = availableClonesHistory[_getCurrentCloneIndex(sourceTimeIndex)]
    
    var availableClonesString: String = ""
    
    match numAvailableClones:
        1:
            availableClonesString = "☺[/color]"
        2:
            availableClonesString = "☺☺[/color]"
    
    var bulbColor: Color
    match playerColor:
        Actor.ActorColor.White:
            availableClonesString = availableClonesString.insert(0, "[color=green]")
            bulbColor = Color.WHITE
        Actor.ActorColor.Green:
            availableClonesString = availableClonesString.insert(0, "[color=yellow]")
            bulbColor = Color.GREEN
        Actor.ActorColor.Yellow:
            availableClonesString = availableClonesString.insert(0, "[color=red]")
            bulbColor = Color.YELLOW
        Actor.ActorColor.Red:
            bulbColor = Color.RED
    
    RenderingServer.global_shader_parameter_set("remote_bulb_color", bulbColor)
    
    remoteAvailableClonesLabel.text = availableClonesString
    
    remoteTimeLabel.text = _getTimeString(sourceTimeIndex)
    
    if _inNoBranchZone():
        remoteNoBranch.show()
        if not noBranchZoneSFXPlayer.playing:
            noBranchZoneSFXPlayer.play()
    else:
        remoteNoBranch.hide()
        noBranchZoneSFXPlayer.stop()
    
    if gamestate == Gamestate.Paused:
        remotePaused.show()
        remotePlaySprite.show()
        remotePauseSprite.hide()
    else:
        remotePaused.hide()
        remotePlaySprite.hide()
        remotePauseSprite.show()
    
    # Interact prompt
    interactPrompt.visible = gamestate == Gamestate.Playing and player.canInteract()
    
    # Update button hints and cursor state
    var isPaused: bool = gamestate == Gamestate.Paused
    
    remotePauseUnpauseKeyLabel.hide()
    remoteReverseKeyLabel.hide()
    remoteForwardKeyLabel.hide()
    remoteBranchKeyLabel.hide()
    
    remotePauseUnpauseGamepadSprite.hide()
    remoteReverseGamepadSprite.hide()
    remoteForwardGamepadSprite.hide()
    remoteBranchGamepadSprite.hide()
    
    interactKeyHint.hide()
    interactGamepadHint.hide()
    
    var allNodes: Array[Node] = _getAllChildren(sceneContainer)
    
    match inputMethod:
        InputMethod.MouseAndKeyboard:
            remotePauseUnpauseKeyLabel.show()
            remoteReverseKeyLabel.visible = isPaused
            remoteForwardKeyLabel.visible = isPaused
            remoteBranchKeyLabel.visible = isPaused
            
            interactKeyHint.show()
            
            for node: Node in allNodes:
                if node is Label3D and node.name.contains("KM"):
                    node.show()
                
                if node is Label3D and node.name.contains("Gamepad"):
                    node.hide()
        
        InputMethod.Gamepad:
            remotePauseUnpauseGamepadSprite.show()
            remoteReverseGamepadSprite.visible = isPaused
            remoteForwardGamepadSprite.visible = isPaused
            remoteBranchGamepadSprite.visible = isPaused
            
            interactGamepadHint.show()
            
            for node: Node in allNodes:
                if node is Label3D and node.name.contains("KM"):
                    node.hide()
                
                if node is Label3D and node.name.contains("Gamepad"):
                    node.show()


func _unhandled_input(event: InputEvent) -> void:
    # Detect mouse and keyboard or gamepad
    if event is InputEventJoypadButton or (event is InputEventJoypadMotion and abs(event.axis_value) > 0.1):
        inputMethod = InputMethod.Gamepad
    
    if event is InputEventKey or (event is InputEventMouseMotion and gamestate == Gamestate.Playing) or \
    (event is InputEventMouseButton):
        inputMethod = InputMethod.MouseAndKeyboard
    
    for eventKind in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
        if is_instance_of(event, eventKind):
            return
    
    remoteViewport.push_input(event)


func _mainMenuRemoteInputEvent(_camera: Node, event: InputEvent, eventPosition: Vector3, _normal: Vector3, _shapeIndex: int):
    var mousePos3D: Vector3 = mainMenuRemoteMouseArea.global_transform.affine_inverse() * eventPosition
    
    event.position = _calculateMouse(mousePos3D)
    
    remoteViewport.push_input(event)


func _remoteInputEvent(_camera: Node, event: InputEvent, eventPosition: Vector3, _normal: Vector3, _shapeIndex: int):
    var mousePos3D: Vector3 = remoteMouseArea.global_transform.affine_inverse() * eventPosition
    
    event.position = _calculateMouse(mousePos3D)
    
    remoteViewport.push_input(event)


func _calculateMouse(mousePos3D: Vector3) -> Vector2:
    var mousePos2D: Vector2 = Vector2(mousePos3D.x, -mousePos3D.y)
    
    const SCREEN_SIZE: Vector2 = Vector2(0.122, 0.0915)
    mousePos2D /= SCREEN_SIZE
    mousePos2D += Vector2(0.5, 0.5)
    
    const SCREEN_RESOLUTION: Vector2 = Vector2(1000, 750)
    mousePos2D = mousePos2D * SCREEN_RESOLUTION
    
    return mousePos2D


func _setKeyLabels():
    remotePauseUnpauseKeyLabel.text = (InputMap.action_get_events("pauseUnpause")[0] as InputEventKey).as_text_physical_keycode()
    remoteReverseKeyLabel.text = (InputMap.action_get_events("timelineReverse")[0] as InputEventKey).as_text_physical_keycode()
    remoteForwardKeyLabel.text = (InputMap.action_get_events("timelineForward")[0] as InputEventKey).as_text_physical_keycode()
    remoteBranchKeyLabel.text = (InputMap.action_get_events("branch")[0] as InputEventKey).as_text_physical_keycode()
    
    interactKeyHint.get_child(0).text =(InputMap.action_get_events("interact")[0] as InputEventKey).as_text_physical_keycode()


# UI Functions
func _play():
    player.process_mode = Node.PROCESS_MODE_INHERIT
    
    currentLevel = 1
    _setupLevel(currentLevel)


func _mainSettingsButtonPressed():
    mainMenu.hide()
    settings.show()
    
    settingsBackButton.grab_focus()


func _displayModeChanged(index: int):
    match index:
        0:
            get_window().mode = Window.MODE_WINDOWED
        
        1:
            get_window().mode = Window.MODE_FULLSCREEN


func _masterVolumeChanged(value: float):
    AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)


func _musicVolumeChanged(value: float):
    AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), value / 4)


func _mainSettingsBackButtonPressed():
    mainMenu.show()
    settings.hide()
    
    mainMenuSettingsButton.grab_focus()


func _creditsButtonPressed():
    mainMenu.hide()
    credits.show()
    
    creditsBackButton.grab_focus()


func _creditsBackButtonPressed():
    mainMenu.show()
    credits.hide()
    
    mainMenuCreditsButton.grab_focus()


func _remoteSettingsButtonPressed():
    remotePauseMenu.hide()
    remoteSettings.show()
    
    remoteSettingsBackButton.grab_focus()


func _remoteSettingsBackButtonPressed():
    remotePauseMenu.show()
    remoteSettings.hide()
    
    remotePauseSettingsButton.grab_focus()


func _handleBackButton():
    if settings.is_visible_in_tree():
        _mainSettingsBackButtonPressed()
    
    if credits.is_visible_in_tree():
        _creditsBackButtonPressed()

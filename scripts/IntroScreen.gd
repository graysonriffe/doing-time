# IntroScreen class - Shows the intro screen for a short time before loading the rest of the game
class_name IntroScreen
extends Control


func _ready() -> void:
    var waitTween: Tween = create_tween()
    
    waitTween.tween_interval(4.0)
    waitTween.finished.connect(_loadMainScene)


func _process(_delta: float) -> void:
    if Input.is_anything_pressed():
        _loadMainScene()


func _loadMainScene():
    get_tree().change_scene_to_file("res://scenes/clone_game.tscn")

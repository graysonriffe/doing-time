# MusicPlayer class - Global node that plays a music playlist in a random order
extends AudioStreamPlayer

var pauseTween: Tween

var lowPass: AudioEffectLowPassFilter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    bus = "Music"
    
    stream = preload("res://assets/audio/music/music_playlist.tres")
    
    lowPass = AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0) as AudioEffectLowPassFilter
    
    play()


func pauseEffect(shouldPause: bool = true):
    if pauseTween:
        pauseTween.kill()
        
    pauseTween = create_tween()
    pauseTween.set_parallel(true)
    pauseTween.set_trans(Tween.TRANS_SINE)
    
    if shouldPause:
        pauseTween.tween_property(lowPass, "cutoff_hz",  500.0, 0.3)
    else:
        pauseTween.tween_property(lowPass, "cutoff_hz",  20500.0, 0.3)

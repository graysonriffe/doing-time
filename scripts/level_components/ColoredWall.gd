# ColoredWall class - A wall that only applies to the same colored Actors
@tool
class_name ColoredWall
extends CSGBox3D

enum WallColor {
    Green,
    Yellow,
    Red
}

const COLOR_COLLISION_LAYERS: Dictionary[WallColor, int] = {
    WallColor.Green:    5,
    WallColor.Yellow:   6,
    WallColor.Red:      7
}

@export var color: WallColor:
    set(value):
        color = value
        print("hello")
        _update()


func _ready() -> void:
    _update()


func _update():
    for layer: int in COLOR_COLLISION_LAYERS.values():
        set_collision_layer_value(layer, false)
    
    set_collision_layer_value(COLOR_COLLISION_LAYERS[color], true)
    
    var shaderColor: Color = Color.BLACK
    match color:
        WallColor.Green:
            shaderColor = Color(0.0, 1.0, 0.0)
        WallColor.Yellow:
            shaderColor = Color(1.0, 1.0, 0.0)
        WallColor.Red:
            shaderColor = Color(1.0, 0.0, 0.0)
    
    set_instance_shader_parameter("color", shaderColor)

# ColoredWall class - A wall that only applies to the same colored Actors
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

@export var color: WallColor

func _init() -> void:
    set_collision_layer_value(COLOR_COLLISION_LAYERS[color], true)

# TimelineData resource - Holds data needed to scrub a level timeline
class_name TimelineData
extends Resource

# TimelineData collects the static state of all moving objects in a level.
# When the player scrubs the timeline, TimelineData provides the data necessary to recreate
# the state of the level at that time.

# Predefined recorded properties of various classes
const CLASS_RECORDED_PROPERTIES: Dictionary = {
    "Actor":            [":global_transform", "/Head:global_transform", ":velocity", ":movementDirectionSmoothed", ":isOnFloor"],
    "PhysicsObject":    [":global_transform", ":linear_velocity", ":angular_velocity"],
    "WeightButton":     [":activated", "/AnimationPlayer:current_animation", ":animationTime"],
}

# To get node references, we need access to the SceneTree
var sceneTree : SceneTree

# Data Dictionary - ("node path:property", Dictionary[timeIndex, value at that time])
# The inner Dictionary isn't an Array because clones will not have data starting at timeIndex of 0.
# They are necessarily created after some time has passed, so a Dictionary prevents
# needless memory usage.
@export var data: Dictionary[NodePath, Dictionary]

# Register either the Player or a newly, created Clone
func registerActor(actor: Actor):
    _registerNode(actor, "Actor")


# Iterate through every node in a level, find nodes with relevant classes to record them later
func registerObjects(levelContainer: Node):
    sceneTree = levelContainer.get_tree()
    
    var levelNodes: Array = _getAllChildren(levelContainer)
    
    for node : Node in levelNodes:
        var className = node.get("CLASS_NAME")
        
        if className != null and className in CLASS_RECORDED_PROPERTIES:
            _registerNode(node, className)


func deregisterActor(actor: Actor):
    var nodePath : String = actor.get_path()
    var propertyArray : Array = CLASS_RECORDED_PROPERTIES["Actor"]
    
    for property : String in propertyArray:
        var fullPropertyPath = "%s%s" % [nodePath, property]
        
        data.erase(NodePath(fullPropertyPath))


func recordData(timeIndex : int):
    for nodePathAndProperty : NodePath in data.keys():
        var node : Node = sceneTree.root.get_node(nodePathAndProperty)
        
        var property : String = nodePathAndProperty.get_concatenated_subnames()
        
        var currentData = node.get(property)
        
        data[nodePathAndProperty][timeIndex] = currentData


func setData(timeIndex : int):
    var tween : Tween = sceneTree.create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_parallel()
    
    for nodePathAndProperty : NodePath in data.keys():
        var node : Node = sceneTree.root.get_node(nodePathAndProperty)
        
        var property : String = nodePathAndProperty.get_concatenated_subnames()
        
        var dataAfter = data[nodePathAndProperty].get(timeIndex)
        
        if dataAfter != null:
            if property == "current_animation": # Don't tween a string!
                node.set(property, dataAfter)
            else:
                tween.tween_property(node, property, dataAfter, 0.07)


func _getAllChildren(node: Node, array: Array[Node] = []) -> Array[Node]:
    for child in node.get_children():
        array.append(child)
        
        if child.get_child_count() > 0:
            array = _getAllChildren(child, array)
    
    return array


func _registerNode(node: Node, className : String):
    var nodePath : String = node.get_path()
    var propertyArray : Array = CLASS_RECORDED_PROPERTIES[className]
    
    for property : String in propertyArray:
        var fullPropertyPath = "%s%s" % [nodePath, property]
        
        data[NodePath(fullPropertyPath)] = Dictionary()

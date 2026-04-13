# TimelineData resource - Holds data needed to scrub a level timeline
class_name TimelineData
extends Resource

# TimelineData collects the static state of all moving objects in a level.
# When the player scrubs the timeline, TimelineData provides the data necessary to recreate
# the state of the level at that time.

# Predefined recorded properties of various classes
const CLASS_RECORDED_PROPERTIES: Dictionary = {
    "Actor":            [":global_transform", "/Head:rotation", ":velocity", ":movementDirectionSmoothed", ":isOnFloor",
                        ":crouching", "/AnimationPlayer:current_animation", ":animationTime", ":color"],
    
    "PhysicsObject":    [":global_transform", ":linear_velocity", ":angular_velocity"],
    
    "WeightButton":     [":activated", "/AnimationPlayer:current_animation", ":animationTime", "/AnimationPlayer:speed_scale"],
    "Lever":            [":activated", "/AnimationPlayer:current_animation", ":animationTime", "/AnimationPlayer:speed_scale"],
    "Door":             [":open", "/AnimationPlayer:current_animation", ":animationTime", "/AnimationPlayer:speed_scale"]
}

# To get node references, we need access to the SceneTree
var sceneTree: SceneTree

# Data Dictionary - ("node path:property", Dictionary[timeIndex, value at that time])
# The inner Dictionary isn't an Array because clones will not have data starting at timeIndex of 0.
# They are necessarily created after some time has passed, so a Dictionary prevents
# needless memory usage.
var data: Dictionary[NodePath, Dictionary]

# Register either the Player or a newly, created Clone
func registerActor(actor: Actor):
    _registerNode(actor, "Actor")


# Iterate through every node in a level, find nodes with relevant classes to record them later
func registerObjects(levelContainer: Node):
    sceneTree = levelContainer.get_tree()
    
    var levelNodes: Array = _getAllChildren(levelContainer)
    
    for node: Node in levelNodes:
        var className = node.get("CLASS_NAME")
        
        if className != null and className in CLASS_RECORDED_PROPERTIES:
            _registerNode(node, className)


func deregisterActor(actor: Actor):
    var nodePath: String = actor.get_path()
    var propertyArray: Array = CLASS_RECORDED_PROPERTIES["Actor"]
    
    for property: String in propertyArray:
        var fullPropertyPath = "%s%s" % [nodePath, property]
        
        data.erase(NodePath(fullPropertyPath))


func recordData(timeIndex: int):
    for nodePathAndProperty: NodePath in data.keys():
        var node: Node = sceneTree.root.get_node(nodePathAndProperty)
        
        var property: String = nodePathAndProperty.get_concatenated_subnames()
        
        var currentData = node.get(property)
        
        data[nodePathAndProperty][timeIndex] = currentData


func setData(timeIndex: int):
    for tween: Tween in sceneTree.get_processed_tweens():
        tween.kill()
    
    var tween: Tween = sceneTree.create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_parallel()
    
    # Get list of before animations to know when they change
    var beforeAnimations: Dictionary[AnimationPlayer, StringName]
    
    for nodePathAndProperty: NodePath in data.keys():
        var property: String = nodePathAndProperty.get_concatenated_subnames()
        if property != "current_animation":
            continue
        var animationPlayer: AnimationPlayer = sceneTree.root.get_node(nodePathAndProperty)
        beforeAnimations[animationPlayer] = animationPlayer.current_animation
    
    for nodePathAndProperty: NodePath in data.keys():
        var node: Node = sceneTree.root.get_node(nodePathAndProperty)
        
        var property: String = nodePathAndProperty.get_concatenated_subnames()
        
        var dataAfter = data[nodePathAndProperty].get(timeIndex)
        
        if dataAfter != null:
            if property == "current_animation":
                var animationPlayer: AnimationPlayer = node as AnimationPlayer
                # Reset when no animation is playing
                if node.get_parent() is Actor:
                    if dataAfter == &"": # This probably won't work when we have a walking animation
                        node.active = true
                        animationPlayer.play("RESET")
                        animationPlayer.seek(0.0, true)
                        node.active = false
                animationPlayer.current_animation = dataAfter # Don't tween a string!
                continue
                
            elif property == "animationTime" and node is Actor: # Don't tween animationTime when the animation is changed
                var animationPlayer: AnimationPlayer = (node as Actor).animationPlayer
                var beforeAnimation = beforeAnimations[animationPlayer]
                var newNodePath: NodePath = "%s%s" % [node.get_path(), "/AnimationPlayer:current_animation"]
                var afterAnimation = data[newNodePath].get(timeIndex)
                if (afterAnimation != beforeAnimation):
                    node.set(property, dataAfter)
                    continue
            
            elif property == "color":
                node.set(property, dataAfter)
                continue
            
            tween.tween_property(node, property, dataAfter, 0.07)


func _getAllChildren(node: Node, array: Array[Node] = []) -> Array[Node]:
    for child in node.get_children():
        array.append(child)
        
        if child.get_child_count() > 0:
            array = _getAllChildren(child, array)
    
    return array


func _registerNode(node: Node, className: String):
    var nodePath: String = node.get_path()
    var propertyArray: Array = CLASS_RECORDED_PROPERTIES[className]
    
    for property: String in propertyArray:
        var fullPropertyPath = "%s%s" % [nodePath, property]
        
        data[NodePath(fullPropertyPath)] = Dictionary()

extends CSGBox3D

@export var wall_aabb: AABB
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_stream_player_3d.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
		
	print(player.getPauseState())
	if player.getPauseState() == true:
		if audio_stream_player_3d.playing:
			audio_stream_player_3d.stop()
	else:
		if !audio_stream_player_3d.playing:
			audio_stream_player_3d.play()

	# Convert player global pos → wall local space
	var local_player_pos = to_local(player.global_position)

	# Clamp in local space against the wall's own AABB
	var aabb = get_aabb()
	var clamped = Vector3(
		clamp(local_player_pos.x, aabb.position.x, aabb.position.x + aabb.size.x),
		clamp(local_player_pos.y, aabb.position.y, aabb.position.y + aabb.size.y),
		clamp(local_player_pos.z, aabb.position.z, aabb.position.z + aabb.size.z)
	)

	# Convert result back to global space for the audio emitter
	audio_stream_player_3d.global_position = to_global(clamped)

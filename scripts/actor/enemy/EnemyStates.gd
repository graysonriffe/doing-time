class_name EnemyStates

class Idle extends State:
    func enter() -> void:
        enemy.velocity = Vector3.ZERO

    func on_hearing_entered(_body: Node3D) -> void:
        if _body.is_in_group("Player"):
            fsm.change_state(fsm.alert_state)


class Alert extends State:
    var timer: float = 0.0

    func enter() -> void:
        timer = 0.0
        enemy.velocity = Vector3.ZERO

    func physics_update(_delta: float) -> void:
        timer += _delta
        if timer >= enemy.vision_interval:
            timer = 0.0
            if enemy.player_in_line_of_sight():
                fsm.change_state(fsm.chase_state)

    func on_hearing_entered(_body: Node3D) -> void:
        # Reset the scan timer so the guard re-checks immediately on new sounds.
        if _body.is_in_group("Player"):
            timer = 0.0


class Chase extends State:
    var line_of_sight_timer: float = 0.0
    var path_timer: float = 0.0

    func enter() -> void:
        line_of_sight_timer = 0.0
        path_timer = 0.0

    func exit() -> void:
        path_timer = 0.0

    func physics_update(_delta: float) -> void:
        line_of_sight_timer += _delta
        if line_of_sight_timer >= enemy.vision_interval:
            line_of_sight_timer = 0.0
            if not enemy.player_in_line_of_sight():
                fsm.change_state(fsm.search_state)
                return

        path_timer += _delta
        if path_timer >= enemy.path_update_interval:
            path_timer = 0.0
            enemy.nav_agent.target_position = enemy.last_known_position

        if not enemy.nav_agent.is_navigation_finished():
            var next_pos := enemy.nav_agent.get_next_path_position()
            enemy.velocity = (next_pos - enemy.global_position).normalized() * enemy.chase_speed
        else:
            enemy.velocity = Vector3.ZERO


class Search extends State:
    var timer: float = 0.0

    func enter() -> void:
        timer = enemy.search_duration
        enemy.nav_agent.target_position = enemy.last_known_position

    func physics_update(_delta: float) -> void:
        timer -= _delta
        if timer <= 0.0:
            fsm.change_state(fsm.idle_state)
            return

        if not enemy.nav_agent.is_navigation_finished():
            var next_pos := enemy.nav_agent.get_next_path_position()
            enemy.velocity = (next_pos - enemy.global_position).normalized() * enemy.chase_speed * 0.5
        else:
            enemy.velocity = Vector3.ZERO

    func on_hearing_entered(_body: Node3D) -> void:
        # Hearing something during a search bumps back to Alert to re-confirm visually.
        if _body.is_in_group("Player"):
            fsm.change_state(fsm.alert_state)

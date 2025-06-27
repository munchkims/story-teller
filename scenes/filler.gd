extends Node3D


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func turn_page():
    animation_player.play("Turn2")
    await animation_player.animation_finished
    hide()
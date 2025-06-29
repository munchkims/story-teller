extends Node2D

@onready var line_2d: Line2D = $Line2D

var _pressed: bool = false
var current_line: Line2D = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pressed = event.pressed

			if _pressed:
				current_line = Line2D.new()
				current_line.default_color = line_2d.default_color
				current_line.width_curve = line_2d.width_curve
				current_line.width = 7
				line_2d.add_child(current_line)
				current_line.add_point(event.position)
	elif event is InputEventMouseMotion and _pressed:
		current_line.add_point(event.position)
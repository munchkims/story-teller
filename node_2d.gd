extends Node2D

var is_inside
var hovering
@onready var area2d = $Area2D

func _process(delta):
	#queue_redraw()
	var mouse_pos = get_viewport().get_mouse_position()
	if is_point_inside_area2d(area2d, mouse_pos):
		if not hovering:
			hovering = true
			print("mouse ent")
			area2d.emit_signal("mouse_entered")
	else:
		if hovering:
			hovering = false
			print("mouse ext")
			area2d.emit_signal("mouse_exited")


func _on_area_2d_mouse_exited() -> void:
	modulate = Color.RED


func _on_area_2d_mouse_entered() -> void:
	modulate = Color.GREEN

# func _draw():
# 	draw_circle(get_local_mouse_position(), 4, Color.RED)

func is_point_inside_area2d(area: Area2D, point: Vector2) -> bool:
	var space_state = area.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = area.collision_layer
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var results = space_state.intersect_point(query)
	for r in results:
		if r.collider == area:
			return true
	return false

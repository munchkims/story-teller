extends Node3D

# The current page is the one on the left
var current_page_number = 1

# This is displayed when pages are not moving
@onready var static_page = $Book/Static
# This is displayed when pages are moving
@onready var turning_page = $Book/Turning
@onready var turning_animation = $Book/Turning/AnimationPlayer

# Pages when turning: left, animated side 1, animated side 2, right
@onready var pf1 = $Book/Turning/PageLeft
@onready var pf2 = $Book/Turning/Page/Skeleton3D/Front
@onready var pf3 = $Book/Turning/Page/Skeleton3D/Back
@onready var pf4 = $Book/Turning/PageRight


@export var ray_length: float = 1000.0
var camera: Camera3D

# Pages when static: left, right
@onready var ps1 = $Book/Static/PageLeft
@onready var ps2 = $Book/Static/PageRight

# There are 6 viewports. Current page (left) is v3, to its right is v4.
# Moreover, there are 2 pages before (v1, v2) and after (v5, v6)
@onready var v1 = $Viewport1
@onready var v2 = $Viewport2
@onready var v3 = $Viewport3
@onready var v4 = $Viewport4
@onready var v5 = $Viewport5
@onready var v6 = $Viewport6

@onready var animationPlayer: AnimationPlayer = $Book/Turning/AnimationPlayer

@onready var node_viewport_left: SubViewport = $Viewport3
@onready var node_viewport_right: SubViewport = $Viewport4

@onready var node_quad_left: MeshInstance3D = $Book/Static/PageLeft
@onready var node_quad_right: MeshInstance3D = $Book/Static/PageRight


@onready var node_area_left: Area3D = $Book/Static/PageLeft/Area3D
@onready var node_area_right: Area3D = $Book/Static/PageRight/Area3D


## Used for checking if the mouse is inside the Area3D.
var is_mouse_inside_left := false
var is_mouse_inside_right := false

## The last processed input touch/mouse event. Used to calculate relative movement.
var last_event_pos2D := Vector2()

## The time of the last event in seconds since engine start.
var last_event_time := -1.0

var last_hovered_side := "" # "left", "right", or ""

var closed_book = false;

@onready var book_animation_player: AnimationPlayer = $book_cover/AnimationPlayer2

@onready var filler_pages: Node3D = $Book/FillerPages


func _ready():
	update_page_number()
	turning_page.hide()
	set_texture(ps1, v3)
	set_texture(ps2, v4)
	
	
	camera = $Camera3D # Adjust this path to your Camera3D node
	assert(camera != null, "Camera3D node is required for raycasting.")
	
	node_area_left.mouse_entered.connect(func(): _mouse_entered_area("left"))
	node_area_left.mouse_exited.connect(func(): _mouse_exited_area("left"))
	
	
	node_area_left.input_event.connect(_mouse_input_event)
	
	
	node_area_right.mouse_entered.connect(func(): _mouse_entered_area("right"))
	node_area_right.mouse_exited.connect(func(): _mouse_exited_area("right"))
	node_area_right.input_event.connect(_mouse_input_event)
	
	
	animationPlayer.animation_finished.connect(_on_animation_finished)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		#jump(10)
		close_book()


# func _process(_delta):
# 	# Create a synthetic motion event
# 	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
# 		var viewport := get_viewport()
# 		var mouse_pos = viewport.get_mouse_position()
# 		var camera_v := get_viewport().get_camera_3d()

# 		if !camera_v:
# 			return

# 		var from = camera_v.project_ray_origin(mouse_pos)
# 		var to = from + camera_v.project_ray_normal(mouse_pos) * 1000

# 		# Perform a raycast
# 		var space_state = get_world_3d().direct_space_state
# 		var query = PhysicsRayQueryParameters3D.new()
# 		query.from = from
# 		query.to = to
# 		query.collide_with_areas = true
# 		query.collide_with_bodies = false

# 		var result = space_state.intersect_ray(query)
		
# 		if result:
# 			var collider = result.collider
# 			var pos = result.position

# 			if collider == node_area_left:
# 				last_hovered_side = "left"
# 				_send_motion_event_to_viewport(node_viewport_left, pos, node_quad_left)

# 			elif collider == node_area_right:
# 				last_hovered_side = "right"
# 				_send_motion_event_to_viewport(node_viewport_right, pos, node_quad_right)

# 			else:
# 				# Still over same side, just keep feeding motion
# 				if last_hovered_side == "left":
# 					_send_motion_event_to_viewport(node_viewport_left, pos, node_quad_left)
# 				elif last_hovered_side == "right":
# 					_send_motion_event_to_viewport(node_viewport_right, position, node_quad_right)

# 		else:
# 			last_hovered_side = ""
		
		
func cast_mouse_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		if collider and collider is MeshInstance3D:
			print("Mouse is pointing at:", collider)
		else:
			print("No mesh detected.")


func _input(_event):
	if turning_animation.is_playing():
		return
	if Input.is_action_just_pressed("ui_left"):
		turn_left()
	if Input.is_action_just_pressed("ui_right"):
		turn_right()


func turn_right():
	set_texture(pf1, v3)
	set_texture(pf2, v4)
	set_texture(pf3, v5)
	set_texture(pf4, v6)
	
	
	hide_and_show(pf4)
	
	static_page.hide()
	turning_page.show()
	turning_animation.play("Turn1")


func turn_left():
	if current_page_number <= 0:
		close_book()
		return
		
	set_texture(pf1, v1)
	set_texture(pf2, v2)
	set_texture(pf3, v3)
	set_texture(pf4, v4)
	hide_and_show(pf1)
	turning_page.show()
	static_page.hide()
	turning_animation.play("Turn2")
	
	
func hide_and_show(page: Node):
	page.hide() # Hide the node immediately
	await get_tree().create_timer(0.1).timeout # Wait for 0.1 seconds
	page.show() # Show the node again


func update_page_number(page_offset = 0):
	"""Changes current page's number by the offset and updates the viewports."""
	current_page_number += page_offset
	var number_offset = -2
	for v in [v1, v2, v3, v4, v5, v6]:
		var temp = current_page_number + number_offset

		if temp == 5:
			v.remove_child(v.get_child(0))
			var t = load("res://scenes/test.tscn").instantiate()
			v.add_child(t)
		elif temp == 6:
			v.remove_child(v.get_child(0))
			var t = load("res://scenes/test.tscn").instantiate()
			v.add_child(t)
		else:
			v.remove_child(v.get_child(0))
			var t = load("res://scenes/Page.tscn").instantiate()
			v.add_child(t)
			
			
		if v.get_child(0).has_method("set_number"):
			v.get_child(0).set_number(current_page_number + number_offset)
		number_offset += 1


func set_texture(page, viewport):
	"""Attaches a viewport texture to a page."""
	var mat = ShaderMaterial.new()
	var shader = load("res://shader/overlay_shader.gdshader")
	mat.shader = shader
	var standard_mat = load("res://images/Book.tres")
	var base_texture = standard_mat.albedo_texture
	mat.set_shader_parameter("base_texture", base_texture)
	mat.set_shader_parameter("overlay_texture", viewport.get_texture())
	mat.set_shader_parameter("alpha_scissor_threshold", 0.1)
	page.material_override = mat
	#page.material_override = StandardMaterial3D.new()
	#page.material_override.albedo_texture = viewport.get_texture()


func _on_animation_finished(anim_name):
	if (closed_book):
		turning_page.hide()
		return
	if anim_name == "Turn1":
		update_page_number(2)
	if anim_name == "Turn2":
		update_page_number(-2)
	static_page.show()
	turning_page.hide()


func _mouse_entered_area(page: String) -> void:
	if page == "left":
		is_mouse_inside_left = true
		is_mouse_inside_right = false
	else:
		is_mouse_inside_left = false
		is_mouse_inside_right = true
		
	print("inside " + page)


func _mouse_exited_area(page: String) -> void:
	if page == "left":
		is_mouse_inside_left = false
		is_mouse_inside_right = false
	else:
		is_mouse_inside_left = false
		is_mouse_inside_right = false
		
	print("outside " + page)


func _unhandled_input(event: InputEvent) -> void:
	# Check if the event is a non-mouse/non-touch event
	for mouse_event in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(event, mouse_event):
			# If the event is a mouse/touch event, then we can ignore it here, because it will be
			# handled via Physics Picking.
			return
	node_viewport_left.push_input(event)
	node_viewport_right.push_input(event)


func _mouse_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	var event_pos2D := Vector2()
	# Current time in seconds since engine start.
	var now := Time.get_ticks_msec() / 1000.0
	if is_mouse_inside_left:
		# Get mesh size to detect edges and make conversions. This code only supports PlaneMesh and QuadMesh.
		var quad_mesh_size: Vector2 = node_quad_left.mesh.size

		# Event position in Area3D in world coordinate space.
		var event_pos3D := event_position

		# Convert position to a coordinate space relative to the Area3D node.
		# NOTE: `affine_inverse()` accounts for the Area3D node's scale, rotation, and position in the scene!
		event_pos3D = node_quad_left.global_transform.affine_inverse() * event_pos3D
		
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)

		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5

		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= node_viewport_left.size.x
		event_pos2D.y *= node_viewport_left.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.
		
	elif is_mouse_inside_right:
		# Get mesh size to detect edges and make conversions. This code only supports PlaneMesh and QuadMesh.
		var quad_mesh_size: Vector2 = node_quad_right.mesh.size

		# Event position in Area3D in world coordinate space.
		var event_pos3D := event_position


		# Convert position to a coordinate space relative to the Area3D node.
		# NOTE: `affine_inverse()` accounts for the Area3D node's scale, rotation, and position in the scene!
		event_pos3D = node_quad_right.global_transform.affine_inverse() * event_pos3D
		
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)

		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5

		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= node_viewport_right.size.x
		event_pos2D.y *= node_viewport_right.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.

	elif last_event_pos2D != null:
		# Fall back to the last known event position.
		event_pos2D = last_event_pos2D

	# Set the event's position and global position.
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D

	# Calculate the relative event distance.
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_event_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		else:
			event.relative = event_pos2D - last_event_pos2D
			event.velocity = event.relative / (now - last_event_time)

	# Update last_event_pos2D with the position we just calculated.
	last_event_pos2D = event_pos2D

	# Update last_event_time to current time.
	last_event_time = now

	# Finally, send the processed input event to the viewport.
	if is_mouse_inside_left:
		#if event is InputEventMouseButton:
			#print(event)
		node_viewport_left.push_input(event)
		
	if is_mouse_inside_right:
		#if event is InputEventMouseButton:
			#print(event)
		node_viewport_right.push_input(event)

# func _send_motion_event_to_viewport(viewport: SubViewport, world_position: Vector3, quad_node: Node3D) -> void:
# 	print("motion sent")
# 	var mesh_size: Vector2 = quad_node.mesh.size
# 	var local_pos = quad_node.global_transform.affine_inverse() * world_position
# 	var uv_pos = Vector2(local_pos.x / mesh_size.x, -local_pos.y / mesh_size.y)
# 	uv_pos += Vector2(0.5, 0.5)
# 	var viewport_pos = uv_pos * Vector2(viewport.size)

# 	# Create and send a fake InputEventMouseMotion
# 	var motion := InputEventMouseMotion.new()
# 	motion.position = viewport_pos
# 	motion.global_position = viewport_pos
# 	motion.relative = Vector2.ZERO
# 	motion.velocity = Vector2.ZERO
# 	print(motion.position)
	
# 	#viewport.push_input(motion)

func jump(number):
	# potentially, I should add here 
	animationPlayer.speed_scale = 3
	for i in range(number):
		turn_right()
		if (i < number / 2):
			animationPlayer.speed_scale += 0.8 # Here should be an exponential increase
		else:
			animationPlayer.speed_scale -= 0.8 # Here should be an exponential decrease
		await animationPlayer.animation_finished
		await get_tree().process_frame
	
	animationPlayer.speed_scale = 1.0


func close_book():
	set_texture(pf1, v1)
	set_texture(pf2, v2)
	set_texture(pf3, v3)
	set_texture(pf4, v4)
	turning_page.show()
	static_page.hide()
	pf1.hide()
	closed_book = true
	close_filler()
	animationPlayer.play("Turn2")
	await get_tree().create_timer(0.2).timeout
	book_animation_player.play_backwards("open_book")

func close_filler():
	var all_filler = filler_pages.get_children()
	for child in all_filler:
		child.turn_page()
		await get_tree().create_timer(0.1).timeout

extends Node3D


@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var sub_viewport: SubViewport = $SubViewport
@onready var front: MeshInstance3D = $Page/Skeleton3D/Front


func _ready():
	var mat = ShaderMaterial.new()
	var shader = load("res://shader/overlay_shader.gdshader")
	mat.shader = shader
	var standard_mat = load("res://images/Book.tres")
	var base_texture = standard_mat.albedo_texture
	mat.set_shader_parameter("base_texture", base_texture)
	var texture_rect = TextureRect.new()
	texture_rect.texture = sub_viewport.get_texture()
	texture_rect.visible = false
	add_child(texture_rect)

	await get_tree().process_frame
	await get_tree().process_frame

	var ov_img = sub_viewport.get_texture().get_image()
	
	#ov_img.save_png("res://baked_page.png")
	var ov_texture = ImageTexture.create_from_image(ov_img)
	mat.set_shader_parameter("overlay_texture", ov_texture)
	mat.set_shader_parameter("alpha_scissor_threshold", 0.1)
	front.material_override = mat
	var scn = sub_viewport.get_child(0)
	scn.queue_free()


func turn_page():
	animation_player.play("Turn2")
	await animation_player.animation_finished
	hide()

func turn_right_page():
	animation_player.play("Turn1")
	await animation_player.animation_finished
	hide()

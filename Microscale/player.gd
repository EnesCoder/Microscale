extends RigidBody2D

@export var move_force = 100
@export var thrust_force = 220
var mouse_pos : Vector2
var can_thrust = true
var splitting = false
var rotation_force : Vector2
var mouse_in = false
var split = false
@onready var cell_group = get_tree().get_nodes_in_group("Player_cells")
@onready var meant_scale = $Sprite2D.scale.x
@onready var ui_holder = $UIHolder

func _ready():
	add_to_group("Player_cells")

	ui_holder.visible = false
	
	const min_force_dvdr = 2
	var rot_rand1 = randi_range(-move_force, -move_force/min_force_dvdr)
	var rot_rand2 = randi_range(move_force/min_force_dvdr, move_force)
	rotation_force = Vector2(randi_range(rot_rand1, rot_rand2), randi_range(rot_rand1, rot_rand2))

func Rotate_physically(force, delta):
	const rot_dvdr = 12 
	angular_velocity -= (force.x/rot_dvdr + force.y/(rot_dvdr-7)) * delta

func Scale(scalar : Vector2):
	$Sprite2D.scale += scalar 
	$CollisionShape2D.scale += scalar 
	$CollisionChecker.scale += scalar
	meant_scale = $Sprite2D.scale.x

func Scale_to(new_scale : Vector2):
	$Sprite2D.scale = new_scale 
	$CollisionShape2D.scale = new_scale 
	$CollisionChecker.scale = new_scale
	meant_scale = $Sprite2D.scale.x
	
func Reset_cells_vel():
	for cell in cell_group:
		cell.linear_velocity = Vector2.ZERO
		cell.angular_velocity = 0

func Split(delta):
	# setup
	Reset_cells_vel()
	print("mitosis")
	splitting = true
	var initial_m_scale = meant_scale
	
	# get the scalar
	var ss_panel = get_parent().get_node("Camera2D").get_node("SplitScalePanel")
	ss_panel.visible = true
	await get_parent().get_node("UIManager").split_scale_entered
	ss_panel.visible = false
	var split_scalar = ss_panel.get_node("TextEdit").text.to_float()
	split_scalar /= 100
	split_scalar = initial_m_scale * split_scalar
	print(str(split_scalar))
	
	var split_dist = 100
	
	# zoom to the split
	get_parent().get_node("Camera2D").interpolate_zoom(delta, global_position)
	
	# create the new cell
	var new_cell = duplicate()
	new_cell.z_index = -1
	new_cell.Scale_to(Vector2(split_scalar, split_scalar))
	new_cell.get_node("CollisionShape2D").disabled = true
	print(new_cell.get_node("Sprite2D").scale)
	get_parent().add_child(new_cell)
	
	# wait a bit
	await get_tree().create_timer(0.7).timeout
	
	# split and scale down
	while abs(new_cell.global_position.x - global_position.x) < split_dist*initial_m_scale:
		var down_scale = -delta*split_scalar
		if meant_scale > initial_m_scale-split_scalar: Scale(Vector2(down_scale, down_scale))
		else: Scale_to(Vector2(initial_m_scale-split_scalar, initial_m_scale-split_scalar))
		new_cell.global_position += Vector2(delta * split_dist*initial_m_scale, 0)
		await get_tree().create_timer(delta).timeout
	
	if meant_scale < initial_m_scale-split_scalar: Scale_to(Vector2(initial_m_scale-split_scalar, initial_m_scale-split_scalar))

	# creating the joint
	var connection_j = DampedSpringJoint2D.new()
	connection_j.length = 20
	connection_j.stiffness = 0.3
	connection_j.bias = 5
	connection_j.disable_collision = false
	connection_j.node_a = get_path()
	connection_j.node_b = new_cell.get_path()
	add_child(connection_j)
	connection_j.global_position = global_position + Vector2(30, 0)

	# finishesa
	new_cell.get_node("CollisionShape2D").disabled = false
	new_cell.z_index = 0
	splitting = false

func Thrust():
	can_thrust = false
	$ThrustTimer.start()
	var thrust_dir = (mouse_pos - global_position).normalized()
	apply_impulse(thrust_dir * thrust_force)

func Get_min_coords(objects):
	var min_y = objects[0].y
	var min_x = objects[0].x
	for o in objects:
		if o.y < min_y: min_y = o.y
		if o.x < min_x: min_x = o.x
	return Vector2(min_x, min_y)

func Get_max_coords(objects):
	var max_y = objects[0].y
	var max_x = objects[0].x
	for o in objects:
		if o.y > max_y: max_y = o.y
		if o.x > max_x: max_x = o.x
	return Vector2(max_x, max_y)
	
func Transform_organism():
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_in:
				print("mouse click on cell "+str(cell_group.find(self)))
				ui_holder.visible = not ui_holder.visible
				print(name)
				for c in cell_group:
					if c != self: c.ui_holder.visible = false
			#elif ui_holder.visible:
			#	ui_holder.visible = false

func _process(_delta):
	mouse_pos = get_parent().get_node("Camera2D").get_global_mouse_position()
	Transform_organism()
	ui_holder.global_rotation = 0
	$UIHolder/CellInfo.set_item_text(0, "Scale: "+str(meant_scale*10)+" µm")

func _physics_process(delta):
	var move_dir = (Input.get_vector("left", "right", "up", "down")).normalized()
	var force = move_dir * move_force
	var can_move = true
	for c in cell_group:
		if c.splitting:
			can_move = false
			break
	if can_move:
		apply_central_force(force)
		if force:
			Rotate_physically(rotation_force * move_dir.x, delta)
		if Input.is_action_just_pressed("thrust") and can_thrust:
			Thrust()
	if splitting:
		Reset_cells_vel()
	if split:
		split = false
		if meant_scale >= 0.25:
			await Split(delta)

func _on_thrust_timer_timeout():
	can_thrust = true

func _on_collision_checker_body_entered(body):
	pass

func _on_collision_checker_body_exited(body):
	pass

func _on_collision_checker_mouse_entered():
	mouse_in = true

func _on_collision_checker_mouse_exited():
	mouse_in = false

func _on_split_button_pressed():
	if not split:
		ui_holder.visible = false
		split = true

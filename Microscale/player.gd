extends RigidBody2D

@export var move_force = 100
@export var thrust_force = 220
var mouse_pos : Vector2
var can_thrust = true
var splitting = false
var rotation_force : Vector2
var connection_j : DampedSpringJoint2D
@onready var meant_scale = $Sprite2D.scale
const split_dist = 140

func _ready():
	add_to_group("Player_cells")
	
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
	meant_scale = $Sprite2D.scale

func Scale_to(new_scale : Vector2):
	$Sprite2D.scale = new_scale 
	$CollisionShape2D.scale = new_scale 
	$CollisionChecker.scale = new_scale
	meant_scale = $Sprite2D.scale

func Split(delta):
	# setup
	splitting = true
	for cell in get_tree().get_nodes_in_group("Player_cells"):
		cell.linear_velocity = Vector2.ZERO
		cell.angular_velocity = 0
	
	# zoom to the split
	get_parent().get_node("Camera2D").interpolate_zoom(delta, global_position)
	
	# create the new cell
	var new_cell = duplicate()
	new_cell.z_index = -1
	new_cell.Scale(Vector2(-0.1, -0.1))
	new_cell.get_node("CollisionShape2D").disabled = true
	print(new_cell.get_node("Sprite2D").scale)
	get_parent().add_child(new_cell)
	
	# wait a bit
	await get_tree().create_timer(0.7).timeout
	
	# split and scale down
	while abs(new_cell.global_position.x - global_position.x) < split_dist*meant_scale.x:
		if meant_scale.x > meant_scale.x-0.1: Scale(Vector2(-delta*0.1, -delta*0.1))
		else: Scale_to(Vector2(meant_scale.x-0.1, meant_scale.x-0.1))
		new_cell.global_position += Vector2(delta * 70, 0)
		await get_tree().create_timer(delta).timeout

	connection_j = DampedSpringJoint2D.new()
	connection_j.length = 22
	connection_j.stiffness = 0.2
	connection_j.bias = 3
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

func _process(_delta):
	mouse_pos = get_parent().get_node("Camera2D").get_global_mouse_position()

func _physics_process(delta):
	var move_dir = (Input.get_vector("left", "right", "up", "down")).normalized()
	var force = move_dir * move_force
	if not splitting:
		apply_central_force(force)
		if force:
			Rotate_physically(rotation_force * move_dir.x, delta)
		if Input.is_action_just_pressed("thrust") and can_thrust:
			Thrust()
	if Input.is_action_just_pressed("split"):
		if meant_scale.x > 0.25:
			await Split(delta)

func _on_thrust_timer_timeout():
	can_thrust = true

func _on_collision_checker_body_entered(body):
	pass

func _on_collision_checker_body_exited(body):
	pass

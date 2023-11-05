extends RigidBody2D

@export var move_force = 80
@export var thrust_force = 200
@export var max_lin_vel = 200
@export var max_ang_vel = 100
var mouse_pos : Vector2
var can_thrust = true

func _ready():
	pass

func Split(delta):
	var initial_lin_vel = linear_velocity
	var initial_ang_vel = angular_velocity
	angular_velocity = 0
	linear_velocity = Vector2(0, 0)
	
	get_parent().get_node("Camera2D").interpolate_zoom(delta)
	
	$CollisionShape2D.disabled = true
	var new_cell = duplicate()
	new_cell.get_node("CollisionShape2D").disabled = true
	get_parent().add_child(new_cell)
	
	await get_tree().create_timer(0.6).timeout
	
	while abs(new_cell.global_position.x - global_position.x) < 80:
		new_cell.global_position += Vector2(delta * 70, 0)
		await get_tree().create_timer(delta).timeout

	$CollisionShape2D.disabled = false
	new_cell.get_node("CollisionShape2D").disabled = false
	linear_velocity = initial_lin_vel
	angular_velocity = initial_ang_vel

func Thrust():
	can_thrust = false
	$ThrustTimer.start()
	var thrust_dir = (mouse_pos - global_position).normalized()
	apply_impulse(thrust_dir * thrust_force)

func _process(_delta):
	mouse_pos = get_viewport().get_mouse_position()
	clamp(linear_velocity.x, -max_lin_vel, max_lin_vel)
	clamp(linear_velocity.y, -max_lin_vel, max_lin_vel)
	clamp(angular_velocity, -max_ang_vel, max_ang_vel)

func _physics_process(delta):
	var move_dir = (Input.get_vector("left", "right", "up", "down")).normalized()
	var force = move_dir * move_force
	apply_force(force, global_position)
	if Input.is_action_just_pressed("thrust") and can_thrust:
		Thrust()
		await Split(delta)
	# global position is the position in the world space / screen, and position is the local position which is the posiotion relative to the parent object

func _on_thrust_timer_timeout():
	can_thrust = true

extends RigidBody2D

@export var move_force = 80
@export var thrust_force = 200
@export var max_lin_vel = 200
@export var max_ang_vel = 100
var mouse_pos : Vector2
var can_thrust = true

func _ready():
	pass

func Split():
	$Sprite2D.scale /= Vector2(2, 2)
	$CollisionShape2D.scale /= Vector2(2, 2)
	var new_p = duplicate()
	new_p.global_position = global_position + Vector2(20, 0)
	get_parent().add_child(new_p)

func Thrust():
	can_thrust = false
	$ThrustTimer.start()
	var thrust_dir = (mouse_pos - global_position).normalized()
	apply_impulse(thrust_dir * thrust_force)

func _process(delta):
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
		Split()
	# global position is the position in the world space / screen, and position is the local position which is the posiotion relative to the parent object

func _on_thrust_timer_timeout():
	can_thrust = true

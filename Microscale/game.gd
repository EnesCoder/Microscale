extends Node2D

var cell_group = []
var dead_cell_particles = preload("res://dead_cell_particles.tscn")
var create_dc_particles = false
var dc_particles_pos : Vector2
var dcp : GPUParticles2D

func _ready():
	dcp = dead_cell_particles.instantiate()
	dcp.emitting = false
	add_child(dcp)
	
func _process(_delta):
	for c in cell_group:
		print(cell_group.size())
		if c != null and c.fragility <= 0:
			dc_particles_pos = c.global_position
			create_dc_particles = true
			c.remove_from_group("Player_cells")
			c.queue_free()
	
	if create_dc_particles:
		dcp.global_position = dc_particles_pos
		dcp.emitting = true
		dcp.one_shot = true
		await get_tree().create_timer(1.0).timeout
		dcp.emitting = false
		create_dc_particles = false

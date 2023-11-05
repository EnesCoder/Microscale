extends Camera2D

func interpolate_zoom(delta):
	var initial_zoom = zoom
	var zoomed_in = false
	while not zoomed_in:
		zoom += Vector2(2, 2) * delta
		if zoom.x > 2:
			zoomed_in = true
		await get_tree().create_timer(delta).timeout
	await get_tree().create_timer(1.0).timeout
	while zoomed_in:
		zoom -= Vector2(2, 2) * delta
		if zoom.x < initial_zoom.x:
			zoom = initial_zoom
			zoomed_in = false
		await get_tree().create_timer(delta).timeout

func _ready():
	pass

func _process(delta):
	pass

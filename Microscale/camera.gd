extends Camera2D

@export var split_zoom_threshold = 2

func interpolate_zoom(delta, where_to_zoom):
	var initial_pos = global_position
	var zoomed_in = false
	var dist = where_to_zoom - initial_pos
	print(global_position)
	print(where_to_zoom)
	while not zoomed_in:
		global_position = lerp(global_position, where_to_zoom, delta*(dist.length()/200))
		#zoom += Vector2(380/dist.length(), 380/dist.length()) * delta
		#if zoom.x > split_zoom_threshold:
		#	zoomed_in = true
		if where_to_zoom - global_position < Vector2.ONE*2:
			zoomed_in = true
		await get_tree().create_timer(delta).timeout
	await get_tree().create_timer(1.0).timeout
	while zoomed_in:
		global_position = lerp(global_position, initial_pos, delta*(dist.length()/200))
		#zoom -= Vector2(2, 2) * delta
		#if zoom.x < initial_zoom.x:
		#	zoom = initial_zoom
		if global_position == initial_pos:
			zoomed_in = false
		await get_tree().create_timer(delta).timeout
	print(global_position)

func _ready():
	pass

func _process(_delta):
	pass

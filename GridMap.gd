extends GridMap

# Algorithm variables
var map_cells: Array = []
var start_cell: Vector3i = Vector3i.UP
var goal_cell: Vector3i = Vector3i.UP
var path: Dictionary = {}

enum unique {start = 1, goal = 2}
enum placeable {space = 0, searched = 3}
enum block {cliff = 4}

# Drag and drop variables
var selected_cell: Vector3i
var selected_cell_type: int

@onready var ray_cast_3d: RayCast3D = $"../Camera3D/RayCast3D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get map cells
	map_cells = get_used_cells()
		
	# Set start_tile and goal tile
	for cell in map_cells:
		if cell.x < start_cell.x or cell.z < start_cell.z:
			start_cell = cell
		elif cell.x > goal_cell.x or cell.z > goal_cell.z:
			goal_cell = cell
	
	set_cell_item(start_cell, 1)
	set_cell_item(goal_cell, 2)
		
	# Label tile locations
	label_map()
	
	# Set frontier and calculate path
	calculate_path([start_cell])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Project mouse position in 3d space
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	ray_cast_3d.target_position = ray_cast_3d.get_parent().project_local_ray_normal(mouse_position) * 1000
	ray_cast_3d.force_raycast_update()
	
	# Check if ray collides
	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		
		# Check if ray is colliding with gridmap
		if collider is GridMap:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			
			# When dragging a start or goal tile:
			# is_action_just_pressed will only check once if the button is pressed
			# Use it to get the type and location of either the start or goal tile
			if Input.is_action_just_pressed("left_click"):
				selected_cell = local_to_map(ray_cast_3d.get_collision_point())
				selected_cell_type = get_cell_item(selected_cell)
			
			# is_action_pressed will check as long as the button is held down
			# Use it 'drag' the selected_cell around
			if Input.is_action_pressed("left_click"):
				var cur_cell: Vector3i = local_to_map(ray_cast_3d.get_collision_point())
				if get_cell_item(cur_cell) in placeable.values():
					if selected_cell_type in unique.values():
							# Change cell position
							set_cell_item(cur_cell, selected_cell_type)
							set_cell_item(selected_cell, placeable.space)
							selected_cell = cur_cell
							
							# Reset map and re-calculate path
							if selected_cell_type == unique.start : 
								start_cell = selected_cell
								calculate_path([selected_cell])
							if selected_cell_type == unique.goal : 
								goal_cell = selected_cell
								calculate_path([start_cell])
								
					elif selected_cell_type in placeable.values():
						set_cell_item(cur_cell, block.cliff)
			
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
func calculate_path(frontier):
	reset_map()
	while not frontier.is_empty():
		var cell : Vector3i = frontier.pop_front()
		
		if cell == goal_cell:
			frontier = []
			break
		
		for neighbour in find_graph_neighbours(cell):
			if neighbour not in path:
				frontier.append(neighbour)
				path[neighbour] = cell
				if get_cell_item(neighbour) == placeable.space:
					set_cell_item(neighbour, placeable.searched)

func find_graph_neighbours(cell) -> Array:
	var graph_neighbours: Array = []
	for direction in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
		var neighbour: Vector3i = direction + cell
		
		if neighbour in map_cells and get_cell_item(neighbour) != block.cliff:
			graph_neighbours.append(neighbour)
			
	return graph_neighbours

# Reset the map tiles to type 0 and path to empty
func reset_map() -> void:
	path = {}
	for cell in map_cells:
		if get_cell_item(cell) in placeable.values():
			set_cell_item(cell, 0)

# Label every tile in the map
func label_map() -> void:
	for cell in map_cells:
		var new_label = Label3D.new()
		new_label.font_size = 48
		new_label.pixel_size = 0.008
		new_label.position = map_to_local(cell)
		new_label.position.y = 0.051
		new_label.rotation_degrees.x = -90
		new_label.text = str(cell)
		add_child(new_label)

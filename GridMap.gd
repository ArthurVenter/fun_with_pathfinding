extends GridMap

# Algorithm variables
var map_cells: Array = []
var start_cell: Vector3i = Vector3i.UP
var goal_cell: Vector3i = Vector3i.UP
var came_from: Dictionary = {}

# Cell types and their corresponding gridmap values
enum unique {start = 1, goal = 2}
enum placeable {space = 0 }
enum block {cliff = 4}
enum highlight {searched = 3, path = 5}

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
				if get_cell_item(cur_cell) in placeable.values() or get_cell_item(cur_cell) in highlight.values():
					# If the initial cell is 'unique'
					if selected_cell_type in unique.values():
						# Change cell position
						set_cell_item(cur_cell, selected_cell_type)
						set_cell_item(selected_cell, placeable.space)
						selected_cell = cur_cell
						
						# Change start and goal cell values to reflect their new positions
						if selected_cell_type == unique.start : 
							start_cell = selected_cell
						if selected_cell_type == unique.goal : 
							goal_cell = selected_cell
							
					# If the initial cell isn't 'unique' or 'impassible terrain'
					elif selected_cell_type in placeable.values() or selected_cell_type in highlight.values():
						# Set cell to 'impassible terrain'
						set_cell_item(cur_cell, block.cliff)
						
				# Update path with new changes
				calculate_path([start_cell])
				
			if Input.is_action_pressed("right_click"):
				# Revert cell if it is impassible terrain
				var cur_cell: Vector3i = local_to_map(ray_cast_3d.get_collision_point())
				if get_cell_item(cur_cell) == block.cliff:
					set_cell_item(cur_cell, placeable.space)
					
				# Update path with new changes
				calculate_path([start_cell])
					
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
func calculate_path(frontier):
	# Reset map before calculating a path 
	# This is mostly so that the visuals will display correctly
	reset_map()
	
	# While there is still cells to search (frontier)
	while not frontier.is_empty():
		var cell : Vector3i = frontier.pop_front()
		
		# Break if we reached the goal cell
		if cell == goal_cell:
			frontier = []
			break
		
		# Search surrounding cells and calculate its closeness to the goal cell
		var priority_cell: Dictionary = {}
		for neighbour in find_graph_neighbours(cell):
			if neighbour not in came_from:
				priority_cell[heuristic(goal_cell, neighbour)] = neighbour
				came_from[neighbour] = cell
				if get_cell_item(neighbour) == placeable.space:
					set_cell_item(neighbour, highlight.searched)
		
		# Return when there is no possible path
		if priority_cell.is_empty():
			return
			
		# Add next closest cell to frontier
		frontier.append(priority_cell[priority_cell.keys().min()])
		
	# Draw path
	show_path()

# Return list of surrounding 'neighbour' cells
# Ignores special cells like start, goal and impassible terrain
func find_graph_neighbours(cell) -> Array:
	var graph_neighbours: Array = []
	for direction in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
		var neighbour: Vector3i = direction + cell
		
		if neighbour in map_cells and get_cell_item(neighbour) != block.cliff:
			graph_neighbours.append(neighbour)
			
	return graph_neighbours
	
# Heuristic for calculating the closeness of a cell to the goal cell
func heuristic(a: Vector3i, b: Vector3i) -> int:
	# Manhattan distance on a square grid
	return abs(a.x - b.x) + abs(a.z - b.z)

func show_path() -> void:
	var path: Array = []
	var cur_cell: Vector3i = goal_cell
	
	# Calculate the path by retracing steps from the goal cell
	while cur_cell != start_cell:
		path.append(cur_cell)
		cur_cell = came_from[cur_cell]
		
		# Highlight path cells
		if cur_cell != start_cell:
			set_cell_item(cur_cell, highlight.path)
	
	# Re-arrange path variable to go from start cell to goal cell
	path.append(start_cell)
	path.reverse()		
	
# Reset the map tiles to type 0 and path to empty
func reset_map() -> void:
	came_from = {}
	for cell in map_cells:
		if get_cell_item(cell) in highlight.values():
			set_cell_item(cell, placeable.space)

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

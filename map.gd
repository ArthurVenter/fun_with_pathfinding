extends Node3D
#
#@export var player: Camera3D
#@export var gridmap: GridMap
#
#var map_tiles: Array = []
#var path: Dictionary = {}
#
## Instantiate start and goal cell information
#var start_cell: Vector3i = Vector3i.MAX:
	#set(value):
		#start_cell = value
		#frontier = [value]
	#get:
		#return start_cell
#var goal_cell: Vector3i = Vector3i.MAX:
	#set(value):
		#goal_cell = value
	#get: 
		#return goal_cell
#
#var frontier: Array = []
#
#func _ready() -> void:
	#map_tiles = gridmap.get_used_cells()
#
#func _process(delta: float) -> void:
	#while not frontier.is_empty() and goal_cell != Vector3i.MAX:
		#var cell : Vector3i = frontier.pop_front()
		#
		#if cell == goal_cell:
			#frontier = []
			#break
		#
		#for neighbour in find_graph_neighbours(cell):
			#if neighbour not in path:
				#frontier.append(neighbour)
				#path[neighbour] = cell
				#if gridmap.get_cell_item(neighbour) == 0:
					#gridmap.set_cell_item(neighbour, 3)
		#
#
#func find_graph_neighbours(cell) -> Array:
	#var graph_neighbours: Array = []
	#for direction in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
		#var neighbour: Vector3i = direction + cell
		#if neighbour in map_tiles:
			#graph_neighbours.append(neighbour)
	#return graph_neighbours

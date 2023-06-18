@tool
extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh_data = []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(
		[
			Vector3(0,0,0),
			Vector3(0,0,0.5),
			Vector3(sqrt(3)/4,0,0.25),
			Vector3(sqrt(3)/4,0,-0.25),
			Vector3(0,0,-0.5),
			Vector3(-sqrt(3)/4,0,-0.25),
			Vector3(-sqrt(3)/4,0,0.25),
		]
	)
	
	mesh_data[ArrayMesh.ARRAY_INDEX] = PackedInt32Array(
		[
			0,1,2, # top right
			
			0,2,3, # center right
			
			0,3,4, # bottom right
			
			0,4,5, # bottom left
			
			0,5,6, # center left
			
			0,6,1, # top left
		]
	)
	
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)

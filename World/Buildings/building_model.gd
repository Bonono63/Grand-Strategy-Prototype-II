extends MeshInstance3D

func init(model : String):
	print(model)
	mesh = load(model)

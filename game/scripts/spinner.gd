extends Node3D
## Rotates continuously around a local axis (wind turbine rotors, etc.).

var speed := 1.0
var axis := Vector3.FORWARD


func _process(delta: float) -> void:
	rotate_object_local(axis, speed * delta)

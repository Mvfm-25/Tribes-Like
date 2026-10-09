extends Node3D

@export var tempo_de_vida: float = 8.0 # segundos até os pedaços sumirem

func _ready() -> void:
	await get_tree().create_timer(tempo_de_vida).timeout
	queue_free()

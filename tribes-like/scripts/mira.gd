extends Control

@export var raio: float = 6.0
@export var espessura: float = 2.0
@export var cor: Color = Color.WHITE

func _draw() -> void:
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 32, cor, espessura, true)

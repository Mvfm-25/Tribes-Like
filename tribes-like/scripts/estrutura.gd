extends StaticBody3D

@export var hp: float = 5.0
@export var destrocos: PackedScene # cena que substitui a estrutura ao ser destruída
@export var forca_explosao: float = 6.0 # impulso em cada pedaço, para fora do centro

func recebe_dano(dano: float) -> void:
	if hp <= 0.0:
		return
	hp -= dano
	print("Estrutura recebendo dano. HP : ", hp)
	if hp <= 0.0:
		_desmorona()

func _desmorona() -> void:
	print("Estrutura destruída!")
	if destrocos:
		var restos: Node3D = destrocos.instantiate()
		restos.transform = transform
		get_parent().add_child(restos)
		for pedaco in restos.get_children():
			if pedaco is RigidBody3D:
				var para_fora: Vector3 = (pedaco.global_position - global_position).normalized()
				pedaco.apply_central_impulse(para_fora * forca_explosao * pedaco.mass)
	queue_free()

extends Area3D

# A força com que o jogador será lançado para cima
@export var launch_force: float = 15.0

func _on_body_entered(body: Node3D) -> void:
	# Verifica se o corpo que entrou é o jogador (CharacterBody3D)
	if body is CharacterBody3D:
		# Altera diretamente a velocidade vertical do personagem
		body.velocity.y = launch_force

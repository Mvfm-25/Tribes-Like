extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var HP = 10.0

func recebe_dano(dano: float) -> void :
	if HP <= 0 :
		return
	HP -= dano 
	print("Recebendo dano. HP : ", HP)
	if HP <= 0:
		print("Bixo morto!")
		queue_free()

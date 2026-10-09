extends CharacterBody3D

@export var speed: float = 20.0
@export var jump_speed: float = 10.0
@export var gravity: float = 10.0

func _physics_process(delta: float) -> void:
	var input := Input.get_vector(
		"strafe_e", "strafe_d", "anda_f", "anda_t"
	)
	velocity.x = input.x * speed
	velocity.z = input.y * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("pula"):
		velocity.y = jump_speed
	else:
		velocity.y = 0.0

	move_and_slide()

	if global_position.y < -10.0:
		global_position = Vector3(0.0, 2.0, 0.0)
		velocity = Vector3.ZERO
		
func _ready() -> void:
	$CameraJogador.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("troca_camera"):
		_troca_camera()

func _troca_camera() -> void:
	if $CameraJogador.current:
		$"../Camera Ambiente".current = true
	else:
		$CameraJogador.current = true

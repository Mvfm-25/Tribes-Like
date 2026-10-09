extends CharacterBody3D

@export var speed: float = 20.0
@export var jump_speed: float = 10.0
@export var gravity: float = 10.0

@export var air_accel: float = 60.0 # m/s²
@export var air_wish_speed: float = 2.0 # limite da projeção da velocidade no input
@export var vel_max_ar: float = 50.0

@export var sensibilidade: float = 0.003 # rad por pixel
@export var pitch_min: float = deg_to_rad(-70.0)
@export var pitch_max: float = deg_to_rad(40.0)

@onready var braco: SpringArm3D = $"Pivô/ControlaColisãoCamera"

func _physics_process(delta: float) -> void:
	var input := Input.get_vector(
		"strafe_e", "strafe_d", "anda_f", "anda_t"
	)
	var direcao := _direcao_pela_camera(input)

	if not is_on_floor():
		velocity.y -= gravity * delta
		_acelera_no_ar(direcao, delta)
	else:
		velocity.x = direcao.x * speed
		velocity.z = direcao.z * speed
		if Input.is_action_just_pressed("pula"):
			velocity.y = jump_speed
		elif velocity.y < 0.0 :
			velocity.y = 0.0

	move_and_slide()

	if global_position.y < -10.0:
		global_position = Vector3(0.0, 2.0, 0.0)
		velocity = Vector3.ZERO

# Direção desejada no plano horizontal, ancorada no yaw da câmera (ignora o pitch).
func _direcao_pela_camera(input: Vector2) -> Vector3:
	var direita: Vector3 = %CameraJogador.global_basis.x
	direita.y = 0.0
	direita = direita.normalized()
	var frente := Vector3.UP.cross(direita)
	return direita * input.x - frente * input.y

# Só acelera até 'air_wish_speed' na direção do input: strafe perpendicular
# curva a trajetória sem tirar velocidade.
func _acelera_no_ar(direcao: Vector3, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var vel_antes := horizontal.length()
	var vel_na_direcao := horizontal.dot(direcao)
	var ganho := clampf(air_wish_speed - vel_na_direcao, 0.0, air_accel * delta)
	horizontal += direcao * ganho
	# O strafe não passa de 'vel_max_ar', mas não freia quem já chegou mais rápido.
	horizontal = horizontal.limit_length(maxf(vel_max_ar, vel_antes))
	velocity.x = horizontal.x
	velocity.z = horizontal.z

func _ready() -> void:
	%CameraJogador.current = true
	braco.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#M Movimento Mouse
var mouse_input : Vector2

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("troca_camera"):
		_troca_camera()
	elif event is InputEventMouseMotion :
		var viewport_transform: Transform2D = get_tree().root.get_final_transform()
		mouse_input += event.xformed_by(viewport_transform).relative

func _troca_camera() -> void:
	if %CameraJogador.current:
		$"../Camera Ambiente".current = true
	else:
		%CameraJogador.current = true

func _process(_delta) -> void :
	rotate_y(-mouse_input.x * sensibilidade)
	braco.rotation.x = clampf(
		braco.rotation.x - mouse_input.y * sensibilidade, pitch_min, pitch_max
	)
	mouse_input = Vector2.ZERO

	%Velocimetro.text = "X: %.1f\nY: %.1f\nZ: %.1f\nHorizontal: %.1f m/s" % [
		velocity.x, velocity.y, velocity.z, Vector2(velocity.x, velocity.z).length()
	]

func _on_launch_pad_body_entered(body: Node3D) -> void:
	pass # Replace with function body.

extends CharacterBody3D

@export var speed: float = 30.0
@export var jump_speed: float = 20.0
@export var gravity: float = 10.0

@export var air_accel: float = 50.0 # m/s²
@export var air_wish_speed: float = 2.0 # limite da projeção da velocidade no input
@export var vel_max_ar: float = 50.0

@export var atrito_esqui: float = 0.2 # m/s² perdidos ao deslizar
@export var freio_chao: float = 20.0 # m/s² com que o chão leva a velocidade até o input

@export var sensibilidade: float = 0.003 # rad por pixel
@export var pitch_min: float = deg_to_rad(-70.0)
@export var pitch_max: float = deg_to_rad(40.0)

@export var alcance_tiro: float = 1000.0 # pew pew
@export var dano_tiro: float = 2.0

@onready var braco: SpringArm3D = $"Pivô/ControlaColisãoCamera"

var esquiando: bool = false
var vel_y_pouso: float = 0.0 # velocidade vertical no instante em que tocou o chão

func _atira() -> void :
	var camera : Camera3D = %CameraJogador
	var origem := camera.global_position
	var destino := origem - camera.global_basis.z * alcance_tiro
	
	var query := PhysicsRayQueryParameters3D.create(origem, destino)
	query.exclude = [get_rid()]
	
	print("Atirando!")
	var acerto := get_world_3d().direct_space_state.intersect_ray(query)
	if acerto and acerto.collider.has_method("recebe_dano"):
		acerto.collider.recebe_dano(dano_tiro)
		print("Acerto!")
	else :
		print("Errou!")

func _physics_process(delta: float) -> void:
	var input := Input.get_vector(
		"strafe_e", "strafe_d", "anda_f", "anda_t"
	)
	var direcao := _direcao_pela_camera(input)

	var no_chao := is_on_floor()
	# Segurar o pulo desliza; o toque inicial ainda é um pulo normal.
	esquiando = (
		no_chao
		and Input.is_action_pressed("pula")
		and not Input.is_action_just_pressed("pula")
	)

	if not no_chao:
		velocity.y -= gravity * delta
		_acelera_no_ar(direcao, delta)
	elif esquiando:
		_esquia(direcao, delta)
	else:
		var horizontal := Vector3(velocity.x, 0.0, velocity.z)
		# O chão aproxima a velocidade do input aos poucos, tanto freando quanto acelerando.
		horizontal = horizontal.move_toward(direcao * speed, freio_chao * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.z
		if Input.is_action_just_pressed("pula"):
			velocity.y = jump_speed
		elif velocity.y < 0.0 :
			velocity.y = 0.0
	
	if Input.is_action_just_pressed("atira"):
		_atira()

	var vel_y_antes := velocity.y
	move_and_slide()
	# O move_and_slide zera a queda ao pousar; guarda para o esqui aproveitar.
	vel_y_pouso = vel_y_antes if is_on_floor() and not no_chao else 0.0

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

# Desliza sem atrito de chão: a gravidade acelera ladeira abaixo e freia ladeira
# acima, e a queda vira velocidade ao pousar numa descida.
func _esquia(direcao: Vector3, delta: float) -> void:
	var normal := get_floor_normal()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if vel_y_pouso < 0.0:
		horizontal = Vector3(velocity.x, vel_y_pouso, velocity.z).slide(normal)
		horizontal.y = 0.0

	# Parte horizontal da gravidade projetada no plano do chão.
	horizontal += Vector3(normal.x, 0.0, normal.z) * normal.y * gravity * delta
	horizontal = horizontal.move_toward(Vector3.ZERO, atrito_esqui * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	_acelera_no_ar(direcao, delta)

	# Vertical que deixa a velocidade tangente ao chão; a gravidade do frame
	# empurra contra ele para o contato não se perder nas subidas.
	velocity.y = -(normal.x * velocity.x + normal.z * velocity.z) / normal.y
	velocity.y -= gravity * delta

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
	%Mira.visible = %CameraJogador.current

func _process(_delta) -> void :
	rotate_y(-mouse_input.x * sensibilidade)
	braco.rotation.x = clampf(
		braco.rotation.x - mouse_input.y * sensibilidade, pitch_min, pitch_max
	)
	mouse_input = Vector2.ZERO

	%Velocimetro.text = "X: %.1f\nY: %.1f\nZ: %.1f\nHorizontal: %.1f m/s%s" % [
		velocity.x, velocity.y, velocity.z, Vector2(velocity.x, velocity.z).length(),
		" [ESQUI]" if esquiando else ""
	]

func _on_launch_pad_body_entered(body: Node3D) -> void:
	pass # Replace with function body.

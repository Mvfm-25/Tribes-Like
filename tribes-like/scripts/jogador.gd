extends CharacterBody3D

@export var speed: float = 20.0
@export var jump_speed: float = 10.0
@export var gravity: float = 10.0

@export var sensibilidade: float = 0.003 # rad por pixel
@export var pitch_min: float = deg_to_rad(-70.0)
@export var pitch_max: float = deg_to_rad(40.0)

@onready var braco: SpringArm3D = $"Pivô/ControlaColisãoCamera"

func _physics_process(delta: float) -> void:
	var input := Input.get_vector(
		"strafe_e", "strafe_d", "anda_f", "anda_t"
	)
	var direcao := transform.basis * Vector3(input.x, 0.0, input.y)
	velocity.x = direcao.x * speed
	velocity.z = direcao.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
		velocity.x += delta * speed
	elif Input.is_action_just_pressed("pula"):
		velocity.y = jump_speed
	elif velocity.y < 0.0 :
		velocity.y = 0.0

	move_and_slide()

	if global_position.y < -10.0:
		global_position = Vector3(0.0, 2.0, 0.0)
		velocity = Vector3.ZERO

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

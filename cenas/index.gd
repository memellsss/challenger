extends Sprite2D


# Called when the node enters the scene tree for the first time.

@onready var _animation_player = $AnimationPlayer
func _ready():
	_animation_player.play("walk")

@onready var anim = $AnimationPlayer

enum State {
idle,
	jump,
	attack_sword,
	strong_attack_sword,
	bow_attack,
	strong_bow_attack,
	hit,
	die
}

var current_state: State = State.idle

func _physics_process(_idle):
	if current_state == State.die:
		return



var move_speed := 200.0
var velocity: Vector2 = Vector2.ZERO

func _process(delta):
	if Input.is_action_pressed("ui_right"):
		_animation_player.play("walk")
	else:
		_animation_player.stop()

	handle_movement(delta)

func handle_movement(delta):
	if is_busy():
		velocity = Vector2.ZERO
	else:
		var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = dir * move_speed

	position += velocity * delta


func handle_input():
	if is_busy():  # impede ações durante animações críticas
		return

	if Input.is_action_just_pressed("jump"):
		pular()
	elif Input.is_action_just_pressed("attack_sword"):
		ataque_espada()
	elif Input.is_action_just_pressed("strong_attack_sword"):
		ataque_espada_carregado()
	elif Input.is_action_just_pressed("bow_attack"):
		atirar_bow_attack()
	elif Input.is_action_just_pressed("strong_bow_attack"):
		atirar_strong_bow_attack()
	elif Input.is_action_just_pressed("hit"):
		tomar_hit()
	elif Input.is_action_just_pressed("die"):
		morrer()

func is_busy() -> bool:
	return current_state in [State.attack_sword, State.strong_attack_sword, State.bow_attack, State.strong_bow_attack, State.hit, State.die]

# ==== AÇÕES ====

func pular():
	current_state = State.jump
	anim.play("pular")

func ataque_espada():
	current_state = State.attack_sword
	anim.play("espada")
	await anim.animation_finished
	current_state = State.idle

func ataque_espada_carregado():
	current_state = State.strong_attack_sword
	anim.play("espada_carregado")
	await anim.animation_finished
	current_state = State.idle

func atirar_bow_attack():
	current_state = State.bow_attack
	anim.play("bow_attack")
	await anim.animation_finished
	current_state = State.idle

func atirar_strong_bow_attack():
	current_state = State.strong_bow_attack
	anim.play("strong_bow_attack")
	await anim.animation_finished
	current_state = State.idle

func tomar_hit():
	current_state = State.hit
	anim.play("hit")
	await anim.animation_finished
	current_state = State.idle

func morrer():
	current_state = State.die
	anim.play("die")

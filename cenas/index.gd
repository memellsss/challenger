extends Sprite2D

# Nodes
@onready var animation_player = $AnimationPlayer
@onready var camera = $Camera2D

# Enumerador para estados
enum State {
	IDLE,
	WALK,
	JUMP,
	ATTACK,
	HIT,
	DIE
}

var current_state: State = State.IDLE

# Variáveis de movimento
var speed := 200
var velocity := Vector2.ZERO

func _ready():
	animation_player.play("idle")

func _physics_process(delta):
	if current_state == State.DIE:
		return

	handle_input()
	handle_movement(delta)

func handle_input():
	if is_busy():
		return

	if Input.is_action_just_pressed("ui_accept"):
		attack("sword_attack")
	elif Input.is_action_just_pressed("ui_up"):
		jump()
	elif Input.is_action_just_pressed("attack_z"):
		attack("strong_sword_attack")
	elif Input.is_action_just_pressed("attack_x"):
		attack("bow_attack")
	elif Input.is_action_just_pressed("attack_c"):
		attack("strong_bow_attack")

func handle_movement(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	
	if direction != Vector2.ZERO:
		if current_state == State.IDLE:
			current_state = State.WALK
			animation_player.play("walk")
	else:
		if current_state == State.WALK:
			current_state = State.IDLE
			animation_player.play("idle")

	position += velocity * delta

func is_busy() -> bool:
	return current_state in [State.ATTACK, State.JUMP, State.HIT, State.DIE]

# === Ações ===

func attack(anim_name):
	current_state = State.ATTACK
	animation_player.play(anim_name)
	await animation_player.animation_finished
	current_state = State.IDLE
	animation_player.play("idle")

func jump():
	current_state = State.JUMP
	animation_player.play("jump")
	await animation_player.animation_finished
	current_state = State.IDLE
	animation_player.play("idle")

func hit():
	current_state = State.HIT
	animation_player.play("hit")
	await animation_player.animation_finished
	current_state = State.IDLE
	animation_player.play("idle")

func die():
	current_state = State.DIE
	animation_player.play("die")
	await animation_player.animation_finished
	queue_free()

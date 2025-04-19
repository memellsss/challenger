extends CharacterBody2D

@export var speed = 120
@export var attack_range = 50
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation = $AnimationPlayer
@onready var attack_area = $DetectionArea
@onready var health_bar = $EnemyHealth


enum State { IDLE, WALK, ATTACK, HIT, DIE }
var current_state = State.IDLE
var last_attack_was_alternate = false
var attack_cooldown = false
var health = 100
var player = null

func _ready():
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	player = get_tree().get_first_node_in_group("player")
	health_bar.max_value = health
	health_bar.value = health
	_update_healthbar_color()
	health_bar.show_percentage = false

func _physics_process(delta):
	if current_state not in [State.ATTACK, State.HIT, State.DIE]:
		if player:
			chase_and_attack(delta)
	update_animation()

func chase_and_attack(delta):
	var distance_to_player = position.distance_to(player.position)
	var direction = (player.position - position).normalized()

	if distance_to_player > attack_range:
		velocity.x = direction.x * speed
		current_state = State.WALK
	else:
		velocity.x = 0
		current_state = State.IDLE
		if not attack_cooldown:
			attack()

	if velocity.x > 0:
		$Orc.flip_h = false
	elif velocity.x < 0:
		$Orc.flip_h = true

	velocity.y += gravity * delta

	move_and_slide()

func update_animation():
	match current_state:
		State.WALK:
			if animation.current_animation != "walk":
				animation.play("walk")
		State.IDLE:
			if animation.current_animation != "idle":
				animation.play("idle")
		State.ATTACK:
			if animation.current_animation not in ["attack", "strong_attack"]:
				var attack_anim = "attack" if last_attack_was_alternate else "strong_attack"
				animation.play(attack_anim)
		State.HIT:
			if animation.current_animation != "hit":
				animation.play("hit")
		State.DIE:
			if animation.current_animation != "die":
				animation.play("die")

func attack():
	attack_cooldown = true
	current_state = State.ATTACK
	attack_area.monitoring = true
	var attack_anim = "strong_attack" if last_attack_was_alternate else "attack"
	last_attack_was_alternate = !last_attack_was_alternate
	animation.play(attack_anim)
	await animation.animation_finished

	attack_area.monitoring = false
	current_state = State.IDLE

	await get_tree().create_timer(1.5).timeout
	attack_cooldown = false

func _on_attack_area_body_entered(body):
	if body.has_method("take_damage") and body.is_in_group("player"):
		body.take_damage(10)
		print("Player tomou dano do Orc!", "Corpo:", body)

func take_damage(amount):
	if current_state == State.DIE:
		return

	health -= amount
	health = clamp(health, 0, health_bar.max_value)
	health_bar.value = health
	_update_healthbar_color()
	print("Orc recebeu dano:", amount, "Saúde atual:", health)

	if health <= 0:
		die()
	else:
		current_state = State.HIT
		animation.play("hit")
		await animation.animation_finished
		current_state = State.IDLE

func die():
	current_state = State.DIE
	animation.play("die")
	await animation.animation_finished
	queue_free()

func _update_healthbar_color():
	var percent = float(health) / health_bar.max_value
	var fill_stylebox = health_bar.get_theme_stylebox("fill").duplicate()

	if percent == 1.0:
		fill_stylebox.bg_color = Color("ffff00")
	elif percent > 0.33:
		fill_stylebox.bg_color = Color("ffff00")
	else:
		fill_stylebox.bg_color = Color("ff0000")

	health_bar.add_theme_stylebox_override("fill", fill_stylebox)

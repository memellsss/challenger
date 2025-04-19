extends CharacterBody2D

class_name Player

signal player_damaged
signal player_defeated

var health: int = 100
@export var jump_velocity: float = -200
@export var climb_speed: float = 60.0
@onready var health_bar = $Health
@onready var attack_area = $attack_area # Já declarado como @onready
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var _can_attack: bool = true
var _is_attacking: bool = false
var _attack_animation_name: String = ""
var _is_dead: bool = false
var _current_attack_damage: int = 0 # Declarando _current_attack_damage
var _hit_bodies: Array[int] # Adicionado para controlar corpos atingidos

@export_category("Variables")
@export var _move_speed: float = 128.0
@export var attack_damage: int = 15
@export var strong_attack_damage: int = 35
@export var _left_attack_name: StringName = "sword"
@export var _right_attack_name: StringName = "strong_attack"
@export var _hit_animation_name: StringName = "hit"
@export var _die_animation_name: StringName = "die"
@export_category("objects")
@export var _sprite2D: Sprite2D
@export var _animation: AnimationPlayer

func _ready():
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited) # Conecta o sinal body_exited

func _physics_process(_delta: float) -> void:
	if _is_dead:
		return

	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		if not _is_attacking:
			_animation.play("jump")

	_move(_delta)
	_animate()
	_attack_input()

	move_and_slide()

func _move(_delta: float) -> void:
	var _direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	velocity = _direction * _move_speed

	move_and_slide()

func _attack_input() -> void:
	if Input.is_action_just_pressed("left_attack") and _can_attack and not _is_attacking:
		_start_attack(_left_attack_name, attack_damage)
	elif Input.is_action_just_pressed("right_attack") and _can_attack and not _is_attacking:
		_start_attack(_right_attack_name, strong_attack_damage)

func _start_attack(anim_name: String, damage_amount: int) -> void:
	_can_attack = false
	_is_attacking = true
	_attack_animation_name = anim_name
	_animation.play(_attack_animation_name)
	attack_area.monitoring = true
	_current_attack_damage = damage_amount
	_hit_bodies.clear() # Limpa a lista de corpos atingidos no início do ataque
	set_physics_process(false)
	print("Player atacou! Dano:", _current_attack_damage, "Monitoring da attack_area:", attack_area.monitoring)

func _on_attack_area_body_entered(body):
	if body.has_method("take_damage") and body.is_in_group("enemy") and _hit_bodies.find(body.get_instance_id()) == -1:
		print("Corpo entrou na attack_area do Player:", body)
		print("Corpo tem take_damage e é inimigo. Dano aplicado:", _current_attack_damage)
		body.take_damage(_current_attack_damage)
		_hit_bodies.append(body.get_instance_id()) # Adiciona o ID do corpo atingido à lista

func _on_attack_area_body_exited(body):
	if _hit_bodies.has(body.get_instance_id()):
		_hit_bodies.erase(body.get_instance_id()) # Remove o ID do corpo quando ele sai da área

func _animate() -> void:
	if _is_attacking:
		return

	if abs(velocity.x) > 0.1:
		_animation.play("walk")
	elif abs(velocity.y) > 0.1:
		if velocity.y < 0 and _animation.current_animation != "jump":
			_animation.play("jump")
		elif velocity.y > 0 and _animation.current_animation != _hit_animation_name and _animation.current_animation != "jump":
			_animation.play("hit")
		elif velocity.y > 0 and _animation.current_animation == "jump":
			_animation.play("fall")

	else:
		_animation.play("idle")

	if velocity.x > 0:
		_sprite2D.flip_h = false
	elif velocity.x < 0:
		_sprite2D.flip_h = true

func take_damage(damage: int) -> void:
	if _is_dead:
		return
	health -= damage
	health = clamp(health, 0, 100)
	emit_signal("player_damaged")
	if is_instance_valid(health_bar):
		health_bar.value = health
	if health <= 0:
		emit_signal("player_defeated")
		queue_free()
	if health <= 0:
		_is_dead = true
		emit_signal("player_defeated")
		_animation.play(_die_animation_name)
		set_physics_process(false)
	update_health_color()

func get_attack_damage() -> int:
	return attack_damage

func get_strong_attack_damage() -> int:
	return strong_attack_damage

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == _left_attack_name or anim_name == _right_attack_name:
		_is_attacking = false
		_can_attack = true
		attack_area.monitoring = false
		set_physics_process(true)
		if abs(velocity.y) > 0.1:
			if velocity.y < 0:
				_animation.play("jump")
			else:
				_animation.play("fall")
		elif abs(velocity.x) > 0.1:
			_animation.play("walk")
		else:
			_animation.play("idle")
	elif anim_name == "jump":
		if abs(velocity.y) > 0.1 and velocity.y > 0:
			_animation.play("fall")
		elif abs(velocity.x) > 0.1:
			_animation.play("walk")
		else:
			_animation.play("idle")
	elif anim_name == _hit_animation_name:
		if abs(velocity.y) > 0.1:
			if velocity.y < 0:
				_animation.play("jump")
			else:
				_animation.play("fall")
		elif abs(velocity.x) > 0.1:
			_animation.play("walk")
		else:
			_animation.play("idle")
	elif anim_name == _die_animation_name:
		pass

func update_health_color():
	if is_instance_valid(health_bar):
		var percent = float(health) / 100.0
		var fill_stylebox = health_bar.get_theme_stylebox("fill").duplicate()

		if percent == 1.0:
			fill_stylebox.bg_color = Color("ffff00")
		elif percent > 0.33:
			fill_stylebox.bg_color = Color("ffff00")
		else:
			fill_stylebox.bg_color = Color("ff0000")

		health_bar.add_theme_stylebox_override("fill", fill_stylebox)

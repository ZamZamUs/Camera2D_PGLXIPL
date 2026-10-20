extends CharacterBody2D

# ─── Konstanta Gerak ───────────────────────────────────────────────────────────
const SPEED         = 180.0
const JUMP_VELOCITY = -420.0
const ACCEL         = 900.0   # Akselerasi saat bergerak
const FRICTION      = 1200.0  # Deselerasi saat berhenti

# ─── Variabel Skor ─────────────────────────────────────────────────────────────
var poin: int = 0

# ─── Node Reference ────────────────────────────────────────────────────────────
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

# ─── Batas Peta (diatur otomatis oleh kamera) ──────────────────────────────────
var _map_rect: Rect2 = Rect2(0, 0, 4000, 1000)

func _ready() -> void:
	# Bergabung ke group agar tomato.gd bisa mendeteksi
	add_to_group("player")
	_setup_camera()
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").on_player_ready(self)

func _setup_camera() -> void:
	# Limit kamera sesuai ukuran peta
	camera.limit_left   = int(_map_rect.position.x)
	camera.limit_top    = int(_map_rect.position.y)
	camera.limit_right  = int(_map_rect.end.x)
	camera.limit_bottom = int(_map_rect.end.y)

func _physics_process(delta: float) -> void:
	# ── Gravitasi ───────────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity += get_gravity() * delta

	# ── Lompat ──────────────────────────────────────────────────────────────────
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# ── Gerak Horizontal ────────────────────────────────────────────────────────
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: float) -> void:
	# Arah sprite mengikuti arah gerak
	if direction > 0.0:
		animated_sprite.flip_h = false
	elif direction < 0.0:
		animated_sprite.flip_h = true

	# Prioritas animasi: jump → run → idle
	if not is_on_floor():
		animated_sprite.play("jump")
	elif direction != 0.0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")


# Dipanggil dari luar (mis. tomato.gd) untuk memperbarui skor di HUD
func tambah_poin(jumlah: int = 1) -> void:
	poin += jumlah
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").on_tomato_collected(jumlah)
	else:
		var label = get_tree().get_first_node_in_group("score_label")
		if label and label.has_method("update_score"):
			label.update_score(poin)

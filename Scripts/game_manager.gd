extends Node

# ─── Konfigurasi Level ─────────────────────────────────────────────────────────
const LEVELS: Array[String] = [
	"res://Scenes/level_root.tscn",
	"res://Scenes/level_root2.tscn",
	"res://Scenes/level_root3.tscn"
]

# ─── Variabel State Game ───────────────────────────────────────────────────────
var current_level_index: int = 0
var total_score: int = 0
var tomatoes_remaining: int = 0
var total_tomatoes_in_level: int = 0
var is_transitioning: bool = false

var _active_tomatoes: Array[Node2D] = []
var hud: CanvasLayer = null


func _ready() -> void:
	# Buat dan tampilkan HUD agar selalu ada di atas setiap level
	_setup_hud()


func _setup_hud() -> void:
	if hud != null and is_instance_valid(hud):
		return

	# Cek jika ada HUD yang sudah ada di tree
	var existing_hud = get_tree().get_first_node_in_group("hud")
	if existing_hud:
		hud = existing_hud
		return

	var hud_scene = preload("res://Scenes/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)


# Dipanggil saat Player selesai _ready di awal level
func on_player_ready(player: CharacterBody2D) -> void:
	_detect_current_level()
	player.poin = total_score

	if hud and is_instance_valid(hud):
		hud.update_level(current_level_index + 1)
		hud.update_score(total_score)
		hud.update_tomatoes(tomatoes_remaining)
		hud.show_level_banner(current_level_index + 1)


func _detect_current_level() -> void:
	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	var scene_path = current_scene.scene_file_path
	for i in range(LEVELS.size()):
		if LEVELS[i] == scene_path or scene_path.ends_with(LEVELS[i].get_file()):
			current_level_index = i
			break


# Dipanggil oleh tomato.gd saat _ready
func register_tomato(tomato: Node2D) -> void:
	if not _active_tomatoes.has(tomato):
		_active_tomatoes.append(tomato)
		tomatoes_remaining = _active_tomatoes.size()
		total_tomatoes_in_level = max(total_tomatoes_in_level, tomatoes_remaining)
		if hud and is_instance_valid(hud):
			hud.update_tomatoes(tomatoes_remaining)


# Dipanggil saat sebuah tomat diambil oleh player
func on_tomato_collected(points: int = 10) -> void:
	total_score += points
	tomatoes_remaining = max(0, tomatoes_remaining - 1)

	# Bersihkan referensi yang sudah di-free
	_active_tomatoes = _active_tomatoes.filter(func(t): return is_instance_valid(t))

	if hud and is_instance_valid(hud):
		hud.update_score(total_score)
		hud.update_tomatoes(tomatoes_remaining)

	# Jika semua tomat telah habis di level ini, lanjut ke level berikutnya
	if tomatoes_remaining <= 0 and not is_transitioning:
		advance_to_next_level()


# Lanjut ke level berikutnya atau tampilkan kemenangan
func advance_to_next_level() -> void:
	is_transitioning = true
	var current_level_num = current_level_index + 1
	var next_level_index = current_level_index + 1

	if next_level_index < LEVELS.size():
		var next_level_num = next_level_index + 1
		if hud and is_instance_valid(hud):
			hud.show_level_complete(current_level_num, next_level_num)

		# Jeda animasi sebelum berpindah scene
		await get_tree().create_timer(1.3).timeout

		current_level_index = next_level_index
		_active_tomatoes.clear()
		tomatoes_remaining = 0
		total_tomatoes_in_level = 0
		is_transitioning = false

		get_tree().change_scene_to_file(LEVELS[current_level_index])
	else:
		# Semua level (1, 2, 3) telah selesai!
		if hud and is_instance_valid(hud):
			hud.show_victory(total_score)


# Mulai ulang seluruh game dari level 1
func restart_game() -> void:
	current_level_index = 0
	total_score = 0
	tomatoes_remaining = 0
	total_tomatoes_in_level = 0
	is_transitioning = false
	_active_tomatoes.clear()

	if hud and is_instance_valid(hud):
		hud.update_score(0)
		hud.update_level(1)

	get_tree().change_scene_to_file(LEVELS[0])

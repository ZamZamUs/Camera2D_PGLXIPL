extends CanvasLayer

# ─── Node References ───────────────────────────────────────────────────────────
@onready var score_label: Label = $TopBar/ScorePanel/Row/ScoreLabel
@onready var level_label: Label = $TopBar/LevelPanel/Row/LevelLabel
@onready var tomato_count_label: Label = $TopBar/LevelPanel/Row/TomatoCountLabel
@onready var help_label: Label = $TopBar/HelpLabel

@onready var banner_panel: PanelContainer = $BannerContainer/BannerPanel
@onready var banner_title: Label = $BannerContainer/BannerPanel/VBox/BannerTitle
@onready var banner_subtitle: Label = $BannerContainer/BannerPanel/VBox/BannerSubtitle

@onready var victory_modal: Control = $VictoryModal
@onready var final_score_label: Label = $VictoryModal/VictoryPanel/VBox/FinalScoreLabel
@onready var restart_button: Button = $VictoryModal/VictoryPanel/VBox/RestartButton

# Tweens
var _score_tween: Tween
var _banner_tween: Tween

func _ready() -> void:
	# Daftarkan ke grup agar player dan game_manager bisa mengaksesnya
	add_to_group("score_label")
	add_to_group("hud")

	# Sembunyikan banner dan modal kemenangan di awal
	banner_panel.modulate.a = 0.0
	victory_modal.visible = false

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

	_hide_help_after_delay()


func _unhandled_input(event: InputEvent) -> void:
	# Jika layar kemenangan aktif, tekan R / Space / Enter untuk main lagi
	if victory_modal.visible:
		if event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and (event.keycode == KEY_R or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
			_on_restart_pressed()


func _hide_help_after_delay() -> void:
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(help_label):
		var t := create_tween()
		t.tween_property(help_label, "modulate:a", 0.0, 0.8)


# Dipanggil saat skor bertambah
func update_score(new_score: int) -> void:
	score_label.text = str(new_score)
	if _score_tween:
		_score_tween.kill()
	_score_tween = create_tween()
	_score_tween.tween_property(score_label, "scale", Vector2(1.35, 1.35), 0.08)
	_score_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.15)


# Perbarui info level di panel HUD (misal: LEVEL 1, LEVEL 2, LEVEL 3)
func update_level(level_number: int) -> void:
	level_label.text = "LEVEL " + str(level_number)


# Perbarui jumlah sisa tomat
func update_tomatoes(remaining: int) -> void:
	tomato_count_label.text = str(remaining)


# Tampilkan banner animasi saat masuk ke level baru
func show_level_banner(level_number: int, subtitle: String = "Kumpulkan semua tomat!") -> void:
	banner_title.text = "LEVEL " + str(level_number)
	banner_subtitle.text = subtitle
	_play_banner_animation(1.6)


# Tampilkan banner animasi saat level selesai
func show_level_complete(level_number: int, next_level: int) -> void:
	banner_title.text = "LEVEL " + str(level_number) + " SELESAI! 🎉"
	banner_subtitle.text = "Menuju Level " + str(next_level) + "..."
	_play_banner_animation(1.2)


func _play_banner_animation(duration: float = 1.6) -> void:
	if _banner_tween:
		_banner_tween.kill()

	banner_panel.scale = Vector2(0.8, 0.8)
	banner_panel.pivot_offset = banner_panel.size / 2.0

	_banner_tween = create_tween()
	# Fade in & scale up
	_banner_tween.tween_property(banner_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_banner_tween.parallel().tween_property(banner_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Tahan sebentar
	_banner_tween.tween_interval(duration)
	# Fade out
	_banner_tween.tween_property(banner_panel, "modulate:a", 0.0, 0.35)


# Tampilkan layar kemenangan setelah semua level selesai
func show_victory(total_score: int) -> void:
	final_score_label.text = "Total Skor: " + str(total_score)
	victory_modal.visible = true
	victory_modal.modulate.a = 0.0

	var t := create_tween()
	t.tween_property(victory_modal, "modulate:a", 1.0, 0.3)


func _on_restart_pressed() -> void:
	victory_modal.visible = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").restart_game()
	else:
		get_tree().reload_current_scene()

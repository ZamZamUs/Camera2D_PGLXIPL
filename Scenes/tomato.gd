extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _collected: bool = false

func _ready() -> void:
	anim.play("default")
	add_to_group("tomatoes")

	# Jika tidak sengaja di-nest di bawah node lain di editor, reparent ke level root
	if get_parent() is Area2D:
		call_deferred("_reparent_to_level")

	# Daftarkan ke GameManager
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").register_tomato(self)

	# Efek bob naik-turun agar terlihat menarik
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 6.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y,       0.6).set_ease(Tween.EASE_IN_OUT)


func _reparent_to_level() -> void:
	var grandparent = get_parent().get_parent() if get_parent() else null
	if grandparent:
		reparent(grandparent)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return

	_collected = true
	# Hapus dari grup segera
	remove_from_group("tomatoes")

	# Matikan collision agar tidak terpicu dua kali
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	var poin_didapat = 10
	if body.has_method("tambah_poin"):
		body.tambah_poin(poin_didapat)
	elif has_node("/root/GameManager"):
		get_node("/root/GameManager").on_tomato_collected(poin_didapat)

	# Efek kecil sebelum hilang
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.12)
	tween.tween_callback(queue_free)

extends Node2D

const WORLD_SIZE := Vector2(1600.0, 1000.0)
const PLAYER_SPEED := 240.0
const ENEMY_SPEED := 72.0
const MAX_HEALTH := 10
const REALMS: Array[String] = ["炼气", "筑基", "金丹", "元婴", "化神"]
const ALTAR := Vector2(800.0, 470.0)
const MERCHANT := Vector2(1060.0, 470.0)
const HERB_POINTS: Array[Vector2] = [Vector2(420, 300), Vector2(580, 760), Vector2(1180, 240), Vector2(1330, 720), Vector2(300, 830)]
const ENEMY_STARTS: Array[Vector2] = [Vector2(650, 650), Vector2(980, 760), Vector2(650, 280)]

var player := Vector2(800.0, 650.0)
var realm_index := 0
var realm_layer := 1
var qi := 0
var max_qi := 100
var spirit_stones := 10
var herbs := 0
var health := MAX_HEALTH
var game_over := false
var enemies: Array[Vector2] = []
var enemy_hps: Array[int] = []
var enemy_spawn_timer := 6.0
var enemy_attack_timer := 0.0
var active_herbs: Array[bool] = [true, true, true, true, true]
var messages: Array[String] = []
var e_was_down := false
var attack_was_down := false
var elapsed := 0.0
var touch_left := false
var touch_right := false
var touch_up := false
var touch_down := false

func _init() -> void:
	for spawn_point in ENEMY_STARTS:
		_spawn_enemy(spawn_point)

func _ready() -> void:
	_add_message("你来到青云山脚，开始自己的修仙之路。")
	_add_message("靠近地图上的对象，按 E 进行互动。")
	_build_touch_controls()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if game_over:
		var restart_down := Input.is_key_pressed(KEY_R)
		if restart_down and not e_was_down:
			_reset_game()
		e_was_down = restart_down
		queue_redraw()
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if touch_left:
		direction.x -= 1.0
	if touch_right:
		direction.x += 1.0
	if touch_up:
		direction.y -= 1.0
	if touch_down:
		direction.y += 1.0
	if direction.length() > 0.0:
		player += direction.normalized() * PLAYER_SPEED * delta
	player.x = clamp(player.x, 40.0, WORLD_SIZE.x - 40.0)
	player.y = clamp(player.y, 100.0, WORLD_SIZE.y - 40.0)
	var e_down := Input.is_key_pressed(KEY_E)
	if e_down and not e_was_down:
		_interact()
	e_was_down = e_down
	var attack_down := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_J)
	if attack_down and not attack_was_down:
		_attack()
	attack_was_down = attack_down
	_update_enemies(delta)
	enemy_spawn_timer -= delta
	if enemy_spawn_timer <= 0.0 and enemies.size() < 6:
		_spawn_enemy(_random_spawn_point())
		enemy_spawn_timer = 7.0
	queue_redraw()

func _build_touch_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var touch_ui := Control.new()
	touch_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(touch_ui)
	var hint := Label.new()
	hint.text = "触屏操作"
	hint.position = Vector2(34, 470)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color("aabbd2"))
	touch_ui.add_child(hint)
	_make_touch_button(touch_ui, "↑", Vector2(108, 430), "touch_up")
	_make_touch_button(touch_ui, "←", Vector2(40, 490), "touch_left")
	_make_touch_button(touch_ui, "↓", Vector2(108, 490), "touch_down")
	_make_touch_button(touch_ui, "→", Vector2(176, 490), "touch_right")
	var interact := Button.new()
	interact.text = "互\n动"
	interact.position = Vector2(510, 465)
	interact.size = Vector2(82, 82)
	interact.add_theme_font_size_override("font_size", 20)
	interact.modulate = Color(1.0, 0.86, 0.52, 0.95)
	interact.pressed.connect(_interact)
	touch_ui.add_child(interact)
	var attack := Button.new()
	attack.text = "攻\n击"
	attack.position = Vector2(420, 465)
	attack.size = Vector2(82, 82)
	attack.add_theme_font_size_override("font_size", 20)
	attack.modulate = Color(1.0, 0.48, 0.45, 0.95)
	attack.pressed.connect(_attack)
	touch_ui.add_child(attack)

func _make_touch_button(parent: Control, caption: String, button_position: Vector2, flag: StringName) -> void:
	var button := Button.new()
	button.text = caption
	button.position = button_position
	button.size = Vector2(62, 52)
	button.add_theme_font_size_override("font_size", 24)
	button.modulate = Color(0.65, 0.85, 0.95, 0.9)
	button.button_down.connect(_set_touch_flag.bind(flag, true))
	button.button_up.connect(_set_touch_flag.bind(flag, false))
	parent.add_child(button)

func _set_touch_flag(flag: StringName, value: bool) -> void:
	set(flag, value)

func _interact() -> void:
	if game_over:
		_reset_game()
		return
	if player.distance_to(ALTAR) < 85.0:
		_cultivate()
		return
	if player.distance_to(MERCHANT) < 85.0:
		_trade()
		return
	for i in HERB_POINTS.size():
		if active_herbs[i] and player.distance_to(HERB_POINTS[i]) < 55.0:
			active_herbs[i] = false
			herbs += 1
			_add_message("你采集了一株灵草。当前灵草：%d" % herbs)
			return
	_add_message("附近没有可以互动的对象。")

func _spawn_enemy(spawn_point: Vector2) -> void:
	enemies.append(spawn_point)
	enemy_hps.append(3)

func _random_spawn_point() -> Vector2:
	var side := randi() % 4
	match side:
		0: return Vector2(randf_range(80.0, WORLD_SIZE.x - 80.0), 130.0)
		1: return Vector2(WORLD_SIZE.x - 80.0, randf_range(130.0, WORLD_SIZE.y - 80.0))
		2: return Vector2(randf_range(80.0, WORLD_SIZE.x - 80.0), WORLD_SIZE.y - 80.0)
		_: return Vector2(80.0, randf_range(130.0, WORLD_SIZE.y - 80.0))

func _update_enemies(delta: float) -> void:
	enemy_attack_timer -= delta
	for i in enemies.size():
		enemies[i] = enemies[i].move_toward(player, ENEMY_SPEED * delta)
		if enemies[i].distance_to(player) < 32.0 and enemy_attack_timer <= 0.0:
			health -= 1
			enemy_attack_timer = 0.9
			_add_message("妖兽咬伤了你，生命 -1。")
			if health <= 0:
				game_over = true
				_add_message("你力竭倒下了，按 R 或点击互动按钮重新开始。")
				return

func _attack() -> void:
	if game_over:
		_reset_game()
		return
	var nearest := -1
	var nearest_distance := 160.0
	for i in enemies.size():
		var distance := enemies[i].distance_to(player)
		if distance <= nearest_distance:
			nearest = i
			nearest_distance = distance
	if nearest < 0:
		_add_message("前方没有进入攻击范围的妖兽。")
		return
	enemy_hps[nearest] -= 1
	_add_message("你挥出一剑，妖兽受伤（剩余生命 %d）。" % enemy_hps[nearest])
	if enemy_hps[nearest] <= 0:
		enemies.remove_at(nearest)
		enemy_hps.remove_at(nearest)
	spirit_stones += 2
	_add_message("妖兽被击败，获得 2 枚灵石。")

func _reset_game() -> void:
	player = Vector2(800.0, 650.0)
	health = MAX_HEALTH
	game_over = false
	qi = 0
	spirit_stones = 10
	herbs = 0
	active_herbs = [true, true, true, true, true]
	enemies.clear()
	enemy_hps.clear()
	for spawn_point in ENEMY_STARTS:
		_spawn_enemy(spawn_point)
	messages.clear()
	_add_message("你重新踏上了修仙之路。")

func _cultivate() -> void:
	if qi >= max_qi:
		_breakthrough()
		return
	var gain := 12 + realm_index * 4
	qi = min(qi + gain, max_qi)
	_add_message("你在修炼台闭关，获得 %d 点灵力。" % gain)
	if qi >= max_qi:
		_add_message("灵力已满！再次按 E 尝试突破。")

func _breakthrough() -> void:
	if qi < max_qi:
		_add_message("灵力不足，还需要 %d 点。" % (max_qi - qi))
		return
	qi = 0
	if realm_layer < 9:
		realm_layer += 1
	else:
		realm_layer = 1
		realm_index = min(realm_index + 1, REALMS.size() - 1)
	max_qi = 100 + realm_index * 50 + (realm_layer - 1) * 15
	spirit_stones += 5
	_add_message("突破成功！当前境界：%s%d层。" % [REALMS[realm_index], realm_layer])

func _trade() -> void:
	if herbs <= 0:
		_add_message("游商：有灵草吗？我可以用灵石交换。")
		return
	herbs -= 1
	spirit_stones += 8
	_add_message("你用一株灵草换到 8 枚灵石。")

func _add_message(message: String) -> void:
	messages.push_front(message)
	if messages.size() > 7:
		messages.pop_back()

func _draw() -> void:
	var camera := Vector2(480.0, 335.0) - player
	draw_rect(Rect2(0, 0, 960, 600), Color("09111e"))
	draw_rect(Rect2(camera, WORLD_SIZE), Color("152c2a"), true)
	# 地面网格帮助新玩家理解地图范围。
	for x in range(0, int(WORLD_SIZE.x) + 1, 100):
		draw_line(Vector2(x, 0) + camera, Vector2(x, WORLD_SIZE.y) + camera, Color(0.2, 0.38, 0.34, 0.25), 1.0)
	for y in range(0, int(WORLD_SIZE.y) + 1, 100):
		draw_line(Vector2(0, y) + camera, Vector2(WORLD_SIZE.x, y) + camera, Color(0.2, 0.38, 0.34, 0.25), 1.0)
	# 修炼台。
	draw_circle(ALTAR + camera, 38.0, Color("b68b4c"))
	draw_circle(ALTAR + camera, 25.0, Color("6c4c2b"))
	draw_string(ThemeDB.fallback_font, ALTAR + camera + Vector2(-35, 62), "修炼台", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f6d58b"))
	# 游商。
	draw_circle(MERCHANT + camera, 24.0, Color("d49b62"))
	draw_circle(MERCHANT + camera + Vector2(0, -8), 12.0, Color("f1c27d"))
	draw_string(ThemeDB.fallback_font, MERCHANT + camera + Vector2(-42, 50), "云游商人", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f6d58b"))
	# 灵草。
	for i in HERB_POINTS.size():
		if active_herbs[i]:
			draw_circle(HERB_POINTS[i] + camera, 14.0, Color("76d68e"))
			draw_circle(HERB_POINTS[i] + camera + Vector2(0, -10), 8.0, Color("b6f28b"))
	# 妖兽。
	for i in enemies.size():
		var enemy_screen := enemies[i] + camera
		draw_circle(enemy_screen, 18.0, Color("c94f62"))
		draw_circle(enemy_screen + Vector2(0, -9), 9.0, Color("f08b76"))
		draw_rect(Rect2(enemy_screen - Vector2(18, 30), Vector2(36, 5)), Color("3a1720"), true)
		draw_rect(Rect2(enemy_screen - Vector2(18, 30), Vector2(12.0 * enemy_hps[i], 5)), Color("e97b68"), true)
	# 玩家。
	draw_circle(player + camera, 18.0, Color("63c7e8"))
	draw_circle(player + camera + Vector2(0, -9), 9.0, Color("d9f4ff"))

	# 固定在屏幕上的状态栏。
	draw_rect(Rect2(0, 0, 960, 88), Color(0.03, 0.06, 0.11, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(24, 30), "自由修仙录", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("f6d58b"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 61), "%s%d层   生命 %d/%d   灵力 %d/%d   灵草 %d   灵石 %d" % [REALMS[realm_index], realm_layer, health, MAX_HEALTH, qi, max_qi, herbs, spirit_stones], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d4e6f5"))
	draw_rect(Rect2(650, 0, 310, 600), Color(0.03, 0.06, 0.11, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(675, 42), "修行日志", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f6d58b"))
	var log_text := "\n".join(messages)
	draw_multiline_string(ThemeDB.fallback_font, Vector2(675, 78), log_text, HORIZONTAL_ALIGNMENT_LEFT, 260, 16, -1, Color("c4d4e8"))
	draw_rect(Rect2(0, 550, 650, 50), Color(0.03, 0.06, 0.11, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(24, 581), "WASD / 方向键移动    空格/J 攻击    E 互动    目标：探索、战斗、修炼、突破", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("c4d4e8"))
	if game_over:
		draw_rect(Rect2(190, 230, 410, 120), Color(0.03, 0.04, 0.08, 0.95))
		draw_string(ThemeDB.fallback_font, Vector2(300, 280), "你已力竭", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("ffb36b"))
		draw_string(ThemeDB.fallback_font, Vector2(250, 320), "按 R 或点击互动按钮重开", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e0e8f2"))


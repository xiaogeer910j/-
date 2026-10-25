extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://main.tscn")
	assert(scene != null, "主场景必须存在")
	var game: Node2D = scene.instantiate()
	root.add_child(game)
	assert(game.realm_index == 0, "初始境界应为炼气")
	assert(game.active_herbs.size() == 5, "地图应有五株灵草")
	game.player = game.ALTAR
	game._cultivate()
	assert(game.qi == 12, "第一次修炼应获得 12 点灵力")
	game.qi = game.max_qi
	game._cultivate()
	assert(game.realm_layer == 2, "突破后应进入下一层")
	print("free cultivation smoke test passed")
	quit()

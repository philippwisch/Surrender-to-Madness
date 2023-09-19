extends Node2D

class_name Gameplay

signal countdown

signal player_cast_finished
signal player_cast_update
signal player_cd_update
signal player_hp_update
signal player_rp_update
signal player_speed_update
signal player_death

signal boss_cast_finished
signal boss_hp_update
signal boss_cast_update
signal boss_death

var player: Player
var boss: Boss
var arena: BossArena

var player_game_position

# used when starting the game
var countdown_progress = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func pause_game():
	get_tree().paused = true
	
func unpause_game():
	get_tree().paused = false


func start_game(arena_path, boss_path):
	# TODO HERE: get information from ui which boss encounter the player
	# selected
	# just using these 2 for testing here
	const a_path = "res://gameplay/arenas/arena_space.tscn"
	const b_path = "res://gameplay/bosses/flying_spaghetti_monster.tscn"
	const p_path = "res://gameplay/other/player.tscn"
	
	prepare_game(a_path, b_path, p_path)
	
	$Countdown.timeout.connect(on_countdown_timeout)
	# emit once at the start so the 3 shows up instantly
	countdown.emit(str(countdown_progress))
	$Countdown.start()


func on_countdown_timeout():
	if countdown_progress > 1:
		countdown_progress -= 1
		$Countdown.start()
		countdown.emit(str(countdown_progress))
	else:
		player.start_game()
		boss.start_game()
		countdown.emit("")


func prepare_game(arena_scene_path: String, boss_scene_path: String, player_scene_path: String):
	arena = reload_child_scene(arena_scene_path, arena)
	boss = reload_child_scene(boss_scene_path, boss)
	player = reload_child_scene(player_scene_path, player)
	init_signals() # Connect Signals AFTER all nodes have been created
	
	boss.global_position = Vector2(800, 400)
	player_game_position = Vector2(1,1)
	# run move once to move player to starting position
	player.move()


func reload_child_scene(scene_path: String, node_reference: Node):
	var ref = node_reference
	var scene
	
	if ref:
		ref.queue_free()
	scene = load(scene_path)
	node_reference = scene.instantiate()
	add_child(node_reference)
	return node_reference


# area of effect should be an array of Vector2 corresponding to all the
# locations the boss ability will hit
func _on_boss_cast_finished(damage, area_of_effect):
	if player_game_position in area_of_effect:
		player.update_hp(-damage)
	
	boss_cast_finished.emit()

func _on_boss_cast_update(cast_progress, cast_name):
	boss_cast_update.emit(cast_progress, cast_name)


func _on_boss_hp_update(hp):
	boss_hp_update.emit(float(hp) / float(boss.hp_max))


func _on_player_cast_finished(damage, name):
	if name == "Silence":
		boss.interrupt_cast()
		boss_cast_update.emit(1, "Interrupted")
	boss.update_hp(-damage)
	
	player_cast_finished.emit()


func _on_player_cast_update(cast_progress, cast_name):
	player_cast_update.emit(cast_progress, cast_name)


func _on_player_cd_update(progress):
	player_cd_update.emit(progress)


func _on_player_death():
	player_death.emit()
	# game_end.emit()


func _on_player_hp_update(hp):
	player_hp_update.emit(float(hp) / float(player.hp_max))


func _on_player_move_input(dir: Vector2):
	var cur = player_game_position
	var new = cur + dir
	new = clamp_position_to_game_grid(new)
	player_game_position = new
	arena.adjust_player_sprite(player,player_game_position)


func _on_player_rp_update(rp):
	player_rp_update.emit(float(rp) / float(player.rp_max))


func _on_player_speed_update(speed):
	player_speed_update.emit(speed)


func init_signals():
	boss.cast_finished.connect(_on_boss_cast_finished)
	boss.cast_update.connect(_on_boss_cast_update)
	boss.hp_update.connect(_on_boss_hp_update)
	
	player.cast_finished.connect(_on_player_cast_finished)
	player.cast_update.connect(_on_player_cast_update)
	player.cd_update.connect(_on_player_cd_update)
	player.death.connect(_on_player_death)	
	player.hp_update.connect(_on_player_hp_update)
	player.move_input.connect(_on_player_move_input)
	player.rp_update.connect(_on_player_rp_update)
	player.speed_update.connect(_on_player_speed_update)


func clamp_position_to_game_grid(pos):
	var res = Vector2(pos)
	if pos.x < arena.GAME_POSITION_MIN.x:
		res.x = arena.GAME_POSITION_MIN.x
	if pos.y < arena.GAME_POSITION_MIN.y:
		res.y = arena.GAME_POSITION_MIN.y
		
	if pos.x > arena.GAME_POSITION_MAX.x:
		res.x = arena.GAME_POSITION_MAX.x
	if pos.y > arena.GAME_POSITION_MAX.y:
		res.y = arena.GAME_POSITION_MAX.y
	return res

extends CharacterBody2D

enum CellType {
	GROUND = 1,
	KEY = 2,
	DOOR = 4,
}

enum TileMapLayers {
	BACKGROUND = 0,
	FOREGROUND = 1,
	COLLECTABLE = 2,
}

signal player_died

@onready var _animation_player = $AnimationPlayer

@export var jump_force : float = 450.0
@export var gravity : float = 9.8

var has_key : bool = false
var lift_off_y : float = 0.0
var tile_map : TileMap

func _ready():
	_animation_player.play("run")

func _process(_delta):
	# jump
	if is_on_floor() and Input.is_action_pressed("jump"):
		lift_off_y = position.y
		_animation_player.play("jump")
		velocity.y -= jump_force
	
	# in air	
	if not is_on_floor():
		velocity.y += gravity
		if position.y > 200:
			die()
			
	check_for_collectable_collision()
	# move
	move_and_slide()

	# finish jump
	if is_on_floor() and _animation_player.current_animation == "jump":
		if lift_off_y > position.y:
			var tile_data = get_tile_data_from_last_collision('type')
			if !tile_data == null and tile_data == CellType.GROUND:
				create_tween().tween_property(get_parent().get_node("Camera2D"), "position", Vector2(7, position.y), 0.25)
				# get_parent().get_node("Camera2D").position.y = position.y
				# assert(get_parent().get_node("Camera2D").position.y == position.y, 'Camera isn\'t on the same Y position as the player')
			
		_animation_player.play("run")
		_animation_player.advance(0.2)
		
func get_tile_data_from_last_collision(data_name: String = 'type', layer: TileMapLayers = TileMapLayers.FOREGROUND):
	# its possible there are more than 1 collisions per frame,
	# but for this game its highly unlikely so just take the last collision for simplicity
	var collision = get_last_slide_collision()
	
	# get_collider() returns an object, which in this case will be the whole TileMap, because we don't have any free standing objects
	tile_map = collision.get_collider()
	assert(tile_map is TileMap, 'We introduced a collision that wasn\'t in the TileMap')
	
	# collisions have a RID or Resource ID and we can use that collision RID to get coordinates off a TileMap
	var collided_tile_coords : Vector2i = tile_map.get_coords_for_body_rid(collision.get_collider_rid())
	var tile_data : TileData = tile_map.get_cell_tile_data(layer, collided_tile_coords)
	if !tile_data is TileData:
		return null
		
	return tile_data.get_custom_data(data_name)
	
func check_for_collectable_collision():
	# its possible there are more than 1 collisions per frame,
	# but for this game its highly unlikely so just take the last collision for simplicity
	var collision = get_last_slide_collision()
	if collision == null:
		return null
	
	# get_collider() returns an object, which in this case will be the whole TileMap, because we don't have any free standing objects
	tile_map = collision.get_collider()
	assert(tile_map is TileMap, 'We introduced a collision that wasn\'t in the TileMap')
	
	# collisions have a RID or Resource ID and we can use that collision RID to get coordinates off a TileMap
	var collided_tile_coords : Vector2i = tile_map.get_coords_for_body_rid(collision.get_collider_rid())
	var tile_data : TileData = tile_map.get_cell_tile_data(TileMapLayers.COLLECTABLE, collided_tile_coords)
	if !tile_data is TileData:
		return null
		
	var custom_data = tile_data.get_custom_data('type')
	collect_object(collided_tile_coords, custom_data)
	
func collect_object(tile_coords, type):
	if type == CellType.KEY:
		has_key = true
		tile_map.erase_cell(TileMapLayers.COLLECTABLE, tile_coords)
		print('got that key')
	elif type == CellType.DOOR and has_key:
		print('winner winner chicken dinner')
		tile_map.erase_cell(TileMapLayers.COLLECTABLE, tile_coords)
		tile_map.speed = 0.0
		_animation_player.stop()

func die():
	player_died.emit()
	print('man down')
	get_tree().reload_current_scene()


func _on_screen_exited():
	die()

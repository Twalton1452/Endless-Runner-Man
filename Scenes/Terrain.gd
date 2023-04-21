extends TileMap

@export var speed = 100
# 100 is enonugh for single block jumps

func _process(delta):
	position.x -= speed * delta

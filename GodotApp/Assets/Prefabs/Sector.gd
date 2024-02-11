extends Sprite
class_name SectorType

var id := 0;

func _ready():
	pass # Replace with function body.

func update_pos(x: float, y: float) -> void:
	set_position(Vector2(x, y))

func update_type(x: int) -> void:
	match x:
		0: self.texture = preload("res://Assets/Textures/starmap_overlay_point_exotic_shop.png")
		1: self.texture = preload("res://Assets/Textures/starmap_overlay_point_general_shop.png")
		2: self.texture = preload("res://Assets/Textures/starmap_overlay_point_hub.png")
		3: self.texture = preload("res://Assets/Textures/starmap_overlay_point_mission.png")
		4: self.texture = preload("res://Assets/Textures/starmap_overlay_point_warp_station.png")
		5: self.texture = preload("res://Assets/Textures/Starmap_Waypoint.png")

func update_id(x: int) -> void:
	id = x

func update_faction(x: int) -> void:
	match x:
		0: self.modulate = Color(0.0652, 0.4903, 0.9853)
		1: self.modulate = Color(1,1,1)
		2: self.modulate = Color(1, 0.4759, 0) 
		3: self.modulate = Color(1, 0.4412, 0.9383) 
		4: self.modulate = Color(1, 0.0956, 0) 
		5: self.modulate = Color(0.9929, 1, 0)
		6: self.modulate = Color(0, 0, 0)  

func update_name(name: String) -> void:
	$Name.text = name;

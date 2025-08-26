extends CharacterBody2D






	
	
func _take_damage(damage: int) -> void:
	damage = 0
	$"../weak_hit".play()

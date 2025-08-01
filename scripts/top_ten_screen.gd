extends Control


var top_scores = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	top_scores = HighScoreManager.load_scores()
	update_score_list()
	
	var content = $ContentGroup
	await center_node(content)
	
	content.modulate.a = 0.0
	content.position.y += 100  # Start slightly lower for slide-up

	var tween = get_tree().create_tween()
	tween.tween_property(content, "modulate:a", 1.0, 2.0)
	tween.parallel().tween_property(content, "position", content.position - Vector2(0, 240), 2.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
func update_score_list() -> void:
	var score_list = $ContentGroup/LabelHighScore/VBoxContainer
	
	for i in range(10):
		var entry = score_list.get_child(i)
		var rank_label = entry.get_node("LabelRank")
		var name_label = entry.get_node("LabelName")
		var score_label = entry.get_node("LabelScore")
		var level_label = entry.get_node("LabelLevel")
		
		if i < top_scores.size():
			var score_entry = top_scores[i]
			name_label.text = score_entry["name"] + "-"
			score_label.text = str(int(score_entry["score"])) + "-"
			level_label.text = "Level " + str(int(score_entry["level"]))
		else:
			# Fill empty spots if fewer than 10 entries
			name_label.text = "---"
			score_label.text = "0-"
			if level_label:
				level_label.text = ""
			
			
func center_node(node: Control) -> void:
	await get_tree().process_frame  # Ensure size is valid
	var viewport_size = get_viewport().size
	var node_size = node.size
	node.position = (Vector2(viewport_size) - node_size) * 0.5

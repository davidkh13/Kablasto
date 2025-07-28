extends Node

const SAVE_PATH := "user://highscores.json"
var top_scores := []



func _ready() -> void:
	top_scores = load_scores()

func load_scores() -> Array:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var content := file.get_as_text()
			var parsed = JSON.parse_string(content)
			if parsed is Array:
				#print("Loaded high scores:", parsed)
				return parsed
	print("No high scores found, returning empty list.")
	return []


func save_scores() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(top_scores))
		print("High scores saved.")
	else:
		print("Failed to save high scores.")
		
		
func qualifies_for_highscore(score: int) -> bool:
	if top_scores.size() < 10:
		return true
	for entry in top_scores:
		if score > entry["score"]:
			return true
	return false
	

func add_score(nameA: String, score: int, level: int) -> void:
	top_scores.append({"name": nameA, "score": score, "level": level})
	#Sort descending by score
	top_scores.sort_custom(_sort_scores_desc)
	#Keep only top 10
	if top_scores.size() > 10:
		top_scores = top_scores.slice(0,10)
	save_scores()
	
	
func _sort_scores_desc(a,b) -> int:
	return b["score"] - a["score"]

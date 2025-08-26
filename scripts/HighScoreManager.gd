extends Node

const SAVE_PATH := "user://highscores.json"
#example C:\Users\DavidHenson\AppData\Roaming\Godot\app_userdata\Kablasto
#use %APPDATA%
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
				# Ensure numeric scores
				for entry in parsed:
					entry["score"] = int(entry["score"])
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
	top_scores.append({"name": nameA, "score": int(score), "level": int(level)})

	bubble_sort_scores_desc(top_scores)
			
	if top_scores.size() > 10:
		top_scores = top_scores.slice(0, 10)
		
	save_scores()
	
	
func bubble_sort_scores_desc(arr: Array) -> void:
	var n = arr.size()
	for i in range(n):
		for j in range(n - i - 1):
			if int(arr[j]["score"]) < int(arr[j + 1]["score"]):
				var temp = arr[j]
				arr[j] = arr[j + 1]
				arr[j + 1] = temp
	
	
func _sort_scores_desc(a,b) -> int:
	return int(b["score"]) - int(a["score"])

extends RefCounted
class_name LevelData

const LEVELS := {
	1: {
		"name": "Tutorial",
		"starting_gold": 150,
		"lanes": [
			{ "defenses": [{"type": "Wall", "x": 400}] },
			{ "defenses": [{"type": "RapidFire", "x": 500}] },
			{ "defenses": [] },
			{ "defenses": [] }
		]
	},
	2: {
		"name": "Mixed Defenses",
		"starting_gold": 200,
		"lanes": [
			{ "defenses": [{"type": "Wall", "x": 300}, {"type": "Sniper", "x": 600}] },
			{ "defenses": [{"type": "AoE", "x": 450}] },
			{ "defenses": [{"type": "RapidFire", "x": 350}, {"type": "Wall", "x": 700}] },
			{ "defenses": [{"type": "Sniper", "x": 500}] }
		]
	},
	3: {
		"name": "Fortress",
		"starting_gold": 250,
		"lanes": [
			{ "defenses": [{"type": "Wall", "x": 200}, {"type": "AoE", "x": 400}, {"type": "Sniper", "x": 700}] },
			{ "defenses": [{"type": "RapidFire", "x": 300}, {"type": "Wall", "x": 500}, {"type": "RapidFire", "x": 800}] },
			{ "defenses": [{"type": "Wall", "x": 250}, {"type": "Sniper", "x": 450}, {"type": "Wall", "x": 650}] },
			{ "defenses": [{"type": "AoE", "x": 350}, {"type": "Wall", "x": 600}, {"type": "AoE", "x": 850}] }
		]
	}
}


static func get_level(level_number: int) -> Dictionary:
	return LEVELS.get(level_number, LEVELS[1])

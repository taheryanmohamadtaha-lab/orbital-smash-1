extends SceneTree
## Loads every script/scene so parse errors fail CI.
## godot --headless --path . --script tests/load_scripts.gd

const PATHS := [
	"res://scripts/core/loc.gd", "res://scripts/core/game_state.gd", "res://scripts/save/save_manager.gd",
	"res://scripts/levels/level_loader.gd", "res://scripts/levels/level_validator.gd",
	"res://scripts/audio/audio_manager.gd", "res://scripts/physics/ball.gd", "res://scripts/physics/block.gd",
	"res://scripts/physics/mover.gd", "res://scripts/gameplay/world_builder.gd", "res://scripts/gameplay/game.gd",
	"res://scripts/ui/ui_kit.gd", "res://scripts/ui/hud.gd", "res://scripts/ui/menu.gd",
	"res://scenes/main/main.tscn", "res://scenes/gameplay/game.tscn",
]

func _init() -> void:
	var bad := 0
	for p in PATHS:
		var r = load(p)
		if r == null or (r is GDScript and not (r as GDScript).can_instantiate() and not str(p).ends_with("game_state.gd")):
			bad += 1
			print("FAIL load: ", p)
	print("scripts checked: %d, failures: %d" % [PATHS.size(), bad])
	quit(1 if bad > 0 else 0)

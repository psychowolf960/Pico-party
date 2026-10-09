# Couch Party

Local multiplayer for Godot 4, the "party game on one screen" kind:

- **Join with anything**: each gamepad and each keyboard layout (WASD, arrows, IJKL) is a seat. Press *o* to join, left/right to pick a character, *o* to be ready.
- **Per-player input actions**: `p1_left`, `p2_o`… bound to the right device, plus shared `any_*` actions that listen to everything (menus, solo play).
- **Automatic split screen**: up to 4 views in a 2×2 grid, one camera and HUD per player, the window grows to fit.
- **Party mode**: a playlist of minigames, 1 point per player beaten (ties handled), a scores screen in between.

Tested on Godot 4.7. Pure GDScript, no dependencies.

## Install

1. Copy `addons/couch_party` into your project (or install it from the Asset Library).
2. *Project → Project Settings → Plugins*: enable **Couch Party**.

This adds two autoloads, `CouchPlayers` and `CouchParty`, and a **Couch Party** section to the project settings.

## Settings

| Setting (`couch_party/…`) | Default | |
|---|---|---|
| `input/player_prefix` | `p` | Per-player actions are `p1_left`, `p2_o`… |
| `input/shared_prefix` | `any` | Shared actions are `any_left`, `any_o`…, plus `any_menu` |
| `split_screen/divider_color` | black | Lines between the views |
| `split_screen/filler_color` | black | The empty 4th quarter with 3 players |
| `party/lobby_scene` | | Scene with a `CouchLobby` node |
| `party/menu_scene` | | Where `CouchParty.quit()` goes |
| `party/scores_scene` | | Shown after each minigame; empty to chain them directly |

The size of one view is the project's viewport size (`display/window/size/viewport_*`). Split screen enlarges `content_scale_size`, so `display/window/stretch/mode` must be `viewport` or `canvas_items`.

Buttons are `left`, `right`, `up`, `down`, `o` (confirm/jump) and `x` (back/action). Change the bindings by editing `CouchPlayers.keyboards`, `pad`, `shared`, `menu_keys` or `menu_pad` from one of your autoloads, then call `CouchPlayers.rebind()`.

## Usage

### Input in your player script

```gdscript
@export var index = 0  # set by CouchPlayers.split() for players 2 to 4

func _physics_process(_delta):
	var dir = Input.get_axis(CouchPlayers.action(index, "left"), CouchPlayers.action(index, "right"))
	if Input.is_action_just_pressed(CouchPlayers.action(index, "o")):
		jump()
```

With one player, `action()` returns the shared action so any device works. `CouchPlayers.skin(index)` gives the character picked in the lobby.

### Lobby

Add a `CouchLobby` node to your lobby scene, draw its `seats` and react to its signals:

```gdscript
@onready var lobby = $CouchLobby

func _ready():
	lobby.skin_count = 4
	lobby.changed.connect(redraw)
	lobby.confirmed.connect(go)

func go():
	lobby.commit()
	CouchParty.start(lobby.seats.size(), CouchParty.playlist)

func redraw():
	for seat in lobby.seats:
		print(seat.skin, " ready" if seat.ready else "", " pad %d" % seat.pad if seat.pad >= 0 else " keys %d" % seat.keys)
```

Signals: `joined(seat)`, `left(seat)`, `skin_changed(seat)`, `readied(seat)`, `unreadied(seat)`, `confirmed`, `changed`.

### Minigame scene

`CouchPlayers.split(game, offsets)` (or `shared_screen()` for a single shared camera) expects this in the scene:

- a `%Player` node (unique name), an instance of a scene (not a plain node) whose script has an `index` property;
- a `%Camera` node whose script has a `target` property;
- a child named `HUD` (a `CanvasLayer` or `Control`).

Players 2 to 4 are new instances of the player scene placed at `%Player.position + offsets[i]`; their cameras and HUDs are copies.

```gdscript
const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(-16, 0), Vector2(32, 0)]
var views = []

func _ready():
	views = CouchPlayers.split(self, STARTS)  # [{player, camera, hud}, ...]

func _on_goal_reached(winner):
	var values = []
	for view in views:
		values.append(view.player.score)
	values[winner.index] += 1000
	CouchParty.finish(CouchParty.rank(values))
```

### Party

```gdscript
const GAMES = [
	{"name": "race", "scene": "res://race.tscn"},
	{"name": "flood", "scene": "res://flood.tscn"},
]

CouchParty.choose(GAMES)        # lobby, then the games once everyone is ready
CouchParty.start(2, GAMES)      # or start directly with 2 players
```

`CouchParty.finish(ranking)` takes groups of player indexes, best first; players in the same group are tied: `CouchParty.finish([[2], [0, 1], [3]])`. Each player gets 1 point per player beaten. `CouchParty.rank(values)` builds that ranking from one score per player.

In the scores scene: `CouchParty.scores`, `CouchParty.gained`, `CouchParty.is_over()`, `CouchParty.upcoming()` and `CouchParty.next()`.

To use your own scene transition: `CouchParty.change_scene = MyTransition.change_scene`. It must call `CouchPlayers.reset_screen()` to go back to a single view (the default one does). Call `reset_screen()` yourself too when you leave a split-screen scene without `CouchParty`.

## Français

Multijoueur local pour Godot 4 : chaque manette ou moitié de clavier rejoint la partie, choisit un perso, reçoit ses propres actions (`p1_left`…) et sa part d'écran, puis enchaîne des mini-jeux avec un tableau des scores. Installation : copier `addons/couch_party`, puis activer le plugin dans *Projet → Paramètres du projet → Plugins*.

## License

Public domain, see [LICENSE](LICENSE) (the Unlicense).

By Gus Roquefort.

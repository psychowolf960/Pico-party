# Créer un mini-jeu

L'addon `couch_party`:

- `CouchPlayers` crée les joueurs, gère leurs touches et l'écran ;
- `CouchParty` enchaîne les mini-jeux et compte les points.

## 1. La scène


- `Player` : une instance de `scenes/player.tscn`, en nom unique (`%Player`) ;
- `Camera` : une `Camera2D`, en nom unique (`%Camera`) ;
- `HUD` : un `CanvasLayer`


## 2. Créer les joueurs

```gdscript
const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(-16, 0), Vector2(32, 0)]

var views = []
var players = []


func _ready():
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
```

- `STARTS` : la position de départ de chaque joueur, par rapport à `%Player` dans la scène.
- `shared_screen` ou `split` à la place pour découper l'écran par joueur.
- `player.index` : le numéro du joueur, à partir de 0.
- `view.hud` : le `HUD` de la vue (un par joueur en écran partagé `split`).

Il y a toujours au moins 2 joueurs.

## 3. Lire les touches

```gdscript
if Input.is_action_just_pressed(CouchPlayers.action(player.index, "o")):
	sauter()
```

Boutons : `"left"`, `"right"`, `"up"`, `"down"`, `"o"`, `"x"`.

## 4. Finir la partie

```gdscript
CouchParty.finish([[2], [0, 1], [3]])
```


```gdscript
CouchParty.finish(CouchParty.rank(scores))
```

Pour afficher les scores et le bandeau de fin `scripts/minigame.gd` :

```gdscript
$HUD/Scores.text = Minigame.score_line(scores)              # "j1 3  j2 0"
Minigame.show_banner(views, Minigame.win_title(winner.index), Minigame.score_line(scores))
# ↑ remplit HUD/Banner/Bravo, et HUD/Banner/Score s'il existe
Minigame.hide_banner(views)
var bounds = Minigame.level_bounds(%Level)                  # Rect2 des tuiles du niveau
```

Pour revenir au menu avec Échap :

```gdscript
func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
```

## 5. Ajouter le jeu au menu

Dans `scripts/menu.gd`,

```gdscript
{"name": "jeu", "scene": "res://scenes/mon_jeu.tscn"},
```


## Licence

Le code du jeu et le plugin Couch Party sont dans le domaine public (The Unlicense), voir [LICENSE](LICENSE). Auteur : Gus Roquefort.

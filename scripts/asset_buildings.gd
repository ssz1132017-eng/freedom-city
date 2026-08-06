extends Node3D
## 用 Kenney GLB 素材生成城市建筑与街道设施。
## 依赖 assets/buildings/*.glb 与 assets/roads/*.glb（CC0，Kenney）。

const BLOCK := 20.0
const STREET_W := 12.0
const GRID_W := 12
const GRID_H := 12

var rng := RandomNumberGenerator.new()
var building_scenes: Array = []
var skyscraper_scenes: Array = []
var road_light_scenes: Array = []

func _ready() -> void:
	rng.randomize()
	_load_assets()
	_build_asset_buildings()
	_build_road_lights()

## 预加载 GLB（glTF 场景）
func _load_assets() -> void:
	var dir := DirAccess.open("res://assets/buildings")
	if dir:
		for f in dir.get_files():
			if f.ends_with(".glb"):
				var scene := load("res://assets/buildings/" + f)
				if scene:
					if f.contains("skyscraper"):
						skyscraper_scenes.append(scene)
					else:
						building_scenes.append(scene)
	print("loaded buildings: ", building_scenes.size(), ", skyscrapers: ", skyscraper_scenes.size())
	dir = DirAccess.open("res://assets/roads")
	if dir:
		for f in dir.get_files():
			if f.contains("light") and f.ends_with(".glb") and not f.contains("construction"):
				var scene := load("res://assets/roads/" + f)
				if scene:
					road_light_scenes.append(scene)
	print("loaded road lights: ", road_light_scenes.size())

## 每个街区放 1~3 栋 GLB 建筑
func _build_asset_buildings() -> void:
	var count := 0
	for i in range(GRID_W):
		for j in range(GRID_H):
			var cx := (i + 0.5) * BLOCK
			var cz := (j + 0.5) * BLOCK
			var n := rng.randi_range(1, 3)
			for k in range(n):
				var scene: PackedScene
				# 市中心（中间区域）多放摩天楼
				var mid := absf(i - GRID_W / 2.0) < 3 and absf(j - GRID_H / 2.0) < 3
				if mid and skyscraper_scenes.size() > 0 and rng.randf() < 0.5:
					scene = skyscraper_scenes[rng.randi_range(0, skyscraper_scenes.size() - 1)]
				elif building_scenes.size() > 0:
					scene = building_scenes[rng.randi_range(0, building_scenes.size() - 1)]
				else:
					continue
				var b := scene.instantiate()
				b.name = "AssetBuilding_%d_%d_%d" % [i, j, k]
				# 街区内的随机偏移（避开街道）
				var ox := rng.randf_range(-(BLOCK / 2.0 - STREET_W / 2.0 - 3.0), BLOCK / 2.0 - STREET_W / 2.0 - 3.0)
				var oz := rng.randf_range(-(BLOCK / 2.0 - STREET_W / 2.0 - 3.0), BLOCK / 2.0 - STREET_W / 2.0 - 3.0)
				b.position = Vector3(cx + ox, 0, cz + oz)
				b.rotation.y = rng.randf() * TAU  # 随机朝向
				# 随机缩放（GLB 素材原始尺寸偏小，放大到街区块）
				var s := rng.randf_range(1.0, 1.6)
				b.scale = Vector3(s, s, s)
				add_child(b)
				count += 1
	print("placed asset buildings: ", count)

## 路口放 GLB 路灯
func _build_road_lights() -> void:
	if road_light_scenes.size() == 0:
		print("no road lights available")
		return
	var count := 0
	for i in range(0, GRID_W + 1, 2):
		for j in range(0, GRID_H + 1, 2):
			var l: Node3D = road_light_scenes[rng.randi_range(0, road_light_scenes.size() - 1)].instantiate()
			l.name = "AssetLight_%d_%d" % [i, j]
			l.position = Vector3(i * BLOCK, 0, j * BLOCK)
			add_child(l)
			count += 1
	print("placed road lights: ", count)

extends Node3D
## 程序化生成迷你城市：街道网格 + 建筑 + 路灯
## 全部用代码生成，不依赖任何外部模型文件。

# 城市范围（格子数）
const GRID_W := 12
const GRID_H := 12
# 街区大小（米）
const BLOCK := 20.0
# 街道宽度（米）
const STREET_W := 12.0
# 建筑最大高度
const BUILDING_MAX_H := 30.0

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_build_ground()
	_build_streets()
	# _build_buildings() 已由 AssetBuildings 用 GLB 素材替代
	_build_streetlights()
	_build_traffic()
	_build_pedestrians()
	_build_traffic_lights()
	_build_crosswalks()

## 生成 NPC 车辆：每条街道上随机放几辆
func _build_traffic() -> void:
	var npc_script := load("res://scripts/npc_car.gd")
	var count := 0
	# 横向街道（沿 Z 行驶）：x = i*BLOCK，车放在街道中间
	for i in range(GRID_W + 1):
		for k in range(2):
			if rng.randf() < 0.5:
				var car := CharacterBody3D.new()
				car.name = "NpcCar_%d_%d" % [i, k]
				car.set_script(npc_script)
				var z := rng.randf_range(3.0, GRID_H * BLOCK - 3.0)
				car.position = Vector3(i * BLOCK, 0.4, z)
				add_child(car)
				count += 1
	# 纵向街道（沿 X 行驶）：z = j*BLOCK
	for j in range(GRID_H + 1):
		for k in range(2):
			if rng.randf() < 0.5:
				var car := CharacterBody3D.new()
				car.name = "NpcCarV_%d_%d" % [j, k]
				car.set_script(npc_script)
				var x := rng.randf_range(3.0, GRID_W * BLOCK - 3.0)
				car.position = Vector3(x, 0.4, j * BLOCK)
				car.rotate_y(PI / 2.0)  # 面朝 X 方向
				add_child(car)
				count += 1
	print("generated NPC cars: ", count)

## 生成行人：沿街道两侧人行道放几个
func _build_pedestrians() -> void:
	var ped_script := load("res://scripts/pedestrian.gd")
	var count := 0
	for i in range(GRID_W + 1):
		for side in [-1.0, 1.0]:
			if rng.randf() < 0.35:
				var p := CharacterBody3D.new()
				p.name = "Ped_%d_%s" % [i, "L" if side < 0 else "R"]
				p.set_script(ped_script)
				# 人行道：街道两侧靠建筑处
				var px: float = i * BLOCK + side * (STREET_W / 2.0 + 1.2)
				var pz: float = rng.randf_range(4.0, GRID_H * BLOCK - 4.0)
				p.position = Vector3(px, 0.0, pz)
				add_child(p)
				count += 1
	print("generated pedestrians: ", count)

## 红绿灯：每 2 个路口放一组（避免全城都是灯）
func _build_traffic_lights() -> void:
	var light_script := load("res://scripts/traffic_light.gd")
	var count := 0
	for i in range(0, GRID_W + 1, 2):
		for j in range(0, GRID_H + 1, 2):
			var tl := Node3D.new()
			tl.name = "TrafficLight_%d_%d" % [i, j]
			tl.set_script(light_script)
			tl.position = Vector3(i * BLOCK, 0, j * BLOCK)
			add_child(tl)
			# 把 grid 信息传给脚本（脚本 _ready 时注册）
			tl.set("grid", Vector2i(i, j))
			count += 1
	print("generated traffic lights: ", count)

## 斑马线：灯控路口的四个入口各铺几条白条
func _build_crosswalks() -> void:
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.92, 0.92, 0.9)
	white.roughness = 0.9
	var count := 0
	for i in range(0, GRID_W + 1, 2):
		for j in range(0, GRID_H + 1, 2):
			var cx := i * BLOCK
			var cz := j * BLOCK
			# 南北向入口（沿 Z 的街道，x = cx 两侧）
			for side in [-1.0, 1.0]:
				for k in range(5):
					var stripe := MeshInstance3D.new()
					stripe.name = "Crosswalk_%d_%d_%d" % [i, j, k]
					stripe.mesh = _box(1.2, 0.06, 0.6)
					stripe.mesh.surface_set_material(0, white)
					stripe.position = Vector3(
						cx + side * (STREET_W / 2.0 + 0.5),
						0.06,
						cz - 3.0 + k * 1.5
					)
					add_child(stripe)
					count += 1
			# 东西向入口（沿 X 的街道，z = cz 两侧）
			for side in [-1.0, 1.0]:
				for k in range(5):
					var stripe := MeshInstance3D.new()
					stripe.name = "CrosswalkH_%d_%d_%d" % [i, j, k]
					stripe.mesh = _box(0.6, 0.06, 1.2)
					stripe.mesh.surface_set_material(0, white)
					stripe.position = Vector3(
						cx - 3.0 + k * 1.5,
						0.06,
						cz + side * (STREET_W / 2.0 + 0.5)
					)
					add_child(stripe)
					count += 1
	print("generated crosswalk stripes: ", count)

## 一大块平整地面（城市基底）
func _build_ground() -> void:
	var size := Vector2(GRID_W * BLOCK, GRID_H * BLOCK)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = _box(size.x, 1.0, size.y)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.38, 0.3)  # 灰绿色，像草地/水泥混合
	mat.roughness = 1.0
	ground.mesh.surface_set_material(0, mat)
	ground.position = Vector3(size.x / 2.0, -0.5, size.y / 2.0)
	add_child(ground)

	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundBody"
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 1.0, size.y)
	var col := CollisionShape3D.new()
	col.shape = shape
	ground_body.add_child(col)
	ground_body.position = ground.position
	add_child(ground_body)

## 街道：在每个街区边界铺深色沥青条
func _build_streets() -> void:
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.12, 0.12, 0.14)
	asphalt.roughness = 0.95
	# 横向街道
	for i in range(GRID_W + 1):
		var s := MeshInstance3D.new()
		s.name = "StreetH%d" % i
		s.mesh = _box(GRID_W * BLOCK, 0.05, STREET_W)
		s.mesh.surface_set_material(0, asphalt)
		s.position = Vector3(i * BLOCK, 0.03, GRID_H * BLOCK / 2.0)
		add_child(s)
	# 纵向街道
	for j in range(GRID_H + 1):
		var s := MeshInstance3D.new()
		s.name = "StreetV%d" % j
		s.mesh = _box(STREET_W, 0.05, GRID_H * BLOCK)
		s.mesh.surface_set_material(0, asphalt)
		s.position = Vector3(GRID_W * BLOCK / 2.0, 0.03, j * BLOCK)
		add_child(s)

## 每个街区中央放 1~4 栋建筑
func _build_buildings() -> void:
	var colors := [
		Color(0.55, 0.5, 0.45), Color(0.5, 0.55, 0.6), Color(0.6, 0.55, 0.5),
		Color(0.48, 0.45, 0.52), Color(0.58, 0.58, 0.55), Color(0.52, 0.5, 0.48),
	]
	for i in range(GRID_W):
		for j in range(GRID_H):
			# 街区中心（街道网格的交叉格子中心）
			var cx := (i + 0.5) * BLOCK
			var cz := (j + 0.5) * BLOCK
			# 每格 1~3 栋
			var n := rng.randi_range(1, 3)
			for k in range(n):
				var bw := rng.randf_range(6.0, 14.0)
				var bd := rng.randf_range(6.0, 14.0)
				var bh := rng.randf_range(8.0, BUILDING_MAX_H)
				var b := MeshInstance3D.new()
				b.name = "Building_%d_%d_%d" % [i, j, k]
				b.mesh = _box(bw, bh, bd)
				var mat := StandardMaterial3D.new()
				mat.albedo_color = colors[rng.randi_range(0, colors.size() - 1)]
				mat.roughness = 0.9
				b.mesh.surface_set_material(0, mat)
				# 街区内的随机偏移（避开街道）
				var ox := rng.randf_range(-(BLOCK / 2.0 - STREET_W / 2.0 - bw / 2.0), BLOCK / 2.0 - STREET_W / 2.0 - bw / 2.0)
				var oz := rng.randf_range(-(BLOCK / 2.0 - STREET_W / 2.0 - bd / 2.0), BLOCK / 2.0 - STREET_W / 2.0 - bd / 2.0)
				b.position = Vector3(cx + ox, bh / 2.0, cz + oz)
				add_child(b)
				# 楼体碰撞
				var body := StaticBody3D.new()
				body.name = b.name + "_body"
				var shape := BoxShape3D.new()
				shape.size = Vector3(bw, bh, bd)
				var col := CollisionShape3D.new()
				col.shape = shape
				body.add_child(col)
				body.position = b.position
				add_child(body)
				# 窗户（每栋楼随机 0~3 个亮窗面）
				if rng.randf() < 0.6:
					_add_windows(b.position, bw, bd, bh)

## 简单窗户：建筑侧面贴几个发光小方块
func _add_windows(center: Vector3, bw: float, bd: float, bh: float) -> void:
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(1.0, 0.9, 0.5)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.85, 0.4)
	win_mat.emission_energy_multiplier = 1.5
	var w := 1.2
	var h := 1.4
	for side in range(4):
		var n := rng.randi_range(2, 4)
		for k in range(n):
			var wnd := MeshInstance3D.new()
			wnd.mesh = _box(w, h, 0.05)
			wnd.mesh.surface_set_material(0, win_mat)
			var x := center.x
			var z := center.z
			var y := rng.randf_range(2.0, bh - 2.0)
			if side == 0 or side == 1:
				# 南北面
				var zz := (bd / 2.0 + 0.03) * (1.0 if side == 0 else -1.0)
				wnd.position = Vector3(x + rng.randf_range(-bw / 2.0 + 1.0, bw / 2.0 - 1.0), y, z + zz)
			else:
				# 东西面
				var xx := (bw / 2.0 + 0.03) * (1.0 if side == 2 else -1.0)
				wnd.position = Vector3(x + xx, y, z + rng.randf_range(-bd / 2.0 + 1.0, bd / 2.0 - 1.0))
			add_child(wnd)

## 街灯：沿街道交叉口放几根
func _build_streetlights() -> void:
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.25, 0.25, 0.28)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1.0, 0.95, 0.7)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.9, 0.6)
	glow_mat.emission_energy_multiplier = 2.0
	for i in range(0, GRID_W, 2):
		for j in range(0, GRID_H, 2):
			var x := float(i) * BLOCK
			var z := float(j) * BLOCK
			# 灯柱
			var pole := MeshInstance3D.new()
			pole.name = "Lamp_%d_%d" % [i, j]
			pole.mesh = _cylinder(0.15, 5.0)
			pole.mesh.surface_set_material(0, pole_mat)
			pole.position = Vector3(x, 2.5, z)
			add_child(pole)
			# 灯头（发光方块）
			var head := MeshInstance3D.new()
			head.name = "LampHead_%d_%d" % [i, j]
			head.mesh = _box(0.8, 0.15, 0.4)
			head.mesh.surface_set_material(0, glow_mat)
			head.position = Vector3(x, 5.1, z)
			add_child(head)
			# 路灯 OmniLight
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.9, 0.6)
			light.light_energy = 2.0
			light.omni_range = 12.0
			light.position = Vector3(x, 5.2, z)
			add_child(light)

func _box(w: float, h: float, d: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(w, h, d)
	return m

func _cylinder(radius: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	return m

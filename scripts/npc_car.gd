extends CharacterBody3D
## NPC 车辆：沿街道网格行驶，路口随机转向，前方有障碍（玩家车/其他车）时减速。
## 城市网格约定（与 city.gd 一致）：
##   - 横街在 x = i*BLOCK（沿 Z 延伸），纵街在 z = j*BLOCK（沿 X 延伸）
##   - 城市范围 [0, GRID_W*BLOCK] x [0, GRID_H*BLOCK]

const BLOCK := 20.0
const STREET_W := 12.0
const GRID_W := 12
const GRID_H := 12
const CRUISE := 10.0       # 巡航速度
const SLOW := 3.0          # 接近障碍时的速度
const STOP_DIST := 8.0     # 检测前方障碍的距离
const TURN_CHANCE := 0.4   # 路口转向概率

var dir := Vector3.FORWARD   # 当前行进方向（单位向量，仅 X/Z）
var speed := 0.0
var at_intersection := false
var last_intersection := Vector3.ZERO

func _ready() -> void:
	_build_mesh()
	# 随机初始方向：四选一
	var dirs := [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	dir = dirs[randi() % dirs.size()]
	_face_dir()
	add_to_group("npc_cars")

## 让车身朝向行进方向（dir 只含 X/Z）
func _face_dir() -> void:
	var yaw := atan2(dir.x, -dir.z)
	rotation.y = yaw

func _physics_process(delta: float) -> void:
	_handle_intersection()
	_avoid_obstacles(delta)
	velocity = dir * speed
	move_and_slide()
	# 撞到东西时大幅减速（模拟撞车）
	if get_slide_collision_count() > 0:
		speed *= 0.5

## 检测是否正接近交叉点，随机决定直行/转向
func _handle_intersection() -> void:
	var ix := roundf(global_position.x / BLOCK)
	var iz := roundf(global_position.z / BLOCK)
	var center := Vector3(ix * BLOCK, 0, iz * BLOCK)
	if center.distance_to(Vector3(global_position.x, 0, global_position.z)) < 2.0:
		if not at_intersection:
			at_intersection = true
			if randf() < TURN_CHANCE:
				# 转向：左右随机 90 度
				var sign := 1.0 if randf() < 0.5 else -1.0
				dir = dir.rotated(Vector3.UP, PI / 2.0 * sign).normalized()
				_face_dir()
		last_intersection = center
	else:
		at_intersection = false

## 前方检测：玩家车 + NPC 车都算障碍；红灯路口停车
func _avoid_obstacles(delta: float) -> void:
	var target := CRUISE
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		global_position + dir * STOP_DIST + Vector3.UP * 0.5
	)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit:
		target = SLOW
	# 红灯：接近灯控路口时完全停车
	var grid := Vector2i(roundi(global_position.x / BLOCK), roundi(global_position.z / BLOCK))
	var center := Vector3(grid.x * BLOCK, 0, grid.y * BLOCK)
	var dist := Vector2(global_position.x - center.x, global_position.z - center.z).length()
	if TrafficManager.is_red(grid) and dist < 12.0 and dist > 2.5:
		target = 0.0
	speed = move_toward(speed, target, 10.0 * delta)

## 车身：简单盒子 + 4 轮（不同颜色区分）
func _build_mesh() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(randf(), randf(), randf()).lerp(Color(0.6, 0.6, 0.6), 0.4)
	body_mat.roughness = 0.4
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.08, 0.08, 0.08)

	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = _box(2.0, 0.6, 4.2)
	body.mesh.surface_set_material(0, body_mat)
	body.position = Vector3(0, 0.65, 0)
	add_child(body)

	for i in range(4):
		var w := MeshInstance3D.new()
		w.name = "Wheel%d" % i
		w.mesh = _cylinder(0.35, 0.3)
		w.mesh.surface_set_material(0, wheel_mat)
		var fx := 1.0 if i % 2 == 0 else -1.0
		var fz := 1.3 if i < 2 else -1.3
		w.position = Vector3(fx * 0.9, 0.35, fz)
		add_child(w)

	# 碰撞形状
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 0.8, 4.2)
	col.shape = shape
	col.position = Vector3(0, 0.7, 0)
	add_child(col)

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

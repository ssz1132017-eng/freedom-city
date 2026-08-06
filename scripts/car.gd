extends CharacterBody3D
## 可驾驶车辆：WASD 加速/转向，第三人称跟随相机。
## 简单物理：速度、转向、摩擦力、碰撞反弹。

# 车辆参数
const MAX_SPEED := 25.0      # 米/秒
const ACCEL := 12.0          # 加速
const BRAKE := 20.0          # 刹车/倒车减速
const TURN_SPEED := 2.2      # 转向速度（弧度/秒）
const FRICTION := 4.0        # 自然减速
const CAM_DIST := 9.0        # 相机距离
const CAM_HEIGHT := 3.5      # 相机高度

var speed := 0.0
var camera: Camera3D
var body_mesh: MeshInstance3D
var wheels: Array[MeshInstance3D] = []

func _ready() -> void:
	_build_car_mesh()
	_build_camera()

## 生成车身：底盘 + 车顶 + 4 个轮子 + 车灯
func _build_car_mesh() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.75, 0.15, 0.1)  # 红色
	body_mat.roughness = 0.35
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.2, 0.3, 0.4)
	glass_mat.metallic = 0.6
	glass_mat.roughness = 0.15
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.08, 0.08, 0.08)

	# 底盘
	body_mesh = MeshInstance3D.new()
	body_mesh.name = "Body"
	body_mesh.mesh = _box(2.2, 0.7, 4.6)
	body_mesh.mesh.surface_set_material(0, body_mat)
	body_mesh.position = Vector3(0, 0.7, 0)
	add_child(body_mesh)

	# 驾驶舱（玻璃）
	var cabin := MeshInstance3D.new()
	cabin.name = "Cabin"
	cabin.mesh = _box(1.8, 0.55, 2.2)
	cabin.mesh.surface_set_material(0, glass_mat)
	cabin.position = Vector3(0, 1.35, -0.3)
	add_child(cabin)

	# 前灯（发光）
	for side in [-1.0, 1.0]:
		var hl := MeshInstance3D.new()
		hl.name = "Headlight%s" % ("L" if side < 0 else "R")
		hl.mesh = _box(0.5, 0.2, 0.08)
		var hl_mat := StandardMaterial3D.new()
		hl_mat.albedo_color = Color(1.0, 0.95, 0.7)
		hl_mat.emission_enabled = true
		hl_mat.emission = Color(1.0, 0.9, 0.5)
		hl_mat.emission_energy_multiplier = 2.0
		hl.mesh.surface_set_material(0, hl_mat)
		hl.position = Vector3(side * 0.8, 0.7, 2.32)
		add_child(hl)

	# 四个轮子
	for i in range(4):
		var w := MeshInstance3D.new()
		w.name = "Wheel%d" % i
		w.mesh = _cylinder(0.4, 0.35)
		w.mesh.surface_set_material(0, wheel_mat)
		var fx := 1.0 if i % 2 == 0 else -1.0
		var fz := 1.4 if i < 2 else -1.4
		w.position = Vector3(fx * 1.0, 0.4, fz)
		add_child(w)
		wheels.append(w)

## 第三人称跟随相机
func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.fov = 70.0
	add_child(camera)
	camera.current = true

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_apply_movement(delta)
	_update_camera()

func _handle_input(delta: float) -> void:
	var fwd := Input.get_axis("backward", "forward")   # 前进/后退
	var turn := Input.get_axis("steer_right", "steer_left")  # 转向

	if fwd > 0:
		speed = move_toward(speed, MAX_SPEED, ACCEL * delta)
	elif fwd < 0:
		speed = move_toward(speed, -MAX_SPEED * 0.5, BRAKE * delta)
	else:
		# 松开按键：自然减速到 0
		speed = move_toward(speed, 0.0, FRICTION * delta)

	# 转向：速度越快转向越有效，倒车反向
	if absf(speed) > 0.5:
		var dir := 1.0 if speed >= 0 else -1.0
		rotate_y(-turn * TURN_SPEED * dir * clampf(absf(speed) / MAX_SPEED, 0.3, 1.0) * delta)

func _apply_movement(delta: float) -> void:
	# 前进方向 = 车头方向（-Z 是 Godot 的前方）
	var forward := -global_transform.basis.z
	var vel := forward * speed
	# 保持在地面高度
	vel.y = 0
	velocity = vel
	move_and_slide()

	# 碰撞后速度衰减（撞楼）
	if get_slide_collision_count() > 0:
		speed *= 0.6

	# 让轮子转起来（视觉）
	for w in wheels:
		w.rotate_x(-speed * delta / 0.4)

func _update_camera() -> void:
	var cam_pos := global_position - global_transform.basis.z * CAM_DIST + Vector3.UP * CAM_HEIGHT
	camera.global_position = cam_pos
	camera.look_at(global_position + Vector3.UP * 1.0)

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

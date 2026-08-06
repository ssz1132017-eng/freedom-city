extends CharacterBody3D
## 行人：在街区边缘的人行道上来回走动，走到尽头随机折返。
## 简单身体：胶囊（躯干）+ 球（头）。

const WALK_SPEED := 1.6
const WANDER_RANGE := 30.0   # 单程走的距离

var walk_dir := 1.0
var walked := 0.0

func _ready() -> void:
	_build_body()
	# 随机朝向：面向 X 或 -X（沿街道走）
	if randi() % 2 == 0:
		rotate_y(PI / 2.0)  # 面向 X
	add_to_group("pedestrians")

func _physics_process(delta: float) -> void:
	var forward := -global_transform.basis.z
	velocity = forward * (WALK_SPEED * walk_dir)
	move_and_slide()
	walked += WALK_SPEED * delta
	# 走够距离就掉头；超出城市范围也掉头
	if walked >= WANDER_RANGE or global_position.x < 3.0 or global_position.x > 12.0 * 20.0 - 3.0:
		walked = 0.0
		walk_dir *= -1.0
		rotate_y(PI)

func _build_body() -> void:
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.85, 0.7, 0.6)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(randf() * 0.6 + 0.2, randf() * 0.6 + 0.2, randf() * 0.6 + 0.2)

	# 躯干（胶囊）
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	torso.mesh = CapsuleMesh.new()
	(torso.mesh as CapsuleMesh).radius = 0.22
	(torso.mesh as CapsuleMesh).height = 1.3
	torso.mesh.surface_set_material(0, cloth)
	torso.position = Vector3(0, 0.8, 0)
	add_child(torso)

	# 头（球）
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.mesh = SphereMesh.new()
	(head.mesh as SphereMesh).radius = 0.17
	(head.mesh as SphereMesh).height = 0.34
	head.mesh.surface_set_material(0, skin)
	head.position = Vector3(0, 1.65, 0)
	add_child(head)

	# 碰撞
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.6
	col.shape = shape
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

extends Node3D
## 路口红绿灯：绿 -> 黄 -> 红 循环，带相位偏移避免全城同步。
## 视觉：灯柱 + 三色灯头（当前状态发光）。

const CYCLE := 14.0      # 完整周期（秒）
const GREEN_T := 7.0     # 绿灯持续到
const YELLOW_T := 10.0   # 黄灯持续到（之后是红灯）

var phase := 0.0
var grid := Vector2i.ZERO
var red_lamp: MeshInstance3D
var yellow_lamp: MeshInstance3D
var green_lamp: MeshInstance3D
var red_mat: StandardMaterial3D
var yellow_mat: StandardMaterial3D
var green_mat: StandardMaterial3D

func _ready() -> void:
	# 随机相位：各路口不同步
	phase = randf() * CYCLE
	_build()
	TrafficManager.register_light(grid, self)

func _process(delta: float) -> void:
	phase = fmod(phase + delta, CYCLE)
	_update_lamps()

## 当前状态：green / yellow / red
func state() -> String:
	if phase < GREEN_T:
		return "green"
	if phase < YELLOW_T:
		return "yellow"
	return "red"

func is_red() -> bool:
	return state() == "red"

## 灯柱 + 三个灯头
func _build() -> void:
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.2, 0.2, 0.22)
	var housing_mat := StandardMaterial3D.new()
	housing_mat.albedo_color = Color(0.15, 0.15, 0.17)

	# 灯柱
	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	pole.mesh = _cylinder(0.12, 4.2)
	pole.mesh.surface_set_material(0, pole_mat)
	pole.position = Vector3(0, 2.1, 0)
	add_child(pole)

	# 灯头外壳
	var housing := MeshInstance3D.new()
	housing.name = "Housing"
	housing.mesh = _box(0.9, 1.6, 0.35)
	housing.mesh.surface_set_material(0, housing_mat)
	housing.position = Vector3(0, 4.4, 0)
	add_child(housing)

	# 三个灯
	red_mat = _lamp_mat(Color(0.9, 0.15, 0.15))
	yellow_mat = _lamp_mat(Color(0.95, 0.8, 0.15))
	green_mat = _lamp_mat(Color(0.15, 0.85, 0.2))
	red_lamp = _lamp(Vector3(0, 4.9, 0.2), red_mat, "RedLamp")
	yellow_lamp = _lamp(Vector3(0, 4.4, 0.2), yellow_mat, "YellowLamp")
	green_lamp = _lamp(Vector3(0, 3.9, 0.2), green_mat, "GreenLamp")
	_update_lamps()

func _lamp_mat(base: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base.darkened(0.7)
	m.emission_enabled = true
	m.emission = base
	m.emission_energy_multiplier = 0.3
	return m

func _lamp(pos: Vector3, mat: StandardMaterial3D, name: String) -> MeshInstance3D:
	var l := MeshInstance3D.new()
	l.name = name
	l.mesh = _box(0.55, 0.4, 0.12)
	l.mesh.surface_set_material(0, mat)
	l.position = pos
	add_child(l)
	return l

func _update_lamps() -> void:
	var s := state()
	_set_glow(red_lamp, red_mat, s == "red")
	_set_glow(yellow_lamp, yellow_mat, s == "yellow")
	_set_glow(green_lamp, green_mat, s == "green")

func _set_glow(lamp: MeshInstance3D, mat: StandardMaterial3D, on: bool) -> void:
	if on:
		mat.emission_energy_multiplier = 2.5
	else:
		mat.emission_energy_multiplier = 0.3

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

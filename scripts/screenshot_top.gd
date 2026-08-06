extends Node
## 临时俯视截图：SCREENSHOT=top 时启用。
## 把相机抬到高空俯拍城市全景，截图后退出。

const SHOT_AFTER := 60
var frame := 0

func _process(_delta: float) -> void:
	if OS.get_environment("SCREENSHOT") != "top":
		return
	frame += 1
	if frame == 10:
		# 找到一个相机来复用视口渲染；没有就建一个临时相机
		var cam := Camera3D.new()
		cam.name = "TopCam"
		cam.position = Vector3(120, 120, 120)
		cam.look_at(Vector3(120, 0, 120))
		cam.fov = 60.0
		cam.current = true
		get_tree().current_scene.add_child(cam)
	if frame == SHOT_AFTER:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://screenshot_top.png")
		print("TOP SCREENSHOT SAVED")
		get_tree().quit()

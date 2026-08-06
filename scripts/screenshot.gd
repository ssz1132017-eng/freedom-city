extends Node
## 临时截图脚本：仅在环境变量 SCREENSHOT=1 时生效。
## 运行几帧让场景/灯光稳定后截图并退出，不影响正常游戏。

const SHOT_AFTER := 45   # 等待帧数（让相机、灯光、NPC 就位）
var frame := 0

func _process(_delta: float) -> void:
	if OS.get_environment("SCREENSHOT") != "1":
		return
	frame += 1
	if frame == SHOT_AFTER:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://screenshot.png")
		print("SCREENSHOT SAVED: res://screenshot.png")
		get_tree().quit()

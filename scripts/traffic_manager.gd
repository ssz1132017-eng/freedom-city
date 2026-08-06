extends Node
## 全局交通灯管理单例（autoload: TrafficManager）。
## NPC 车通过 TrafficManager.is_red(grid) 查询路口信号灯状态。

var lights := {}  # Vector2i -> Node（traffic_light 实例）

func register_light(grid: Vector2i, light: Node) -> void:
	lights[grid] = light

## 查询某路口是否红灯；无灯的路口返回 false（可通行）
func is_red(grid: Vector2i) -> bool:
	var l: Node = lights.get(grid)
	return l != null and l.is_red()

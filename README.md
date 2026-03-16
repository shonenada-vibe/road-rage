# Road Rage Relief

一个使用 Godot 4 开发的 2D 原型：玩家驾驶车辆穿过一条非常繁忙的城市道路，既可以选择守规则抵达终点，也可以把一路上的怒气转成夸张的碰撞反馈。

## 当前原型内容

- 顶视角 2D 驾驶，支持方向键和 `WASD`
- 主菜单场景，支持开始和退出
- 三组红绿灯，闯红灯会扣守规则分
- 违停车辆、电动车、行人三类障碍
- AI 机动车流，包含同向慢车和对向来车
- 程序化音效：引擎声、环境噪声、碰撞声、菜单确认、通关提示
- 自定义粒子爆裂和轮胎滑移尘雾
- 更强的撞飞/滑飞反馈、镜头震动和玩家反冲
- 双分数系统
  - `守规则`：超速、压上人行/非机动车区域、闯红灯会扣分
  - `混乱`：撞击障碍物会增加
- 抵达终点后给出风格化结算

## 目录结构

- `project.godot`: Godot 项目配置
- `scenes/menu.tscn`: 菜单入口
- `scenes/main.tscn`: 游戏场景
- `scripts/main.gd`: 世界搭建、HUD、规则判定、结算
- `scripts/player_car.gd`: 玩家车辆控制与碰撞
- `scripts/traffic_actor.gd`: 行人、电动车、违停车辆逻辑
- `scripts/traffic_light.gd`: 红绿灯循环与绘制
- `scripts/ai_vehicle.gd`: AI 机动车流
- `scripts/audio_lab.gd`: 程序化音效
- `scripts/fx_manager.gd`: 粒子/特效调度
- `scripts/particle_burst.gd`: 自定义 2D 粒子爆裂
- `scripts/menu.gd`: 主菜单 UI

## 运行方式

1. 用 Godot 4 打开本目录。
2. 载入 `project.godot`。
3. 运行主菜单，点击“开始上路”。

## 可继续扩展的方向

- 为 AI 机动车流增加跟车、变道和事故链反应
- 把道路切成多个主题路段，加入学校、商圈、施工区
- 为行人和电动车增加更细的状态机
- 使用 `RigidBody2D` 做更真实的碰撞二次反应
- 替换程序化音效/粒子为正式美术与音频资源

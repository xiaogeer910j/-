# 自由修仙录

这是一个使用 Godot 4 制作的 2D 单机修仙原型。当前版本支持自由移动、采集灵草、修炼、突破、游商交易和妖兽战斗，并包含 iOS Safari 触屏操作。

## 本地运行

```bash
godot4 --editor --path .
```

## 检查和测试

```bash
godot4 --headless --path . --editor --quit
godot4 --headless --path . --script res://tests/smoke.gd
```

## 生成 iOS Safari 在线试玩包

```bash
./tools/install_web_template.sh
./tools/build_web.sh
```

构建结果在 `build/web/`。这个目录会由 GitHub Pages 工作流发布，iPhone 或 iPad 使用 Safari 打开 Pages 地址即可试玩。

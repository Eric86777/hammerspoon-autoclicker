# 🎫 大麦抢票神器 v2.0 - 智能学习版

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos/)
[![Hammerspoon](https://img.shields.io/badge/Hammerspoon-0.9.100+-green.svg)](http://www.hammerspoon.org/)

专为 macOS + iPhone 镜像优化的高速抢票脚本，支持实时坐标学习和智能错误处理。

## ✨ 核心特性

- 🚀 **高速点击**：支持每秒 20 次的疯狂点击模式
- 🧠 **智能学习**：实时学习错误按钮位置，自动处理各种弹窗
- 🔄 **自动重置**：每次加载自动清理旧状态，确保稳定运行
- 📱 **iPhone 镜像优化**：专门针对 iPhone 镜像窗口优化点击事件
- ⚡ **快捷键操作**：全程快捷键控制，无需触碰鼠标

## 🆕 v2.0 更新内容

### 清除重置版改进
- **完整清理机制**：每次加载脚本时自动清理所有旧状态
- **全局状态管理**：使用 `_G.damaiGrabber` 统一管理定时器、事件和快捷键
- **双重垃圾回收**：确保内存彻底释放，避免状态污染
- **事件同步管理**：鼠标事件同时保存到局部和全局容器
- **解决鼠标锁定问题**：通过彻底清理避免鼠标被锁定的情况

## 📋 系统要求

- macOS 10.12 或更高版本
- [Hammerspoon](http://www.hammerspoon.org/) 0.9.100 或更高版本
- iPhone 镜像功能（通过 QuickTime Player 或其他镜像软件）

## 🛠️ 安装步骤

1. **安装 Hammerspoon**
   ```bash
   brew install --cask hammerspoon
   ```
   或从[官网](http://www.hammerspoon.org/)下载

2. **下载脚本**
   ```bash
   git clone https://github.com/yourusername/damai-ticket-grabber.git
   cd damai-ticket-grabber
   ```

3. **配置 Hammerspoon**
   - 将 `damai_ticket_grabber_qingchu.lua` 复制到 `~/.hammerspoon/` 目录
   - 在 `~/.hammerspoon/init.lua` 中添加：
     ```lua
     require("damai_ticket_grabber_qingchu")
     ```

4. **重新加载配置**
   - 点击菜单栏的 Hammerspoon 图标
   - 选择 "Reload Config"

## 🎮 使用方法

### 快捷键说明

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Option + R` | 记录主按钮位置 | 将鼠标移到"提交订单"按钮上按此键 |
| `Option + E` | 记录错误按钮位置 | 遇到错误弹窗时，将鼠标移到"确定"按钮上按此键 |
| `Option + G` | 开始抢票 | 开始自动点击 |
| `Option + S` | 停止抢票 | 手动停止 |
| `Option + Q` | 紧急停止 | 立即停止所有操作 |
| `Option + I` | 显示状态 | 查看当前配置和运行状态 |
| `Option + D` | 切换调试模式 | 开启/关闭详细日志 |

### 使用流程

1. **准备工作**
   - 打开大麦 App 的 iPhone 镜像
   - 进入抢票页面，等待开抢

2. **记录按钮位置**
   - 将鼠标移到"提交订单"或"立即预订"按钮上
   - 按 `Option + R` 记录位置

3. **开始抢票**
   - 按 `Option + G` 开始自动点击
   - 脚本会以每秒 20 次的速度点击

4. **智能学习**
   - 遇到错误弹窗时，手动点击处理
   - 然后将鼠标移到错误按钮上，按 `Option + E`
   - 脚本会自动学习并处理后续相同错误

5. **停止抢票**
   - 成功进入支付页面后，按 `Option + S` 停止
   - 紧急情况按 `Option + Q` 立即停止

## ⚠️ 注意事项

1. **首次使用**可能需要在系统偏好设置中授予 Hammerspoon 辅助功能权限
2. **点击速度**可在脚本中调整 `clickInterval` 参数（默认 0.05 秒）
3. **最大运行时间**默认 10 分钟，可通过 `maxRunTime` 参数调整
4. 使用时请遵守平台规则，本工具仅供学习交流使用

## 🐛 常见问题

### Q: 鼠标被锁定无法移动？
A: 这是旧版本的已知问题，清除重置版已经解决。如仍有问题，请按 `Option + Q` 紧急停止，然后重新加载脚本。

### Q: 点击没有反应？
A: 
1. 确保已正确记录按钮位置（Option + R）
2. 检查 Hammerspoon 是否有辅助功能权限
3. 尝试重新加载脚本

### Q: 如何调整点击速度？
A: 修改脚本中的 `clickInterval` 值：
- `0.05` = 20次/秒（默认）
- `0.1` = 10次/秒
- `0.02` = 50次/秒（极限速度）

## 📝 更新日志

### v2.0.1 - 清除重置版 (2024-01-XX)
- 🔧 修复鼠标锁定问题
- ✨ 添加完整的脚本加载清理机制
- 🚀 优化事件对象管理
- 📦 统一使用全局容器管理资源

### v2.0.0 - 智能学习版 (2024-01-XX)
- 🧠 新增实时坐标学习功能
- ⚡ 优化点击性能
- 🛡️ 添加错误处理机制

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## ⚖️ 免责声明

本工具仅供学习和研究使用，请勿用于商业用途。使用本工具进行抢票时，请遵守相关平台的使用条款和法律法规。因使用本工具产生的任何问题，作者不承担任何责任。

---

Made with ❤️ by Eric & AI Assistant
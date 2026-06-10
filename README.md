# OneLife ⏳ — Make Time Count

把余生变成动力的倒计时 App。设定出生日期与预期寿命，OneLife 实时倒数你拥有的每一秒，提醒你：时间有限，去做让你快乐和有意义的事。

> App Store 名称：**OneLife - Make Time Count** · iOS 16+ / watchOS 9+

## 功能

- **实时倒计时**：彩虹渐变大数字按 0.1 秒跳动，年/天/时/分/秒拆分，人生进度条
- **每日打卡**：每天记录一件最开心或最有意义的事，连续打卡统计
- **分享海报**：任意一条记录一键生成渐变海报（两种样式），分享或存相册
- **五种主题**：深色 / 浅色 / 流动渐变 / 照片轮播（最多 9 张自动切换）/ 醒目红恐惧模式
- **睡前提醒**：每晚定时提醒打卡，当天已记录则自动静默
- **锁屏 & 主屏小组件**：iOS 16 锁屏组件 + 桌面小组件，随时可见
- **Apple Watch**：独立表盘 App + 四种表盘复杂功能，抬腕即见；设置自动从 iPhone 同步

## 技术架构

- **SwiftUI** 全家桶：TimelineView 驱动实时刷新、WidgetKit 小组件、ImageRenderer 生成海报、WatchConnectivity 同步手表
- **XcodeGen**：`project.yml` 生成 Xcode 工程，`.xcodeproj` 不入库
- **零本地 Xcode 开发**：全部构建、签名、上传都在 GitHub Actions（macos runner）完成，开发机是 Windows

```
DeadClock/            iOS 主 App（倒计时、打卡、海报、主题、提醒）
DeadClock/Shared/     与各 target 共享的模型（DeathClock、JournalStore）
DeadClockWidget/      iOS 锁屏/主屏小组件
DeadClockWatch/       watchOS App
DeadClockWatchWidget/ watchOS 表盘复杂功能
.github/workflows/    ci.yml（模拟器构建+截图） testflight.yml（签名+上传）
```

## CI / 发布流程

1. push 任意分支 → **CI**：模拟器构建 + 启动截图（artifact 可下载预览 UI）
2. push `main` → **TestFlight**：云签名（ASC API Key）→ Archive → 上传，构建号 = run_number + 100
3. Apple 处理 5-15 分钟后，TestFlight 即可安装

需要的仓库 Secrets：`APP_STORE_CONNECT_API_KEY_P8` / `_KEY_ID` / `_ISSUER_ID`（Admin 角色）。

## 本地开发（可选，需 Mac）

```bash
brew install xcodegen
xcodegen generate
open DeadClock.xcodeproj
```

---

🤖 Built with [Claude Code](https://claude.com/claude-code)

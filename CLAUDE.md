# CLAUDE.md

OneLife（死亡倒计时 App）。Windows 开发，无本地 Xcode，一切构建签名走 GitHub Actions。

## 关键值

- Repo：`rjxznb/dead-clock`（public，免费 macOS Actions）
- Bundle ID：`com.rjxznb.deadclock`（+ `.widget` / `.watchkitapp` / `.watchkitapp.widget`）
- App Group：`group.com.rjxznb.deadclock`（所有 target 共享数据）
- Team ID：`Q3BK52FQT9`；ASC App ID：6778642991
- TestFlight 构建号 = GitHub run_number + 100

## 工作方式

- 改完代码 `git push` 即发布：CI（~4min 模拟器+截图 artifact）、TestFlight（~10min，仅 main）
- 验证 UI：下载 CI 的 screenshots artifact 查看
- `xcodegen` 由 CI 执行，本地不需要；`.xcodeproj` 不入库，工程结构全在 `project.yml`

## 产品基调

定位是**正向激励**（珍惜时间、记录美好），默认文案和配色避免恐怖感；"醒目红"主题（`AppTheme.red / isFearMode`）是唯一允许恐惧措辞的地方。

## 踩过的坑（勿重蹈）

- `.p8` 推 GitHub Secret 必须用 bash `<` 重定向；PowerShell 管道会损坏编码（CryptoKit invalidPEMDocument）
- 竖屏-only 必须 `UIRequiresFullScreen: true`，否则 ITMS-90474 拒收
- ITMS 错误在 altool 上传成功**之后**经邮件异步到达；altool 日志中的临时 `ERROR:`（如 HTTP 500 重试）不代表失败，以 `UPLOAD SUCCEEDED` 为准
- 新增 target 的 Bundle ID 需在开发者后台手动注册并关联 App Group，云签名自动注册不可靠（报误导性的 bearer token 错误）
- 用户网络到 GitHub 偶发 SSL 中断：git push / gh api 一律带重试
- 图标必须 1024×1024 RGB 无 alpha
- 纯文档提交用 `[skip ci]` 避免浪费构建

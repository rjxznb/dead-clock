import SwiftUI

@main
struct DeadClockMacApp: App {
    init() {
        // 截图流水线：渲染 App Store 用的 2880x1800 营销图后退出
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--render-screenshot"), i + 1 < args.count {
            let renderer = ImageRenderer(content: MacScreenshotView())
            renderer.scale = 2
            if let img = renderer.nsImage,
               let tiff = img.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: args[i + 1]))
            }
            exit(0)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MacCountdownView()
        } label: {
            MacMenuLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

/// App Store macOS 截图：渐变背景 + 居中的菜单栏弹窗卡片
struct MacScreenshotView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.25),
                    Color(red: 0.45, green: 0.13, blue: 0.32),
                    Color(red: 0.91, green: 0.45, blue: 0.25),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 28) {
                Text("⏳ OneLife")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(.white)
                MacCountdownView()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.35), radius: 30, y: 14)
            }
        }
        .frame(width: 1440, height: 900)
    }
}

/// 菜单栏常驻标签：⏳ + 剩余天数（每小时刷新一次足够）
struct MacMenuLabel: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 3600)) { context in
            Text(String(format: NSLocalizedString("mac.menubar.format", comment: ""),
                        DeathClock.remainingDays(at: context.date)))
        }
    }
}

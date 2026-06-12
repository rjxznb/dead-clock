import SwiftUI

@main
struct DeadClockMacApp: App {
    init() {
        // 截图流水线：渲染 App Store 用的 2880x1800 营销图后退出
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--render-screenshot"), i + 1 < args.count {
            var variant = 1
            if let v = args.firstIndex(of: "--shot-style"), v + 1 < args.count {
                variant = Int(args[v + 1]) ?? 1
            }
            let renderer = ImageRenderer(content: MacScreenshotView(variant: variant))
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

/// App Store macOS 截图：纯 SwiftUI 绘制（ImageRenderer 渲染不了 AppKit 原生控件，
/// 所以不能直接用 MacCountdownView 里的 DatePicker/Stepper）
struct MacScreenshotView: View {
    var variant: Int = 1

    private var bgColors: [Color] {
        switch variant {
        case 2:
            return [
                Color(red: 0.04, green: 0.07, blue: 0.20),
                Color(red: 0.08, green: 0.22, blue: 0.42),
                Color(red: 0.05, green: 0.45, blue: 0.50),
            ]
        case 3:
            return [
                Color(red: 0.16, green: 0.05, blue: 0.25),
                Color(red: 0.55, green: 0.10, blue: 0.45),
                Color(red: 0.95, green: 0.35, blue: 0.45),
            ]
        default:
            return [
                Color(red: 0.10, green: 0.08, blue: 0.25),
                Color(red: 0.45, green: 0.13, blue: 0.32),
                Color(red: 0.91, green: 0.45, blue: 0.25),
            ]
        }
    }

    private var titleKey: LocalizedStringKey {
        switch variant {
        case 2: return "mac.shot.title2"
        case 3: return "mac.shot.title3"
        default: return "mac.shot.title"
        }
    }

    private var subtitleKey: LocalizedStringKey {
        switch variant {
        case 2: return "mac.shot.subtitle2"
        case 3: return "mac.shot.subtitle3"
        default: return "mac.shot.subtitle"
        }
    }

    private let rainbow = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.42, blue: 0.62),
            Color(red: 1.00, green: 0.62, blue: 0.26),
            Color(red: 1.00, green: 0.79, blue: 0.34),
            Color(red: 0.18, green: 0.80, blue: 0.44),
            Color(red: 0.00, green: 0.82, blue: 0.83),
            Color(red: 0.65, green: 0.37, blue: 0.92),
        ],
        startPoint: .leading, endPoint: .trailing)

    private static let secondsFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 1
        return f
    }()

    var body: some View {
        let now = Date()
        let days = DeathClock.remainingDays(at: now)
        let remaining = DeathClock.remainingSeconds(at: now)
        let progress = DeathClock.lifeProgress(at: now)

        ZStack(alignment: .top) {
            LinearGradient(colors: bgColors, startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 0) {
                // 菜单栏（模拟）
                HStack(spacing: 14) {
                    Text("OneLife")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Text("⏳ \(days) \(String(localized: "mac.shot.days"))")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.25),
                                    in: RoundedRectangle(cornerRadius: 5))
                    Text("9:41")
                        .font(.system(size: 13))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 32)
                .background(Color.black.opacity(0.28))

                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(titleKey)
                            .font(.system(size: 46, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineSpacing(8)
                        Text(subtitleKey)
                            .font(.system(size: 21))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.leading, 90)
                    .padding(.top, 200)

                    Spacer()

                    // 菜单栏弹窗（模拟）
                    VStack(spacing: 14) {
                        Text("headline.normal")
                            .font(.caption)
                            .foregroundStyle(Color(white: 0.65))
                            .tracking(3)
                        Text(Self.secondsFormatter.string(from: NSNumber(value: remaining)) ?? "")
                            .font(.system(size: 27, weight: .heavy, design: .monospaced))
                            .foregroundStyle(rainbow)
                            .lineLimit(1)
                        Text("unit.seconds.caption")
                            .font(.caption2)
                            .foregroundStyle(Color(white: 0.65))

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.15))
                                Capsule()
                                    .fill(rainbow)
                                    .frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 6)

                        Text(String(format: NSLocalizedString("progress.normal", comment: ""),
                                    progress * 100))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color(white: 0.65))
                    }
                    .padding(24)
                    .frame(width: 320)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.14),
                                in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.4), radius: 28, y: 12)
                    .padding(.trailing, 70)
                    .padding(.top, 14)
                }
                Spacer()
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

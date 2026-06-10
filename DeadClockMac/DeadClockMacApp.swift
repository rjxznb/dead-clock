import SwiftUI

@main
struct DeadClockMacApp: App {
    var body: some Scene {
        MenuBarExtra {
            MacCountdownView()
        } label: {
            MacMenuLabel()
        }
        .menuBarExtraStyle(.window)
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

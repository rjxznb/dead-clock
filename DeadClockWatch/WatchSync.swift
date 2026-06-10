import Foundation
import WatchConnectivity
import WidgetKit

/// 接收 iPhone 端同步过来的出生日期/预期寿命。
/// iPhone 通过 updateApplicationContext 推送，手表端落到本地 UserDefaults，
/// 表盘组件读同一份数据。
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    static func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = shared
        WCSession.default.activate()
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        apply(session.receivedApplicationContext)
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    private func apply(_ context: [String: Any]) {
        guard !context.isEmpty else { return }
        if let t = context["birthDate"] as? Double {
            DeathClock.birthDate = Date(timeIntervalSince1970: t)
        }
        if let y = context["lifeExpectancyYears"] as? Double {
            DeathClock.lifeExpectancyYears = y
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

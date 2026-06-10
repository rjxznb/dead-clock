import Foundation
import WatchConnectivity

/// iPhone → Apple Watch 同步出生日期/预期寿命。
/// updateApplicationContext 会持久化，手表下次唤醒也能收到最新值。
enum PhoneSync {
    static func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = Delegate.shared
        WCSession.default.activate()
    }

    static func push() {
        let session = WCSession.default
        guard WCSession.isSupported(), session.activationState == .activated else { return }
        try? session.updateApplicationContext([
            "birthDate": DeathClock.birthDate.timeIntervalSince1970,
            "lifeExpectancyYears": DeathClock.lifeExpectancyYears,
        ])
    }

    final class Delegate: NSObject, WCSessionDelegate {
        static let shared = Delegate()

        func session(_ session: WCSession,
                     activationDidCompleteWith activationState: WCSessionActivationState,
                     error: Error?) {
            DispatchQueue.main.async { PhoneSync.push() }
        }

        func sessionDidBecomeInactive(_ session: WCSession) {}

        func sessionDidDeactivate(_ session: WCSession) {
            session.activate()
        }
    }
}

import Foundation
import UserNotifications

/// 睡前打卡提醒：一次性预排未来 7 天的本地通知。
/// 当天已打卡则跳过当天，所以打卡后当晚不会再被打扰。
/// App 每次启动 / 打卡 / 改设置时调用 reschedule() 续排。
enum ReminderManager {
    private static let enabledKey = "reminderEnabled"
    private static let hourKey = "reminderHour"
    private static let minuteKey = "reminderMinute"

    static var isEnabled: Bool {
        get { DeathClock.defaults.bool(forKey: enabledKey) }
        set { DeathClock.defaults.set(newValue, forKey: enabledKey) }
    }

    static var hour: Int {
        get {
            let v = DeathClock.defaults.object(forKey: hourKey) as? Int
            return v ?? 22
        }
        set { DeathClock.defaults.set(newValue, forKey: hourKey) }
    }

    static var minute: Int {
        get {
            let v = DeathClock.defaults.object(forKey: minuteKey) as? Int
            return v ?? 0
        }
        set { DeathClock.defaults.set(newValue, forKey: minuteKey) }
    }

    static func requestAuthorizationAndEnable(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    isEnabled = granted
                    if granted { reschedule() }
                    completion(granted)
                }
            }
    }

    static func disable() {
        isEnabled = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func reschedule() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard isEnabled else { return }

        let cal = Calendar.current
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: Date()) else { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour
            comps.minute = minute
            guard let fireDate = cal.date(from: comps) else { continue }
            // 今天：已打卡或提醒时间已过则跳过
            if offset == 0 {
                if JournalStore.entry(for: day) != nil { continue }
                if fireDate <= Date() { continue }
            }
            let content = UNMutableNotificationContent()
            content.title = "✨ 记录今天"
            content.body = "今天最让你开心或最有意义的一件事是什么？睡前花 30 秒记下来。"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "checkin-\(JournalStore.dateKey(for: day))",
                content: content,
                trigger: trigger)
            center.add(request)
        }
    }
}

import Foundation

/// 共享的核心模型：主 App 与 Widget 通过 App Group 读写同一份设置。
enum DeathClock {
    static let appGroupID = "group.com.rjxznb.deadclock"

    private static let birthDateKey = "birthDate"
    private static let lifeExpectancyKey = "lifeExpectancyYears"

    /// 一年的平均秒数（格里历 365.2425 天）
    static let secondsPerYear: Double = 365.2425 * 86400

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static var birthDate: Date {
        get {
            let t = defaults.double(forKey: birthDateKey)
            if t != 0 { return Date(timeIntervalSince1970: t) }
            return Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        }
        set { defaults.set(newValue.timeIntervalSince1970, forKey: birthDateKey) }
    }

    /// 预期寿命（岁），默认 78
    static var lifeExpectancyYears: Double {
        get {
            let v = defaults.double(forKey: lifeExpectancyKey)
            return v > 0 ? v : 78
        }
        set { defaults.set(newValue, forKey: lifeExpectancyKey) }
    }

    static var deathDate: Date {
        birthDate.addingTimeInterval(lifeExpectancyYears * secondsPerYear)
    }

    static func remainingSeconds(at now: Date = Date()) -> TimeInterval {
        max(0, deathDate.timeIntervalSince(now))
    }

    /// 人生已度过的比例 0...1
    static func lifeProgress(at now: Date = Date()) -> Double {
        let total = deathDate.timeIntervalSince(birthDate)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(birthDate) / total))
    }

    struct Breakdown {
        let years: Int
        let days: Int
        let hours: Int
        let minutes: Int
        let seconds: Int
    }

    static func breakdown(at now: Date = Date()) -> Breakdown {
        var t = remainingSeconds(at: now)
        let years = Int(t / secondsPerYear)
        t -= Double(years) * secondsPerYear
        let days = Int(t / 86400)
        t -= Double(days) * 86400
        let hours = Int(t / 3600)
        t -= Double(hours) * 3600
        let minutes = Int(t / 60)
        t -= Double(minutes) * 60
        return Breakdown(years: years, days: days, hours: hours, minutes: minutes, seconds: Int(t))
    }

    static func remainingDays(at now: Date = Date()) -> Int {
        Int(remainingSeconds(at: now) / 86400)
    }
}

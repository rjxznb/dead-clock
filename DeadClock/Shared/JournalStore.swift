import Foundation

struct JournalEntry: Codable, Identifiable, Equatable {
    var id: String { dateKey }
    let dateKey: String      // "2026-06-10"
    var text: String
    var updatedAt: Date
}

/// 每日打卡存储：一天一条，记录当天最开心/最有意义的事。
/// 存在 App Group UserDefaults 里，主 App 与 Widget 均可读取。
enum JournalStore {
    private static let storageKey = "journalEntries"

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dateKey(for date: Date) -> String {
        keyFormatter.string(from: date)
    }

    static func date(fromKey key: String) -> Date? {
        keyFormatter.date(from: key)
    }

    /// 按日期倒序（最新在前）
    static func load() -> [JournalEntry] {
        guard let data = DeathClock.defaults.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([JournalEntry].self, from: data)
        else { return [] }
        return entries.sorted { $0.dateKey > $1.dateKey }
    }

    static func entry(for date: Date = Date()) -> JournalEntry? {
        let key = dateKey(for: date)
        return load().first { $0.dateKey == key }
    }

    static func save(text: String, for date: Date = Date()) {
        var entries = load()
        let key = dateKey(for: date)
        if let i = entries.firstIndex(where: { $0.dateKey == key }) {
            entries[i].text = text
            entries[i].updatedAt = Date()
        } else {
            entries.append(JournalEntry(dateKey: key, text: text, updatedAt: Date()))
        }
        persist(entries)
    }

    static func delete(_ entry: JournalEntry) {
        persist(load().filter { $0.dateKey != entry.dateKey })
    }

    private static func persist(_ entries: [JournalEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            DeathClock.defaults.set(data, forKey: storageKey)
        }
    }

    static var totalCount: Int { load().count }

    /// 连续打卡天数（今天没打则从昨天往前数）
    static var streak: Int {
        let keys = Set(load().map(\.dateKey))
        guard !keys.isEmpty else { return 0 }
        var day = Date()
        if !keys.contains(dateKey(for: day)) {
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var count = 0
        while keys.contains(dateKey(for: day)) {
            count += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }
}

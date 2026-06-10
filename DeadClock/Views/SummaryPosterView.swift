import SwiftUI

enum SummaryPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return String(localized: "summary.week")
        case .month: return String(localized: "summary.month")
        case .year: return String(localized: "summary.year")
        }
    }

    var maxExcerpts: Int {
        switch self {
        case .week: return 7
        case .month: return 6
        case .year: return 8
        }
    }

    func dateInterval(now: Date = Date()) -> DateInterval {
        let cal = Calendar.current
        let component: Calendar.Component
        switch self {
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        return cal.dateInterval(of: component, for: now) ?? DateInterval(start: now, duration: 1)
    }

    func label(now: Date = Date()) -> String {
        let interval = dateInterval(now: now)
        switch self {
        case .week:
            let end = min(now, interval.end.addingTimeInterval(-1))
            return "\(interval.start.formatted(.dateTime.month().day())) – \(end.formatted(.dateTime.month().day()))"
        case .month:
            return now.formatted(.dateTime.month(.wide).year())
        case .year:
            return now.formatted(.dateTime.year())
        }
    }
}

struct SummaryStats {
    let label: String
    let entries: [JournalEntry]    // 时间正序
    let excerpts: [JournalEntry]   // 均匀抽样，控制海报高度
    let daysElapsed: Int

    init(period: SummaryPeriod, now: Date = Date()) {
        let interval = period.dateInterval(now: now)
        label = period.label(now: now)

        let inRange = JournalStore.load()
            .compactMap { entry -> (JournalEntry, Date)? in
                guard let d = JournalStore.date(fromKey: entry.dateKey) else { return nil }
                return (entry, d)
            }
            .filter { $0.1 >= interval.start && $0.1 < interval.end }
            .sorted { $0.0.dateKey < $1.0.dateKey }
            .map { $0.0 }
        entries = inRange

        if inRange.count > period.maxExcerpts {
            let step = Double(inRange.count) / Double(period.maxExcerpts)
            excerpts = (0..<period.maxExcerpts).map { inRange[Int(Double($0) * step)] }
        } else {
            excerpts = inRange
        }

        let endSoFar = min(now, interval.end)
        let days = Calendar.current.dateComponents([.day], from: interval.start, to: endSoFar).day ?? 0
        daysElapsed = max(1, days + 1)
    }
}

struct SummaryPosterCard: View {
    let stats: SummaryStats
    let style: PosterStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stats.label)
                    .font(.footnote)
                    .opacity(0.85)
                Text("summary.card.title")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(style == .dark ? AnyShapeStyle(Theme.rainbow) : AnyShapeStyle(.white))
            }

            if stats.entries.isEmpty {
                Text("summary.empty")
                    .font(.subheadline)
                    .opacity(0.9)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(stats.entries.count)")
                        .font(.system(size: 46, weight: .heavy, design: .monospaced))
                        .foregroundStyle(style == .dark ? AnyShapeStyle(Theme.rainbow) : AnyShapeStyle(.white))
                    Text("summary.moments.unit")
                        .font(.subheadline)
                        .opacity(0.9)
                }

                Text(String(format: NSLocalizedString("summary.days.coverage", comment: ""),
                            stats.entries.count, stats.daysElapsed))
                    .font(.footnote)
                    .opacity(0.8)

                Rectangle()
                    .fill(.white.opacity(style == .dark ? 0.15 : 0.3))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(stats.excerpts) { entry in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(shortDate(entry))
                                .font(.caption2.monospacedDigit())
                                .opacity(0.7)
                                .frame(width: 42, alignment: .leading)
                            Text(entry.text)
                                .font(.footnote)
                                .lineLimit(2)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Text("poster.brand")
                    .font(.caption2)
                    .opacity(0.65)
            }
        }
        .foregroundStyle(.white)
        .padding(30)
        .frame(width: 330, alignment: .leading)
        .background(
            style == .gradient
                ? AnyShapeStyle(Theme.posterBackground)
                : AnyShapeStyle(Color(red: 0.05, green: 0.05, blue: 0.07))
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private func shortDate(_ entry: JournalEntry) -> String {
        guard let date = JournalStore.date(fromKey: entry.dateKey) else { return "" }
        return date.formatted(.dateTime.month(.defaultDigits).day())
    }
}

struct SummaryPosterSheet: View {
    let period: SummaryPeriod
    @Environment(\.dismiss) private var dismiss
    @State private var style: PosterStyle = .gradient
    @State private var rendered: Image?
    private let stats: SummaryStats

    init(period: SummaryPeriod) {
        self.period = period
        self.stats = SummaryStats(period: period)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("poster.style.picker", selection: $style) {
                        ForEach(PosterStyle.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)

                    SummaryPosterCard(stats: stats, style: style)
                        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)

                    if let rendered, !stats.entries.isEmpty {
                        ShareLink(
                            item: rendered,
                            preview: SharePreview(String(localized: "poster.preview"), image: rendered)
                        ) {
                            Label("poster.share", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 13)
                                .background(Theme.actionGradient, in: Capsule())
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle(period.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.done") { dismiss() }
                }
            }
        }
        .task(id: style) { render() }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: SummaryPosterCard(stats: stats, style: style))
        renderer.scale = 3
        if let ui = renderer.uiImage {
            rendered = Image(uiImage: ui)
        }
    }
}

#Preview {
    SummaryPosterSheet(period: .week)
}

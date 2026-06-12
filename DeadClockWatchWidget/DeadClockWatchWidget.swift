import WidgetKit
import SwiftUI

struct WatchEntry: TimelineEntry {
    let date: Date
}

struct WatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchEntry {
        WatchEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
        completion(WatchEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        let now = Date()
        let entries = (0..<24).compactMap { offset -> WatchEntry? in
            guard let date = Calendar.current.date(byAdding: .hour, value: offset, to: now) else { return nil }
            return WatchEntry(date: date)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - 样式一：时光倒计时（计时器为主）

struct TimerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WatchEntry

    var body: some View {
        let deathDate = DeathClock.deathDate
        let days = DeathClock.remainingDays(at: entry.date)
        let progress = DeathClock.lifeProgress(at: entry.date)

        switch family {
        case .accessoryInline:
            Text(String(format: NSLocalizedString("widget.inline", comment: ""), days))
                .watchWidgetBackground()

        case .accessoryCircular:
            Gauge(value: 1 - progress) {
                Image(systemName: "sparkles")
            } currentValueLabel: {
                Text("\(Int((1 - progress) * 100))%")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .watchWidgetBackground()

        case .accessoryCorner:
            Text("\(days)")
                .font(.headline)
                .widgetLabel {
                    Text("widget.corner.label")
                }
                .watchWidgetBackground()

        default: // .accessoryRectangular
            VStack(alignment: .leading, spacing: 2) {
                Text("widget.header")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: NSLocalizedString("widget.days.n", comment: ""), days))
                    .font(.headline)
                if entry.date < deathDate {
                    Text(timerInterval: entry.date...deathDate, countsDown: true)
                        .font(.system(.caption2, design: .monospaced))
                        .monospacedDigit()
                }
            }
            .watchWidgetBackground()
        }
    }
}

struct DeadClockWatchWidget: Widget {
    let kind = "DeadClockWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchProvider()) { entry in
            TimerWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.name")
        .description("widget.desc")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
        ])
    }
}

// MARK: - 样式二：大字剩余天数

struct DaysWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WatchEntry

    var body: some View {
        let days = DeathClock.remainingDays(at: entry.date)

        switch family {
        case .accessoryInline:
            Text(String(format: NSLocalizedString("widget.inline", comment: ""), days))
                .watchWidgetBackground()

        case .accessoryCorner:
            Text("\(days)")
                .font(.system(.headline, design: .monospaced).weight(.heavy))
                .widgetLabel {
                    Text("widget.corner.label")
                }
                .watchWidgetBackground()

        default: // .accessoryCircular
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("widget.day.unit.short")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .watchWidgetBackground()
        }
    }
}

struct DeadClockDaysWidget: Widget {
    let kind = "DeadClockDaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchProvider()) { entry in
            DaysWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.days.name")
        .description("widget.desc")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
        ])
    }
}

// MARK: - 样式三：人生进度环

struct RingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WatchEntry

    var body: some View {
        let progress = DeathClock.lifeProgress(at: entry.date)

        switch family {
        case .accessoryCorner:
            Text(String(format: "%.0f%%", progress * 100))
                .font(.headline)
                .widgetLabel {
                    Text("widget.ring.label")
                }
                .watchWidgetBackground()

        case .accessoryRectangular:
            HStack(spacing: 10) {
                Gauge(value: progress) {
                    Image(systemName: "hourglass")
                } currentValueLabel: {
                    Text("\(Int(progress * 100))%")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                VStack(alignment: .leading, spacing: 2) {
                    Text("widget.ring.name")
                        .font(.caption)
                    Text(String(format: "%.4f%%", progress * 100))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .watchWidgetBackground()

        default: // .accessoryCircular
            Gauge(value: progress) {
                Image(systemName: "hourglass")
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .watchWidgetBackground()
        }
    }
}

struct DeadClockRingWidget: Widget {
    let kind = "DeadClockRingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchProvider()) { entry in
            RingWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.ring.name")
        .description("widget.desc")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
        ])
    }
}

@main
struct DeadClockWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        DeadClockWatchWidget()
        DeadClockDaysWidget()
        DeadClockRingWidget()
    }
}

extension View {
    /// watchOS 10 起要求 containerBackground，watchOS 9 没有该 API。
    @ViewBuilder
    func watchWidgetBackground() -> some View {
        if #available(watchOS 10.0, *) {
            containerBackground(for: .widget) { Color.clear }
        } else {
            self
        }
    }
}

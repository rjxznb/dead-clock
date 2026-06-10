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

struct WatchWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WatchEntry

    var body: some View {
        let deathDate = DeathClock.deathDate
        let days = DeathClock.remainingDays(at: entry.date)
        let progress = DeathClock.lifeProgress(at: entry.date)

        switch family {
        case .accessoryInline:
            Text("✨ 你还拥有 \(days) 天")
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
                    Text("还拥有 · 天")
                }
                .watchWidgetBackground()

        default: // .accessoryRectangular
            VStack(alignment: .leading, spacing: 2) {
                Text("把握当下 · 你还拥有")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(days) 天")
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
            WatchWidgetView(entry: entry)
        }
        .configurationDisplayName("时光倒计时")
        .description("抬腕即见：把余生变成动力。")
        .supportedFamilies([
            .accessoryInline,
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

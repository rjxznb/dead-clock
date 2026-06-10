import WidgetKit
import SwiftUI

struct DeathEntry: TimelineEntry {
    let date: Date
}

struct DeathProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeathEntry {
        DeathEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (DeathEntry) -> Void) {
        completion(DeathEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeathEntry>) -> Void) {
        // Text(timerInterval:) 由系统实时驱动秒级跳动，时间线本身只需
        // 每小时刷新一次来更新“剩余天数”这类静态数字。
        let now = Date()
        let entries = (0..<24).compactMap { offset -> DeathEntry? in
            guard let date = Calendar.current.date(byAdding: .hour, value: offset, to: now) else { return nil }
            return DeathEntry(date: date)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct DeadClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: DeathEntry

    var body: some View {
        let deathDate = DeathClock.deathDate
        let days = DeathClock.remainingDays(at: entry.date)
        let progress = DeathClock.lifeProgress(at: entry.date)

        switch family {
        case .accessoryInline:
            Text("余生 \(days) 天")
                .widgetBackground(Color.clear)

        case .accessoryCircular:
            Gauge(value: progress) {
                Image(systemName: "hourglass")
            } currentValueLabel: {
                Text("\(Int((1 - progress) * 100))%")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetBackground(Color.clear)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("距离死亡")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(days) 天")
                    .font(.headline)
                if entry.date < deathDate {
                    Text(timerInterval: entry.date...deathDate, countsDown: true)
                        .font(.system(.caption, design: .monospaced))
                        .monospacedDigit()
                }
            }
            .widgetBackground(Color.clear)

        default:
            VStack(spacing: 8) {
                Text("距离死亡还剩")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text("\(days)")
                    .font(.system(size: family == .systemMedium ? 56 : 40,
                                  weight: .heavy, design: .monospaced))
                    .foregroundStyle(.red)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("天")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                if entry.date < deathDate {
                    Text(timerInterval: entry.date...deathDate, countsDown: true)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetBackground(Color.black)
        }
    }
}

struct DeadClockWidget: Widget {
    let kind = "DeadClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeathProvider()) { entry in
            DeadClockWidgetView(entry: entry)
        }
        .configurationDisplayName("死亡倒计时")
        .description("时刻提醒你：余生有限。")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

@main
struct DeadClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        DeadClockWidget()
    }
}

extension View {
    /// iOS 17 起 Widget 必须使用 containerBackground，iOS 16 没有该 API。
    @ViewBuilder
    func widgetBackground<B: View>(_ background: B) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            self.background(background)
        }
    }
}

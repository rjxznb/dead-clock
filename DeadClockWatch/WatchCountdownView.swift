import SwiftUI

private let rainbow = LinearGradient(
    colors: [
        Color(red: 1.00, green: 0.42, blue: 0.62),
        Color(red: 1.00, green: 0.62, blue: 0.26),
        Color(red: 1.00, green: 0.79, blue: 0.34),
        Color(red: 0.18, green: 0.80, blue: 0.44),
        Color(red: 0.00, green: 0.82, blue: 0.83),
        Color(red: 0.65, green: 0.37, blue: 0.92),
    ],
    startPoint: .leading, endPoint: .trailing)

private let rainbowAngular = AngularGradient(
    colors: [
        Color(red: 1.00, green: 0.42, blue: 0.62),
        Color(red: 1.00, green: 0.62, blue: 0.26),
        Color(red: 1.00, green: 0.79, blue: 0.34),
        Color(red: 0.18, green: 0.80, blue: 0.44),
        Color(red: 0.00, green: 0.82, blue: 0.83),
        Color(red: 0.65, green: 0.37, blue: 0.92),
        Color(red: 1.00, green: 0.42, blue: 0.62),
    ],
    center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))

struct WatchCountdownView: View {
    @State private var page = ProcessInfo.processInfo.arguments.contains("--page2") ? 1 : 0

    var body: some View {
        TabView(selection: $page) {
            WatchTimerPage().tag(0)
            WatchProgressPage().tag(1)
        }
    }
}

/// 第一页：余生倒计时
struct WatchTimerPage: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let days = DeathClock.remainingDays(at: now)
            let b = DeathClock.breakdown(at: now)

            VStack(spacing: 4) {
                Text("watch.header")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)

                Text("\(days)")
                    .font(.system(size: 44, weight: .heavy, design: .monospaced))
                    .foregroundStyle(rainbow)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("watch.day.unit")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)

                if now < DeathClock.deathDate {
                    Text(timerInterval: now...DeathClock.deathDate, countsDown: true)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                HStack(spacing: 5) {
                    unitMini(b.years, "watch.u.y")
                    unitMini(b.days, "watch.u.d")
                    unitMini(b.hours, "watch.u.h")
                    unitMini(b.minutes, "watch.u.m")
                }
                .padding(.top, 4)
            }
        }
    }

    private func unitMini(_ value: Int, _ key: LocalizedStringKey) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(key)
                .font(.system(size: 9))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
    }
}

/// 第二页：人生进度环
struct WatchProgressPage: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let progress = DeathClock.lifeProgress(at: context.date)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 11)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(rainbowAngular, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(String(format: "%.2f%%", progress * 100))
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .foregroundStyle(rainbow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("watch.lived")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                    Text("watch.journey")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(10)
        }
    }
}

#Preview {
    WatchCountdownView()
}

import SwiftUI

struct WatchCountdownView: View {
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

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let days = DeathClock.remainingDays(at: now)
            let progress = DeathClock.lifeProgress(at: now)

            VStack(spacing: 5) {
                Text("把握当下 · 你还拥有")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)

                Text("\(days)")
                    .font(.system(size: 46, weight: .heavy, design: .monospaced))
                    .foregroundStyle(rainbow)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("天")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)

                if now < DeathClock.deathDate {
                    Text(timerInterval: now...DeathClock.deathDate, countsDown: true)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.15))
                        Capsule()
                            .fill(rainbow)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    WatchCountdownView()
}

import SwiftUI

struct MacCountdownView: View {
    @State private var birthDate = DeathClock.birthDate
    @State private var lifeExpectancy = DeathClock.lifeExpectancyYears

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
        VStack(spacing: 14) {
            TimelineView(.animation(minimumInterval: 0.1)) { context in
                let now = context.date
                let remaining = DeathClock.remainingSeconds(at: now)
                let progress = DeathClock.lifeProgress(at: now)

                VStack(spacing: 10) {
                    Text("headline.normal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .tracking(3)

                    Text(Self.secondsFormatter.string(from: NSNumber(value: remaining)) ?? "")
                        .font(.system(size: 26, weight: .heavy, design: .monospaced))
                        .foregroundStyle(rainbow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text("unit.seconds.caption")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.primary.opacity(0.12))
                            Capsule()
                                .fill(rainbow)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 6)

                    Text(String(format: NSLocalizedString("progress.normal", comment: ""),
                                progress * 100))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            DatePicker("settings.birthdate",
                       selection: $birthDate,
                       in: ...Date(),
                       displayedComponents: .date)
                .onChange(of: birthDate) { newValue in
                    DeathClock.birthDate = newValue
                }

            Stepper(value: $lifeExpectancy, in: 40...120, step: 1) {
                HStack {
                    Text("settings.expectancy")
                    Spacer()
                    Text(String(format: NSLocalizedString("settings.age.format", comment: ""),
                                Int(lifeExpectancy)))
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: lifeExpectancy) { newValue in
                DeathClock.lifeExpectancyYears = newValue
            }

            Divider()

            HStack {
                Spacer()
                Button("mac.quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private static let secondsFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 1
        return f
    }()
}

#Preview {
    MacCountdownView()
}

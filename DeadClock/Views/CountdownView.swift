import SwiftUI

struct CountdownView: View {
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 0.1)) { context in
                let now = context.date
                let b = DeathClock.breakdown(at: now)
                let remaining = DeathClock.remainingSeconds(at: now)
                let progress = DeathClock.lifeProgress(at: now)

                VStack(spacing: 32) {
                    Spacer()

                    Text("距离死亡还剩")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .tracking(8)

                    Text(Self.secondsFormatter.string(from: NSNumber(value: remaining)) ?? "")
                        .font(.system(size: 44, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.red)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .padding(.horizontal)
                        .contentTransition(.numericText())
                    Text("秒")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .padding(.top, -24)

                    HStack(spacing: 12) {
                        unitBlock(value: b.years, unit: "年")
                        unitBlock(value: b.days, unit: "天")
                        unitBlock(value: b.hours, unit: "时")
                        unitBlock(value: b.minutes, unit: "分")
                        unitBlock(value: b.seconds, unit: "秒")
                    }
                    .padding(.horizontal)

                    VStack(spacing: 10) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                Capsule()
                                    .fill(Color.red)
                                    .frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 8)

                        Text(String(format: "人生已逝去 %.6f%%", progress * 100))
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Button {
                        showSettings = true
                    } label: {
                        Label("设置", systemImage: "gearshape")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func unitBlock(value: Int, unit: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
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
    CountdownView()
}

import SwiftUI

struct CountdownView: View {
    @State private var showSettings = false
    @State private var showCheckIn = false
    @State private var showJournal = false

    @State private var theme = ThemeStore.current
    @State private var photos = ThemeStore.loadPhotos()
    @StateObject private var parallax = MotionParallax()
    @State private var streak = JournalStore.streak
    @State private var totalMoments = JournalStore.totalCount
    @State private var checkedToday = JournalStore.entry() != nil

    var body: some View {
        let palette = theme.palette

        TimelineView(.animation(minimumInterval: 0.1)) { context in
            ZStack {
                background(at: context.date)
                    .ignoresSafeArea()
                content(at: context.date, palette: palette)
            }
        }
        .preferredColorScheme(palette.isLight ? .light : .dark)
        .sheet(isPresented: $showCheckIn, onDismiss: refresh) {
            CheckInView()
        }
        .sheet(isPresented: $showJournal, onDismiss: refresh) {
            JournalView()
        }
        .sheet(isPresented: $showSettings, onDismiss: refresh) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCheckIn)) { _ in
            showCheckIn = true
        }
        .onAppear {
            ReminderManager.reschedule()
            if theme == .photo { parallax.start() }
        }
        .onDisappear {
            parallax.stop()
        }
        .onChange(of: theme) { newTheme in
            if newTheme == .photo {
                parallax.start()
            } else {
                parallax.stop()
            }
        }
    }

    // MARK: - 背景

    @ViewBuilder
    private func background(at date: Date) -> some View {
        switch theme {
        case .dark:
            Color.black
        case .light:
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.97, blue: 0.94),
                    Color(red: 1.00, green: 0.93, blue: 0.96),
                    Color(red: 0.93, green: 0.96, blue: 1.00),
                ],
                startPoint: .top, endPoint: .bottom)
        case .gradient:
            LinearGradient(colors: Theme.flowColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .hueRotation(.degrees(
                    date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 36) * 10))
        case .photo:
            if photos.isEmpty {
                Color.black
            } else {
                GeometryReader { geo in
                    // 多张照片每 20 秒轮播一次，结尾 2 秒淡入下一张
                    let interval = 20.0
                    let t = date.timeIntervalSinceReferenceDate / interval
                    let index = Int(t) % photos.count
                    let next = (index + 1) % photos.count
                    let frac = t - t.rounded(.down)
                    let fade = photos.count > 1 ? max(0, (frac - 0.9) * 10) : 0

                    ZStack {
                        Image(uiImage: photos[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                        if fade > 0 {
                            Image(uiImage: photos[next])
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .opacity(fade)
                        }
                    }
                    // 陀螺仪视差：放大一点再随姿态平移，边缘不露底
                    .scaleEffect(1.08)
                    .offset(parallax.offset)
                    .overlay(Color.black.opacity(0.45))
                }
            }
        case .red:
            Color.black
        }
    }

    // MARK: - 内容

    private func content(at now: Date, palette: ThemePalette) -> some View {
        let b = DeathClock.breakdown(at: now)
        let remaining = DeathClock.remainingSeconds(at: now)
        let progress = DeathClock.lifeProgress(at: now)

        return VStack(spacing: 26) {
            Spacer()

            Text(theme.isFearMode ? String(localized: "headline.fear") : String(localized: "headline.normal"))
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .tracking(6)

            VStack(spacing: 6) {
                Text(Self.secondsFormatter.string(from: NSNumber(value: remaining)) ?? "")
                    .font(.system(size: 44, weight: .heavy, design: .monospaced))
                    .foregroundStyle(palette.numberGradient)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal)
                Text("unit.seconds.caption")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            }

            HStack(spacing: 10) {
                unitBlock(value: b.years, unit: String(localized: "unit.y"), palette: palette)
                unitBlock(value: b.days, unit: String(localized: "unit.d"), palette: palette)
                unitBlock(value: b.hours, unit: String(localized: "unit.h"), palette: palette)
                unitBlock(value: b.minutes, unit: String(localized: "unit.m"), palette: palette)
                unitBlock(value: b.seconds, unit: String(localized: "unit.s"), palette: palette)
            }
            .padding(.horizontal)

            VStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(palette.barTrack)
                        Capsule()
                            .fill(palette.numberGradient)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 8)

                Text(String(format: NSLocalizedString(theme.isFearMode ? "progress.fear" : "progress.normal",
                                                      comment: ""),
                            progress * 100))
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(palette.textSecondary)
            }
            .padding(.horizontal, 32)

            if totalMoments > 0 {
                Text(String(format: NSLocalizedString("streak.line", comment: ""), streak, totalMoments))
                    .font(.caption)
                    .foregroundStyle(palette.accent)
            }

            Spacer()

            HStack(spacing: 14) {
                sideButton(icon: "book.pages", label: String(localized: "tab.journal"), palette: palette) {
                    showJournal = true
                }

                Button {
                    showCheckIn = true
                } label: {
                    Label(checkedToday ? String(localized: "checkin.done") : String(localized: "checkin.button"),
                          systemImage: checkedToday ? "checkmark.seal.fill" : "sparkles")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.actionBackground, in: Capsule())
                }

                sideButton(icon: "gearshape", label: String(localized: "tab.settings"), palette: palette) {
                    showSettings = true
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
    }

    private func unitBlock(value: Int, unit: String, palette: ThemePalette) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func sideButton(icon: String, label: String, palette: ThemePalette,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(palette.textSecondary)
            .frame(width: 52)
        }
    }

    private func refresh() {
        theme = ThemeStore.current
        photos = ThemeStore.loadPhotos()
        streak = JournalStore.streak
        totalMoments = JournalStore.totalCount
        checkedToday = JournalStore.entry() != nil
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

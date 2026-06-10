import SwiftUI

enum PosterStyle: String, CaseIterable, Identifiable {
    case gradient
    case dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .gradient: return String(localized: "poster.style.gradient")
        case .dark: return String(localized: "poster.style.dark")
        }
    }
}

/// 可渲染成图片分享的海报卡片
struct PosterCard: View {
    let entry: JournalEntry
    let style: PosterStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(dateString)
                .font(.footnote)
                .opacity(0.85)

            Text(String(format: NSLocalizedString("poster.quote.format", comment: ""), entry.text))
                .font(.title3.weight(.bold))
                .lineSpacing(8)
                .foregroundStyle(style == .dark ? AnyShapeStyle(Theme.rainbow) : AnyShapeStyle(.white))

            Rectangle()
                .fill(.white.opacity(style == .dark ? 0.15 : 0.3))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: NSLocalizedString("life.day.n", comment: ""), dayNumber.formatted()))
                    .font(.subheadline.weight(.semibold))
                Text(String(format: NSLocalizedString("poster.moment.n", comment: ""), momentIndex))
                    .font(.footnote)
                    .opacity(0.85)
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

    private var dateString: String {
        guard let date = JournalStore.date(fromKey: entry.dateKey) else { return entry.dateKey }
        return date.formatted(.dateTime.year().month().day().weekday(.wide))
    }

    private var dayNumber: Int {
        guard let date = JournalStore.date(fromKey: entry.dateKey) else { return 0 }
        return Int(date.timeIntervalSince(DeathClock.birthDate) / 86400) + 1
    }

    private var momentIndex: Int {
        let all = JournalStore.load().map(\.dateKey).sorted()
        return (all.firstIndex(of: entry.dateKey) ?? 0) + 1
    }
}

struct PosterSheet: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @State private var style: PosterStyle = .gradient
    @State private var rendered: Image?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("poster.style.picker", selection: $style) {
                    ForEach(PosterStyle.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                PosterCard(entry: entry, style: style)
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)

                if let rendered {
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
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle(Text("poster.title"))
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
        let renderer = ImageRenderer(content: PosterCard(entry: entry, style: style))
        renderer.scale = 3
        if let ui = renderer.uiImage {
            rendered = Image(uiImage: ui)
        }
    }
}

#Preview {
    PosterSheet(entry: JournalEntry(
        dateKey: "2026-06-10",
        text: "今天和爸妈视频聊了一个小时，听他们讲老家院子里的石榴树开花了。",
        updatedAt: Date()))
}

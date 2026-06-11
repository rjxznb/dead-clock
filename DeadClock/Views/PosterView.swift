import SwiftUI
import PhotosUI

/// 海报背景：渐变 / 黑底 / 调色板纯色 / 相册照片
enum PosterBackground: Equatable {
    case gradient
    case dark
    case solid(Color)
    case photo(UIImage)

    var isDark: Bool { self == .dark }
}

/// 深色系调色板：保证白色文字可读（与 Android 版一致）
let posterSolidPalette: [Color] = [
    Color(red: 0.70, green: 0.15, blue: 0.12),
    Color(red: 0.91, green: 0.35, blue: 0.05),
    Color(red: 0.78, green: 0.47, blue: 0.00),
    Color(red: 0.18, green: 0.49, blue: 0.20),
    Color(red: 0.00, green: 0.41, blue: 0.43),
    Color(red: 0.10, green: 0.37, blue: 0.71),
    Color(red: 0.40, green: 0.26, blue: 0.85),
    Color(red: 0.76, green: 0.09, blue: 0.36),
    Color(red: 0.22, green: 0.28, blue: 0.31),
]

/// 海报卡片的背景视图
struct PosterBackgroundFill: View {
    let background: PosterBackground

    var body: some View {
        switch background {
        case .gradient:
            Theme.posterBackground
        case .dark:
            Color(red: 0.05, green: 0.05, blue: 0.07)
        case .solid(let color):
            color
        case .photo(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.40))   // 暗化遮罩保证文字可读
        }
    }
}

/// 背景选择条：渐变 / 黑底 / 纯色圆点 / 照片
struct PosterSwatchRow: View {
    @Binding var background: PosterBackground
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                swatch(isSelected: background == .gradient) {
                    Circle().fill(Theme.posterBackground)
                } action: {
                    background = .gradient
                }
                swatch(isSelected: background == .dark) {
                    Circle().fill(Color(red: 0.05, green: 0.05, blue: 0.07))
                } action: {
                    background = .dark
                }
                ForEach(0..<posterSolidPalette.count, id: \.self) { i in
                    let color = posterSolidPalette[i]
                    swatch(isSelected: background == .solid(color)) {
                        Circle().fill(color)
                    } action: {
                        background = .solid(color)
                    }
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    ZStack {
                        Circle().fill(Color(white: 0.25))
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle().strokeBorder(
                            isPhoto ? Color.primary : Color.primary.opacity(0.2),
                            lineWidth: isPhoto ? 2 : 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 4)
        }
        .onChange(of: photoItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    background = .photo(ui)
                }
            }
        }
    }

    private var isPhoto: Bool {
        if case .photo = background { return true }
        return false
    }

    private func swatch<Content: View>(
        isSelected: Bool,
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            content()
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().strokeBorder(
                        isSelected ? Color.primary : Color.primary.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 可渲染成图片分享的海报卡片
struct PosterCard: View {
    let entry: JournalEntry
    let background: PosterBackground

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(dateString)
                .font(.footnote)
                .opacity(0.85)

            Text(String(format: NSLocalizedString("poster.quote.format", comment: ""), entry.text))
                .font(.title3.weight(.bold))
                .lineSpacing(8)
                .foregroundStyle(background.isDark ? AnyShapeStyle(Theme.rainbow) : AnyShapeStyle(.white))

            Rectangle()
                .fill(.white.opacity(background.isDark ? 0.15 : 0.3))
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
        .background { PosterBackgroundFill(background: background) }
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
    @State private var background: PosterBackground = .gradient
    @State private var rendered: Image?
    @State private var renderedUI: UIImage?
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PosterSwatchRow(background: $background)

                    PosterCard(entry: entry, background: background)
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

                        // 低调的辅助操作：无背景纯文字
                        Button {
                            if let ui = renderedUI {
                                UIImageWriteToSavedPhotosAlbum(ui, nil, nil, nil)
                                saved = true
                            }
                        } label: {
                            Text(saved ? "poster.saved" : "poster.save")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(Text("poster.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.done") { dismiss() }
                }
            }
        }
        .task(id: background) { render() }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: PosterCard(entry: entry, background: background))
        renderer.scale = 3
        if let ui = renderer.uiImage {
            renderedUI = ui
            rendered = Image(uiImage: ui)
            saved = false
        }
    }
}

#Preview {
    PosterSheet(entry: JournalEntry(
        dateKey: "2026-06-10",
        text: "今天和爸妈视频聊了一个小时，听他们讲老家院子里的石榴树开花了。",
        updatedAt: Date()))
}

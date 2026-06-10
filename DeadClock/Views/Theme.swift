import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case dark
    case light
    case gradient
    case photo
    case red

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dark: return "深色"
        case .light: return "浅色"
        case .gradient: return "流动渐变"
        case .photo: return "照片轮播"
        case .red: return "醒目红"
        }
    }

    /// 醒目红主题连文案一起切回“恐惧模式”
    var isFearMode: Bool { self == .red }
}

struct ThemePalette {
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let cardBackground: Color
    let barTrack: Color
    let numberGradient: LinearGradient
    let actionBackground: LinearGradient
    let isLight: Bool
}

extension AppTheme {
    var palette: ThemePalette {
        switch self {
        case .light:
            return ThemePalette(
                textPrimary: Color(red: 0.11, green: 0.11, blue: 0.12),
                textSecondary: Color(red: 0.63, green: 0.58, blue: 0.54),
                accent: Color(red: 0.91, green: 0.51, blue: 0.12),
                cardBackground: Color.white.opacity(0.85),
                barTrack: Color.black.opacity(0.08),
                // 浅色背景下用更深的饱和色保证对比度
                numberGradient: LinearGradient(
                    colors: [
                        Color(red: 0.93, green: 0.26, blue: 0.50),
                        Color(red: 0.95, green: 0.52, blue: 0.13),
                        Color(red: 0.80, green: 0.62, blue: 0.00),
                        Color(red: 0.10, green: 0.65, blue: 0.45),
                        Color(red: 0.00, green: 0.55, blue: 0.70),
                        Color(red: 0.55, green: 0.35, blue: 0.85),
                    ],
                    startPoint: .leading, endPoint: .trailing),
                actionBackground: Theme.actionGradient,
                isLight: true)
        case .red:
            return ThemePalette(
                textPrimary: .white,
                textSecondary: Color(white: 0.55),
                accent: Color(red: 1.0, green: 0.27, blue: 0.23),
                cardBackground: Color.white.opacity(0.06),
                barTrack: Color.white.opacity(0.12),
                numberGradient: LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.27, blue: 0.23),
                        Color(red: 0.80, green: 0.06, blue: 0.08),
                    ],
                    startPoint: .top, endPoint: .bottom),
                actionBackground: LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.18, blue: 0.16),
                        Color(red: 0.65, green: 0.02, blue: 0.05),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing),
                isLight: false)
        default:
            return ThemePalette(
                textPrimary: .white,
                textSecondary: Color(white: 0.62),
                accent: Color(red: 1.0, green: 0.79, blue: 0.34),
                cardBackground: Color.white.opacity(self == .dark ? 0.07 : 0.14),
                barTrack: Color.white.opacity(0.15),
                numberGradient: Theme.rainbow,
                actionBackground: Theme.actionGradient,
                isLight: false)
        }
    }
}

/// 全 App 共用的渐变
enum Theme {
    static let rainbow = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.42, blue: 0.62),
            Color(red: 1.00, green: 0.62, blue: 0.26),
            Color(red: 1.00, green: 0.79, blue: 0.34),
            Color(red: 0.18, green: 0.80, blue: 0.44),
            Color(red: 0.00, green: 0.82, blue: 0.83),
            Color(red: 0.65, green: 0.37, blue: 0.92),
        ],
        startPoint: .leading, endPoint: .trailing)

    static let actionGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.42, blue: 0.62),
            Color(red: 1.00, green: 0.62, blue: 0.26),
            Color(red: 0.65, green: 0.37, blue: 0.92),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let posterBackground = LinearGradient(
        colors: [
            Color(red: 0.35, green: 0.16, blue: 0.66),
            Color(red: 0.85, green: 0.25, blue: 0.55),
            Color(red: 1.00, green: 0.55, blue: 0.30),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let flowColors = [
        Color(red: 0.18, green: 0.11, blue: 0.41),
        Color(red: 0.72, green: 0.20, blue: 0.43),
        Color(red: 0.91, green: 0.40, blue: 0.24),
    ]
}

/// 主题选择与自定义背景照片（支持多张轮播）的存取
enum ThemeStore {
    private static let themeKey = "appTheme"

    static var current: AppTheme {
        get { AppTheme(rawValue: DeathClock.defaults.string(forKey: themeKey) ?? "") ?? .dark }
        set { DeathClock.defaults.set(newValue.rawValue, forKey: themeKey) }
    }

    private static var container: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: DeathClock.appGroupID)
    }

    private static var backgroundsDir: URL? {
        guard let base = container else { return nil }
        let dir = base.appendingPathComponent("backgrounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// 覆盖式保存整组背景照片（自动压缩到 1800px 内）
    static func savePhotos(_ datas: [Data]) {
        guard let dir = backgroundsDir else { return }
        if let old = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for f in old { try? FileManager.default.removeItem(at: f) }
        }
        for (i, data) in datas.enumerated() {
            guard let image = UIImage(data: data) else { continue }
            let resized = downscale(image, maxSide: 1800)
            if let jpeg = resized.jpegData(compressionQuality: 0.85) {
                try? jpeg.write(to: dir.appendingPathComponent(String(format: "bg-%02d.jpg", i)))
            }
        }
    }

    static func loadPhotos() -> [UIImage] {
        guard let dir = backgroundsDir,
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        else { return legacyPhoto() }
        let images = files
            .filter { $0.pathExtension == "jpg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { UIImage(contentsOfFile: $0.path) }
        return images.isEmpty ? legacyPhoto() : images
    }

    static var photoCount: Int { loadPhotos().count }

    /// 旧版单张背景的兼容读取
    private static func legacyPhoto() -> [UIImage] {
        guard let url = container?.appendingPathComponent("background.jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return [] }
        return [image]
    }

    private static func downscale(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let side = max(image.size.width, image.size.height)
        guard side > maxSide else { return image }
        let scale = maxSide / side
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

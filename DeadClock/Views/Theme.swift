import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case dark
    case light
    case gradient
    case photo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dark: return "深色"
        case .light: return "浅色"
        case .gradient: return "流动渐变"
        case .photo: return "自定义照片"
        }
    }
}

struct ThemePalette {
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let cardBackground: Color
    let barTrack: Color
    let numberGradient: LinearGradient
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
                isLight: true)
        default:
            return ThemePalette(
                textPrimary: .white,
                textSecondary: Color(white: 0.62),
                accent: Color(red: 1.0, green: 0.79, blue: 0.34),
                cardBackground: Color.white.opacity(self == .dark ? 0.07 : 0.14),
                barTrack: Color.white.opacity(0.15),
                numberGradient: Theme.rainbow,
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

/// 主题选择与自定义背景照片的存取
enum ThemeStore {
    private static let themeKey = "appTheme"

    static var current: AppTheme {
        get { AppTheme(rawValue: DeathClock.defaults.string(forKey: themeKey) ?? "") ?? .dark }
        set { DeathClock.defaults.set(newValue.rawValue, forKey: themeKey) }
    }

    private static var photoURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: DeathClock.appGroupID)?
            .appendingPathComponent("background.jpg")
    }

    static func savePhoto(_ data: Data) {
        guard let url = photoURL, let image = UIImage(data: data) else { return }
        // 控制尺寸避免每帧渲染大图
        let maxSide: CGFloat = 1800
        var final = image
        let side = max(image.size.width, image.size.height)
        if side > maxSide {
            let scale = maxSide / side
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            final = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        }
        if let jpeg = final.jpegData(compressionQuality: 0.85) {
            try? jpeg.write(to: url)
        }
    }

    static func loadPhoto() -> UIImage? {
        guard let url = photoURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

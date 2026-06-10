import CoreMotion
import SwiftUI

/// 陀螺仪视差：照片主题下，背景随手机倾斜轻微平移，产生 3D 景深感。
/// 仅在照片主题且界面可见时运行，离开即停止以省电。
final class MotionParallax: ObservableObject {
    private let manager = CMMotionManager()
    @Published var offset: CGSize = .zero

    /// 背景最大平移量（点）；配合 1.15 倍放大保证边缘不露底
    private let maxShift: CGFloat = 40
    /// 手持手机的典型俯仰角基线（弧度）
    private let pitchBaseline = 0.7

    var isRunning: Bool { manager.isDeviceMotionActive }

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            let x = CGFloat(max(-0.5, min(0.5, m.attitude.roll / 1.2))) * 2 * self.maxShift
            let y = CGFloat(max(-0.5, min(0.5, (m.attitude.pitch - self.pitchBaseline) / 1.2))) * 2 * self.maxShift
            // 低通滤波让移动顺滑
            self.offset = CGSize(
                width: self.offset.width * 0.75 + x * 0.25,
                height: self.offset.height * 0.75 + y * 0.25)
        }
    }

    func stop() {
        guard manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
        offset = .zero
    }
}

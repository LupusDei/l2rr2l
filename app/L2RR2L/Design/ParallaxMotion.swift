import CoreMotion
import SwiftUI

/// Tilt-driven parallax. On a real iPad the sky layers shift as the device
/// tilts; in the simulator (no motion) the sky sways gently on its own.
/// `offset` is roughly -1...1 on each axis; layers multiply it by their depth.
@MainActor
@Observable
final class ParallaxMotion {
    private(set) var offset: CGSize = .zero

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var reference: CMAttitude?
    @ObservationIgnored private var swayTask: Task<Void, Never>?

    func start() {
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 1 / 60
            manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self, let attitude = motion?.attitude.copy() as? CMAttitude else { return }
                if self.reference == nil { self.reference = attitude }
                if let reference = self.reference { attitude.multiply(byInverseOf: reference) }
                let target = CGSize(width: max(-1, min(1, attitude.roll * 2.5)),
                                    height: max(-1, min(1, attitude.pitch * 2.5)))
                // smooth it so the sky floats instead of jittering
                self.offset = CGSize(width: self.offset.width * 0.9 + target.width * 0.1,
                                     height: self.offset.height * 0.9 + target.height * 0.1)
            }
        } else if swayTask == nil {
            swayTask = Task { [weak self] in
                let start = Date()
                while !Task.isCancelled {
                    let t = Date().timeIntervalSince(start)
                    self?.offset = CGSize(width: sin(t * 0.35) * 0.5, height: cos(t * 0.27) * 0.3)
                    try? await Task.sleep(for: .milliseconds(33))
                }
            }
        }
    }
}

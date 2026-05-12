import Combine
import CoreMotion
import Foundation

final class MagnetometerService: ObservableObject {
    @Published private(set) var x: Double = 0
    @Published private(set) var y: Double = 0
    @Published private(set) var z: Double = 0
    @Published private(set) var magnitudeMicroTesla: Double = 0
    @Published private(set) var history: [Double] = Array(repeating: 0, count: 180)
    @Published private(set) var isRunning = false

    private let motion = CMMotionManager()
    private let queue = OperationQueue()

    init() {
        queue.qualityOfService = .userInteractive
    }

    func start() {
        guard motion.isMagnetometerAvailable else { return }
        motion.magnetometerUpdateInterval = 1.0 / 50.0
        motion.startMagnetometerUpdates(to: queue) { [weak self] data, _ in
            guard let data, let self else { return }
            let x = data.magneticField.x
            let y = data.magneticField.y
            let z = data.magneticField.z
            let mag = sqrt(x * x + y * y + z * z)
            DispatchQueue.main.async {
                self.x = x
                self.y = y
                self.z = z
                self.magnitudeMicroTesla = mag
                var h = self.history
                h.removeFirst()
                h.append(mag)
                self.history = h
            }
        }
        isRunning = true
    }

    func stop() {
        motion.stopMagnetometerUpdates()
        isRunning = false
    }
}

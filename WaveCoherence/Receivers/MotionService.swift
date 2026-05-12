import Combine
import CoreMotion
import Foundation

final class MotionService: ObservableObject {
    @Published private(set) var accel: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published private(set) var gyro: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published private(set) var attitudePitch: Double = 0
    @Published private(set) var attitudeRoll: Double = 0
    @Published private(set) var attitudeYaw: Double = 0
    @Published private(set) var vibrationRMS: Double = 0
    @Published private(set) var isRunning = false

    private let motion = CMMotionManager()
    private let queue = OperationQueue()
    private var samples: [Double] = []
    private let sampleWindow = 200
    private let sampleLock = NSLock()

    init() {
        queue.qualityOfService = .userInteractive
    }

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(to: queue) { [weak self] data, _ in
            guard let data, let self else { return }
            let ax = data.userAcceleration.x
            let ay = data.userAcceleration.y
            let az = data.userAcceleration.z
            let mag = sqrt(ax * ax + ay * ay + az * az)

            self.sampleLock.lock()
            self.samples.append(mag)
            if self.samples.count > self.sampleWindow {
                self.samples.removeFirst(self.samples.count - self.sampleWindow)
            }
            let snapshot = self.samples
            self.sampleLock.unlock()

            let mean = snapshot.reduce(0, +) / Double(snapshot.count)
            let variance = snapshot.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(snapshot.count)
            let rms = sqrt(variance)

            let pitch = data.attitude.pitch
            let roll = data.attitude.roll
            let yaw = data.attitude.yaw
            let gx = data.rotationRate.x
            let gy = data.rotationRate.y
            let gz = data.rotationRate.z

            DispatchQueue.main.async {
                self.accel = (ax, ay, az)
                self.gyro = (gx, gy, gz)
                self.attitudePitch = pitch
                self.attitudeRoll = roll
                self.attitudeYaw = yaw
                self.vibrationRMS = rms
            }
        }
        isRunning = true
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        isRunning = false
    }
}

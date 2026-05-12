import Combine
import CoreMotion
import Foundation

final class BarometerService: ObservableObject {
    @Published private(set) var pressureKPa: Double = 0
    @Published private(set) var relativeAltitude: Double = 0
    @Published private(set) var history: [Double] = Array(repeating: 0, count: 180)
    @Published private(set) var isRunning = false

    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()

    init() {
        queue.qualityOfService = .userInteractive
    }

    func start() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, _ in
            guard let data, let self else { return }
            let kPa = data.pressure.doubleValue
            let alt = data.relativeAltitude.doubleValue
            DispatchQueue.main.async {
                self.pressureKPa = kPa
                self.relativeAltitude = alt
                var h = self.history
                h.removeFirst()
                h.append(kPa)
                self.history = h
            }
        }
        isRunning = true
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
        isRunning = false
    }
}

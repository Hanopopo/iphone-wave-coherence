import AVFoundation
import Foundation

// Pulses the rear flash LED at a target frequency for visual entrainment.
// Note: AVCaptureDevice torch toggling is rate-limited by iOS; we cap the
// emit rate to a few Hz to avoid driver throttling. For higher SSVEP
// frequencies use ScreenFlasher instead.
final class TorchEmitter {
    private(set) var isRunning = false
    private var timer: DispatchSourceTimer?
    private var on = false
    private var device: AVCaptureDevice? {
        AVCaptureDevice.default(for: .video)
    }

    func start(frequencyHz: Double) {
        stop()
        guard let dev = device, dev.hasTorch else { return }
        let f = min(max(frequencyHz, 0.5), 12.0)
        let interval = 1.0 / (2.0 * f)
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        t.schedule(deadline: .now(), repeating: interval)
        t.setEventHandler { [weak self] in
            guard let self else { return }
            self.toggle()
        }
        timer = t
        t.resume()
        isRunning = true
    }

    func stop() {
        timer?.cancel()
        timer = nil
        on = false
        if let dev = device, dev.hasTorch {
            try? dev.lockForConfiguration()
            dev.torchMode = .off
            dev.unlockForConfiguration()
        }
        isRunning = false
    }

    private func toggle() {
        guard let dev = device, dev.hasTorch else { return }
        on.toggle()
        do {
            try dev.lockForConfiguration()
            if on {
                try? dev.setTorchModeOn(level: 0.6)
            } else {
                dev.torchMode = .off
            }
            dev.unlockForConfiguration()
        } catch {
            // device busy
        }
    }
}

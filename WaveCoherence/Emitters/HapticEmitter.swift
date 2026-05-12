import CoreHaptics
import Foundation

// Drives the Taptic Engine in time with the coherence engine's target frequency.
// Below ~30 Hz the user feels discrete pulses; above ~30 Hz Core Haptics maps
// to a continuous vibration that closely matches the audio carrier.
final class HapticEmitter {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private(set) var isRunning = false

    func start(frequencyHz: Double) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            if engine == nil {
                engine = try CHHapticEngine()
                engine?.stoppedHandler = { _ in }
                engine?.resetHandler = { [weak self] in
                    try? self?.engine?.start()
                }
            }
            try engine?.start()
            let pattern = try buildPattern(frequencyHz: frequencyHz)
            player = try engine?.makeAdvancedPlayer(with: pattern)
            player?.loopEnabled = true
            try player?.start(atTime: CHHapticTimeImmediate)
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        engine?.stop(completionHandler: nil)
        player = nil
        isRunning = false
    }

    private func buildPattern(frequencyHz: Double) throws -> CHHapticPattern {
        // For low frequencies (< 30 Hz), emit a transient at each cycle.
        // For higher frequencies, emit one continuous event with a sharpness tied to freq.
        let period = max(0.02, 1.0 / max(0.5, frequencyHz))

        if frequencyHz < 30 {
            var events: [CHHapticEvent] = []
            let cycles = max(1, Int(2.0 / period))
            for i in 0..<cycles {
                let e = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: TimeInterval(i) * period
                )
                events.append(e)
            }
            return try CHHapticPattern(events: events, parameters: [])
        } else {
            let sharpness = Float(min(1.0, max(0.0, (frequencyHz - 30) / 200)))
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0,
                duration: 2.0
            )
            return try CHHapticPattern(events: [event], parameters: [])
        }
    }
}

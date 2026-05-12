import Combine
import Foundation
import SwiftUI

// Master coordinator. Owns one instance of every receiver and emitter, exposes
// a single Published "tick" that views can use to render synchronized
// visualizations, and computes the cross-modal coherence score that the
// Dashboard surfaces. All mutations happen on the main runloop (Timer on main,
// button actions on main), so no actor isolation is required.
final class CoherenceEngine: ObservableObject {
    // Receivers
    let magnetometer = MagnetometerService()
    let motion = MotionService()
    let barometer = BarometerService()
    let audio = AudioFFTService()
    let heart = HeartRateService()
    let ble = BLEScannerService()

    // Emitters
    let tone = ToneEmitter()
    let haptic = HapticEmitter()
    let torch = TorchEmitter()
    let bleAdvertiser = BLEAdvertiserService()

    // Targets
    @Published var preset: FrequencyPreset = Presets.defaultPreset()
    @Published var toneMode: ToneEmitter.Mode = .binaural
    @Published var amplitude: Double = 0.18

    // Emitter switches
    @Published var audioOn = false
    @Published var hapticOn = false
    @Published var torchOn = false
    @Published var screenFlasherOn = false
    @Published var beaconOn = false

    // Receiver switches (default on — the dashboard wants them live)
    @Published var magnetometerOn = false
    @Published var motionOn = false
    @Published var barometerOn = false
    @Published var audioInOn = false
    @Published var heartOn = false
    @Published var bleScanOn = false

    // Visualization clock — drives screen flasher and aurora animations in
    // phase with the emitters.
    @Published private(set) var phase: Double = 0
    @Published private(set) var coherenceScore: Double = 0

    private var phaseTimer: Timer?
    private var startedAt: TimeInterval = CACurrentMediaTime()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Republish whenever any sub-service publishes, so views that observe
        // `engine` re-render when sensors/emitters update.
        let publishers: [ObjectWillChangePublisher] = [
            magnetometer.objectWillChange,
            motion.objectWillChange,
            barometer.objectWillChange,
            audio.objectWillChange,
            heart.objectWillChange,
            ble.objectWillChange,
            bleAdvertiser.objectWillChange
        ]
        for publisher in publishers {
            publisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
        }

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tickPhase()
        }
    }

    private func tickPhase() {
        let t = CACurrentMediaTime() - startedAt
        let f = max(0.1, preset.frequencyHz)
        phase = (t * f).truncatingRemainder(dividingBy: 1.0)
        computeCoherence()
    }

    private func computeCoherence() {
        // Combine multiple normalized indicators:
        // - HRV coherence proxy
        // - Audio rms stability
        // - Magnetometer fluctuation (lower = more coherent)
        // - BLE RF density (higher density = more chaotic)
        let hrv = heart.coherenceScore
        let mag = magnetometer.history.suffix(60)
        let magVar: Double
        if mag.count > 2 {
            let mean = mag.reduce(0, +) / Double(mag.count)
            magVar = mag.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(mag.count)
        } else {
            magVar = 0
        }
        let magCalm = 1.0 - min(1.0, magVar / 30.0)
        let rfCalm = 1.0 - ble.rfDensity
        let audioCalm = 1.0 - min(1.0, Double(audio.rms) * 8.0)

        let active = [
            heartOn ? hrv : nil,
            magnetometerOn ? magCalm : nil,
            bleScanOn ? rfCalm : nil,
            audioInOn ? audioCalm : nil
        ].compactMap { $0 }

        if active.isEmpty {
            coherenceScore = 0
        } else {
            coherenceScore = active.reduce(0, +) / Double(active.count)
        }
    }

    // MARK: - Receivers control

    func toggleMagnetometer() {
        magnetometerOn.toggle()
        if magnetometerOn { magnetometer.start() } else { magnetometer.stop() }
    }
    func toggleMotion() {
        motionOn.toggle()
        if motionOn { motion.start() } else { motion.stop() }
    }
    func toggleBarometer() {
        barometerOn.toggle()
        if barometerOn { barometer.start() } else { barometer.stop() }
    }
    func toggleAudioIn() {
        audioInOn.toggle()
        if audioInOn { audio.start() } else { audio.stop() }
    }
    func toggleHeart() {
        heartOn.toggle()
        if heartOn { heart.start() } else { heart.stop() }
    }
    func toggleBLEScan() {
        bleScanOn.toggle()
        if bleScanOn { ble.start() } else { ble.stop() }
    }

    func startAllReceivers() {
        if !magnetometerOn { toggleMagnetometer() }
        if !motionOn { toggleMotion() }
        if !barometerOn { toggleBarometer() }
        if !audioInOn { toggleAudioIn() }
        if !bleScanOn { toggleBLEScan() }
    }
    func stopAllReceivers() {
        if magnetometerOn { toggleMagnetometer() }
        if motionOn { toggleMotion() }
        if barometerOn { toggleBarometer() }
        if audioInOn { toggleAudioIn() }
        if heartOn { toggleHeart() }
        if bleScanOn { toggleBLEScan() }
    }

    // MARK: - Emitters control

    func toggleAudio() {
        audioOn.toggle()
        applyPresetToTone()
        if audioOn { tone.start() } else { tone.stop() }
    }
    func toggleHaptic() {
        hapticOn.toggle()
        if hapticOn { haptic.start(frequencyHz: preset.frequencyHz) } else { haptic.stop() }
    }
    func toggleTorch() {
        torchOn.toggle()
        if torchOn { torch.start(frequencyHz: preset.frequencyHz) } else { torch.stop() }
    }
    func toggleScreenFlasher() {
        screenFlasherOn.toggle()
    }
    func toggleBeacon() {
        beaconOn.toggle()
        if beaconOn { bleAdvertiser.start() } else { bleAdvertiser.stop() }
    }

    func emitAll() {
        if !audioOn { toggleAudio() }
        if !hapticOn { toggleHaptic() }
        if !screenFlasherOn { toggleScreenFlasher() }
        if !beaconOn { toggleBeacon() }
    }
    func silenceAll() {
        if audioOn { toggleAudio() }
        if hapticOn { toggleHaptic() }
        if torchOn { toggleTorch() }
        if screenFlasherOn { toggleScreenFlasher() }
        if beaconOn { toggleBeacon() }
    }

    func applyPresetToTone() {
        tone.mode = toneMode
        tone.carrierHz = preset.carrierHz
        tone.beatHz = preset.binauralOffsetHz
        tone.amplitude = Float(amplitude)
    }

    func setPreset(_ p: FrequencyPreset) {
        preset = p
        applyPresetToTone()
        if hapticOn {
            haptic.stop()
            haptic.start(frequencyHz: p.frequencyHz)
        }
        if torchOn {
            torch.stop()
            torch.start(frequencyHz: p.frequencyHz)
        }
        bleAdvertiser.intentionTag = String(format: "%.2fHz", p.frequencyHz)
    }
}

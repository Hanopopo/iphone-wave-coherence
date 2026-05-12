import AVFoundation
import Foundation

// Synthesizes pure tones, binaural beats, and isochronic tones to the speaker
// (or headphones). The CoherenceEngine drives `frequencyHz` and `binauralOffset`
// and reads `currentPhase` so the screen flasher / haptics / torch stay
// phase-locked with the audio.
final class ToneEmitter {
    enum Mode: String, Hashable, CaseIterable {
        case pure          // single sine
        case binaural      // left = carrier - offset/2, right = carrier + offset/2
        case isochronic    // single sine amplitude-modulated at the target frequency
    }

    var mode: Mode = .binaural
    var carrierHz: Double = 200
    var beatHz: Double = 7.83
    var amplitude: Float = 0.18
    private(set) var currentPhase: Double = 0

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var sampleRate: Double = 48_000
    private var isRunning = false
    private var generatorQueue = DispatchQueue(label: "tone.generator")
    private var leftPhase: Double = 0
    private var rightPhase: Double = 0
    private var amPhase: Double = 0

    init() {
        engine.attach(player)
    }

    func start() {
        guard !isRunning else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            // .playAndRecord so the tone emitter coexists with the FFT receiver.
            try session.setCategory(.playAndRecord,
                                    mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            return
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
        sampleRate = format.sampleRate
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do { try engine.start() } catch { return }
        player.play()
        scheduleNextBuffer(format: format)
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        player.stop()
        engine.stop()
        isRunning = false
    }

    private func scheduleNextBuffer(format: AVAudioFormat) {
        generatorQueue.async { [weak self] in
            guard let self else { return }
            let frames: AVAudioFrameCount = 4096
            guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
            buf.frameLength = frames
            let left = buf.floatChannelData![0]
            let right = buf.floatChannelData![1]
            let sr = self.sampleRate

            for i in 0..<Int(frames) {
                let sample: (Float, Float)
                switch self.mode {
                case .pure:
                    let v = sin(2 * .pi * self.leftPhase) * Double(self.amplitude)
                    sample = (Float(v), Float(v))
                    self.leftPhase += self.carrierHz / sr
                case .binaural:
                    let fL = self.carrierHz - self.beatHz / 2
                    let fR = self.carrierHz + self.beatHz / 2
                    let l = sin(2 * .pi * self.leftPhase) * Double(self.amplitude)
                    let r = sin(2 * .pi * self.rightPhase) * Double(self.amplitude)
                    sample = (Float(l), Float(r))
                    self.leftPhase += fL / sr
                    self.rightPhase += fR / sr
                case .isochronic:
                    let carrier = sin(2 * .pi * self.leftPhase)
                    let amEnv = max(0.0, (1 + sin(2 * .pi * self.amPhase - .pi / 2)) / 2)
                    let v = carrier * amEnv * Double(self.amplitude)
                    sample = (Float(v), Float(v))
                    self.leftPhase += self.carrierHz / sr
                    self.amPhase += self.beatHz / sr
                }
                left[i] = sample.0
                right[i] = sample.1
            }

            self.currentPhase = self.amPhase

            self.player.scheduleBuffer(buf) { [weak self] in
                guard let self, self.isRunning else { return }
                self.scheduleNextBuffer(format: format)
            }
        }
    }
}

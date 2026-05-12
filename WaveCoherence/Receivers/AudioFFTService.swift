import AVFoundation
import Accelerate
import Combine
import Foundation

final class AudioFFTService: ObservableObject {
    struct Peak: Identifiable, Hashable {
        let id = UUID()
        let frequencyHz: Double
        let magnitude: Float
    }

    @Published private(set) var spectrum: [Float] = []
    @Published private(set) var peaks: [Peak] = []
    @Published private(set) var rms: Float = 0
    @Published private(set) var dominantHz: Double = 0
    @Published private(set) var isRunning = false
    @Published private(set) var sampleRate: Double = 48_000

    private let engine = AVAudioEngine()
    private let fft = FFTProcessor(size: 4096)
    private var buffer: [Float] = []
    private let lock = NSLock()

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord,
                                    mode: .measurement,
                                    options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            return
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        sampleRate = format.sampleRate
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
            self?.process(buf)
        }

        do {
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
    }

    private func process(_ buf: AVAudioPCMBuffer) {
        guard let channelData = buf.floatChannelData?[0] else { return }
        let frameLength = Int(buf.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))

        lock.lock()
        buffer.append(contentsOf: samples)
        if buffer.count > fft.size * 2 {
            buffer.removeFirst(buffer.count - fft.size * 2)
        }
        let snapshot = buffer
        lock.unlock()

        var rmsVal: Float = 0
        vDSP_rmsqv(samples, 1, &rmsVal, vDSP_Length(samples.count))

        let mags = fft.magnitudeSpectrum(snapshot)
        let detectedPeaks = FFTProcessor.topPeaks(mags, sampleRate: sampleRate, fftSize: fft.size, count: 6, minHz: 1.0)
        let domHz = detectedPeaks.first?.hz ?? 0
        let display = downsample(mags, target: 128)
        let mappedPeaks = detectedPeaks.map { Peak(frequencyHz: $0.hz, magnitude: $0.mag) }

        DispatchQueue.main.async {
            self.rms = rmsVal
            self.spectrum = display
            self.peaks = mappedPeaks
            self.dominantHz = domHz
        }
    }

    private func downsample(_ mags: [Float], target: Int) -> [Float] {
        guard mags.count > target else { return mags }
        let bucket = mags.count / target
        var out = [Float](repeating: 0, count: target)
        for i in 0..<target {
            let start = i * bucket
            let end = min(start + bucket, mags.count)
            var maxV: Float = 0
            for j in start..<end { if mags[j] > maxV { maxV = mags[j] } }
            out[i] = maxV
        }
        return out
    }
}

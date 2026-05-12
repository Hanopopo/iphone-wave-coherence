import Accelerate
import Foundation

// Wraps vDSP for a sliding-window FFT of mono audio samples.
final class FFTProcessor {
    let log2n: vDSP_Length
    let size: Int
    private let fftSetup: FFTSetup
    private var window: [Float]

    init(size: Int = 4096) {
        let pow2 = vDSP_Length(log2(Double(size)).rounded())
        self.log2n = pow2
        self.size = 1 << pow2
        self.fftSetup = vDSP_create_fftsetup(pow2, FFTRadix(kFFTRadix2))!
        self.window = [Float](repeating: 0, count: self.size)
        vDSP_hann_window(&window, vDSP_Length(self.size), Int32(vDSP_HANN_NORM))
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    /// Returns the linear magnitude spectrum (size/2 bins) for `samples`.
    func magnitudeSpectrum(_ samples: [Float]) -> [Float] {
        guard samples.count >= size else { return [] }
        var windowed = [Float](repeating: 0, count: size)
        let frame = Array(samples.suffix(size))
        vDSP_vmul(frame, 1, window, 1, &windowed, 1, vDSP_Length(size))

        var real = [Float](repeating: 0, count: size / 2)
        var imag = [Float](repeating: 0, count: size / 2)

        return real.withUnsafeMutableBufferPointer { realPtr in
            imag.withUnsafeMutableBufferPointer { imagPtr in
                var split = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                windowed.withUnsafeBufferPointer { samplesPtr in
                    samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: size / 2) { typedPtr in
                        vDSP_ctoz(typedPtr, 2, &split, 1, vDSP_Length(size / 2))
                    }
                }
                vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))

                var magnitudes = [Float](repeating: 0, count: size / 2)
                vDSP_zvabs(&split, 1, &magnitudes, 1, vDSP_Length(size / 2))
                var scale: Float = 1.0 / Float(size)
                vDSP_vsmul(magnitudes, 1, &scale, &magnitudes, 1, vDSP_Length(size / 2))
                return magnitudes
            }
        }
    }

    /// Frequency in Hz for FFT bin index, given sample rate.
    static func frequency(forBin index: Int, sampleRate: Double, fftSize: Int) -> Double {
        Double(index) * sampleRate / Double(fftSize)
    }

    /// Top-N peaks in the spectrum, returned as (frequencyHz, magnitude).
    static func topPeaks(_ magnitudes: [Float], sampleRate: Double, fftSize: Int, count: Int = 5, minHz: Double = 1.0) -> [(hz: Double, mag: Float)] {
        guard !magnitudes.isEmpty else { return [] }
        var peaks: [(hz: Double, mag: Float)] = []
        for i in 1..<(magnitudes.count - 1) {
            let m = magnitudes[i]
            if m > magnitudes[i - 1], m > magnitudes[i + 1] {
                let hz = frequency(forBin: i, sampleRate: sampleRate, fftSize: fftSize)
                if hz >= minHz {
                    peaks.append((hz, m))
                }
            }
        }
        return Array(peaks.sorted { $0.mag > $1.mag }.prefix(count))
    }
}

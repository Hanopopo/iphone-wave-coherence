import AVFoundation
import Combine
import Foundation
import UIKit

// Camera-based photoplethysmography (PPG).
// User covers the rear camera with their fingertip; the flash illuminates
// capillaries, and pulses are derived from the red-channel intensity over time.
final class HeartRateService: NSObject, ObservableObject {
    @Published private(set) var bpm: Double = 0
    @Published private(set) var hrvMs: Double = 0
    @Published private(set) var coherenceScore: Double = 0
    @Published private(set) var signal: [Double] = Array(repeating: 0, count: 240)
    @Published private(set) var isRunning = false
    @Published private(set) var fingerDetected: Bool = false

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sampleQueue = DispatchQueue(label: "ppg.samples")
    private var device: AVCaptureDevice?
    private var samples: [(t: TimeInterval, v: Double)] = []
    private var ibis: [Double] = []
    private var lastPeakTime: TimeInterval = 0
    private let stateLock = NSLock()

    func start() {
        sampleQueue.async { [weak self] in
            self?.configureAndStart()
        }
    }

    func stop() {
        sampleQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            if let d = self.device, d.hasTorch {
                try? d.lockForConfiguration()
                d.torchMode = .off
                d.unlockForConfiguration()
            }
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    private func configureAndStart() {
        session.beginConfiguration()
        session.sessionPreset = .low

        guard
            let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: cam),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        self.device = cam
        session.addInput(input)

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()

        if cam.hasTorch {
            try? cam.lockForConfiguration()
            try? cam.setTorchModeOn(level: 0.4)
            cam.unlockForConfiguration()
        }

        session.startRunning()
        DispatchQueue.main.async { self.isRunning = true }
    }
}

extension HeartRateService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let ptr = base.assumingMemoryBound(to: UInt8.self)

        let patch = 32
        let x0 = max(0, width / 2 - patch / 2)
        let y0 = max(0, height / 2 - patch / 2)
        var rSum: UInt64 = 0
        var gSum: UInt64 = 0
        var count: UInt64 = 0
        for y in y0..<(y0 + patch) {
            for x in x0..<(x0 + patch) {
                let i = y * bytesPerRow + x * 4
                gSum &+= UInt64(ptr[i + 1])
                rSum &+= UInt64(ptr[i + 2])
                count &+= 1
            }
        }
        let r = Double(rSum) / Double(count)
        let g = Double(gSum) / Double(count)
        let finger = r > 150 && g < 100
        let value = r - g

        let t = CACurrentMediaTime()

        // Buffer the signal series (sampleQueue is the only writer)
        samples.append((t, value))
        if samples.count > 600 { samples.removeFirst(samples.count - 600) }
        let snapshot = samples.suffix(60).map { $0.v }

        detectPeak(at: t, value: value, recent: snapshot, finger: finger)

        // Push the signal trace to the UI
        DispatchQueue.main.async {
            self.fingerDetected = finger
            var sig = self.signal
            sig.removeFirst()
            sig.append(value)
            self.signal = sig
        }
    }

    private func detectPeak(at t: TimeInterval, value: Double, recent: [Double], finger: Bool) {
        guard recent.count >= 30 else { return }
        let mean = recent.reduce(0, +) / Double(recent.count)
        let maxV = recent.max() ?? 0
        let threshold = mean + 0.6 * (maxV - mean)
        let cooldown = 0.35

        if value > threshold && (t - lastPeakTime) > cooldown && finger {
            if lastPeakTime > 0 {
                let ibi = (t - lastPeakTime) * 1000.0
                if ibi > 300 && ibi < 1500 {
                    ibis.append(ibi)
                    if ibis.count > 60 { ibis.removeFirst(ibis.count - 60) }
                    publishMetrics()
                }
            }
            lastPeakTime = t
        }
    }

    private func publishMetrics() {
        guard ibis.count >= 5 else { return }
        let snapshot = ibis
        let meanIbi = snapshot.reduce(0, +) / Double(snapshot.count)
        let newBpm = 60_000.0 / meanIbi
        var sumSq = 0.0
        for i in 1..<snapshot.count {
            let d = snapshot[i] - snapshot[i - 1]
            sumSq += d * d
        }
        let rmssd = sqrt(sumSq / Double(snapshot.count - 1))
        let mean = meanIbi
        let variance = snapshot.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(snapshot.count)
        let normalized = min(1.0, variance / 4000.0)

        DispatchQueue.main.async {
            self.bpm = newBpm
            self.hrvMs = rmssd
            self.coherenceScore = normalized
        }
    }
}

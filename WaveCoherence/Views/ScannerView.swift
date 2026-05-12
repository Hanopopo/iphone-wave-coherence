import Charts
import SwiftUI

struct SeriesPoint: Identifiable {
    let id = UUID()
    let idx: Int
    let value: Double
}

struct ScannerView: View {
    @EnvironmentObject private var engine: CoherenceEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionHeader(title: "Receivers", subtitle: "Detect waves around you")
                    .padding(.horizontal, 4)

                magnetometerCard
                audioCard
                heartCard
                motionCard
                barometerCard
                bleCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private var magnetometerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Magnetometer",
                           subtitle: "3-axis Hall sensor — magnetic field",
                           on: engine.magnetometerOn) { engine.toggleMagnetometer() }
                HStack(spacing: 18) {
                    metric("X", String(format: "%.1f", engine.magnetometer.x), .cyan)
                    metric("Y", String(format: "%.1f", engine.magnetometer.y), .pink)
                    metric("Z", String(format: "%.1f", engine.magnetometer.z), .yellow)
                    metric("|B|", String(format: "%.1f µT", engine.magnetometer.magnitudeMicroTesla), .white)
                }
                Chart(magPoints) { p in
                    LineMark(x: .value("t", p.idx), y: .value("µT", p.value))
                        .foregroundStyle(.cyan)
                        .interpolationMethod(.catmullRom)
                }
                .frame(height: 100)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }
    }

    private var audioCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Microphone (FFT)",
                           subtitle: "Audio spectrum + peak detection",
                           on: engine.audioInOn) { engine.toggleAudioIn() }
                HStack(spacing: 18) {
                    metric("Dominant", String(format: "%.0f Hz", engine.audio.dominantHz), .cyan)
                    metric("RMS", String(format: "%.3f", engine.audio.rms), .pink)
                }
                spectrumView
                if !engine.audio.peaks.isEmpty {
                    HStack {
                        ForEach(engine.audio.peaks.prefix(4)) { peak in
                            GlassPill(label: String(format: "%.0f Hz", peak.frequencyHz),
                                      systemImage: "waveform",
                                      tint: .cyan)
                        }
                    }
                }
            }
        }
    }

    private var spectrumView: some View {
        Chart(spectrumPoints) { p in
            BarMark(
                x: .value("bin", p.idx),
                y: .value("mag", p.value)
            )
            .foregroundStyle(
                LinearGradient(colors: [.cyan, .pink], startPoint: .bottom, endPoint: .top)
            )
        }
        .frame(height: 120)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }

    private var magPoints: [SeriesPoint] {
        engine.magnetometer.history.enumerated().map { SeriesPoint(idx: $0.offset, value: $0.element) }
    }

    private var spectrumPoints: [SeriesPoint] {
        engine.audio.spectrum.enumerated().map { SeriesPoint(idx: $0.offset, value: Double($0.element)) }
    }

    private var heartPoints: [SeriesPoint] {
        engine.heart.signal.enumerated().map { SeriesPoint(idx: $0.offset, value: $0.element) }
    }

    private var heartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Heart (camera PPG)",
                           subtitle: "Cover the rear camera with your fingertip",
                           on: engine.heartOn) { engine.toggleHeart() }
                HStack(spacing: 18) {
                    metric("BPM", engine.heart.bpm > 0 ? String(format: "%.0f", engine.heart.bpm) : "—", .red)
                    metric("HRV", engine.heart.hrvMs > 0 ? String(format: "%.0f ms", engine.heart.hrvMs) : "—", .orange)
                    metric("Coh", String(format: "%.0f%%", engine.heart.coherenceScore * 100), .pink)
                }
                if engine.heartOn {
                    Chart(heartPoints) { p in
                        LineMark(x: .value("t", p.idx), y: .value("v", p.value))
                            .foregroundStyle(.red)
                    }
                    .frame(height: 80)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    if !engine.heart.fingerDetected {
                        Text("No finger detected on lens")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    private var motionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Motion (accel + gyro)",
                           subtitle: "Vibrations, orientation",
                           on: engine.motionOn) { engine.toggleMotion() }
                HStack(spacing: 18) {
                    metric("Vibration RMS",
                           String(format: "%.4f g", engine.motion.vibrationRMS),
                           .yellow)
                    metric("Pitch", String(format: "%.0f°", engine.motion.attitudePitch * 180 / .pi), .cyan)
                    metric("Roll", String(format: "%.0f°", engine.motion.attitudeRoll * 180 / .pi), .pink)
                }
            }
        }
    }

    private var barometerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Barometer",
                           subtitle: "Atmospheric pressure / altitude",
                           on: engine.barometerOn) { engine.toggleBarometer() }
                HStack(spacing: 18) {
                    metric("Pressure",
                           String(format: "%.2f kPa", engine.barometer.pressureKPa),
                           .cyan)
                    metric("Δ alt",
                           String(format: "%.2f m", engine.barometer.relativeAltitude),
                           .pink)
                }
            }
        }
    }

    private var bleCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "BLE radio scan",
                           subtitle: "Devices broadcasting 2.4 GHz",
                           on: engine.bleScanOn) { engine.toggleBLEScan() }
                HStack(spacing: 18) {
                    metric("Devices", "\(engine.ble.devices.count)", .cyan)
                    metric("RF density",
                           String(format: "%.0f%%", engine.ble.rfDensity * 100),
                           .pink)
                }
                if !engine.ble.devices.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(engine.ble.devices.prefix(6)) { d in
                            HStack {
                                Text(d.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundStyle(.white.opacity(0.85))
                                Spacer()
                                Text("\(d.rssi) dBm")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                }
            }
        }
    }

    private func metric(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
    }

    private func cardHeader(title: String, subtitle: String, on: Bool, toggle: @escaping () -> Void) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Button(action: toggle) {
                Image(systemName: on ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(on ? .pink : .cyan)
            }
            .buttonStyle(.plain)
        }
    }
}

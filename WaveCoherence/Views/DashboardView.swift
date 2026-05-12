import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var engine: CoherenceEngine

    var body: some View {
        ZStack {
            if engine.screenFlasherOn {
                ScreenFlasher(phase: engine.phase, frequencyHz: engine.preset.frequencyHz)
            }
            ScrollView {
                VStack(spacing: 18) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                SectionHeader(title: "Coherence", subtitle: engine.preset.name)
                                Spacer()
                                GlassPill(label: String(format: "%.2f Hz", engine.preset.frequencyHz),
                                          systemImage: "waveform.path",
                                          tint: .cyan)
                            }
                            CoherenceRing(score: engine.coherenceScore, phase: engine.phase)
                                .frame(height: 220)
                        }
                    }

                    GlassCard {
                        VStack(spacing: 12) {
                            MetricRow(label: "Magnetic field",
                                      value: String(format: "%.1f", engine.magnetometer.magnitudeMicroTesla),
                                      unit: "µT",
                                      icon: "scope",
                                      tint: .pink)
                            MetricRow(label: "Ambient sound peak",
                                      value: String(format: "%.0f", engine.audio.dominantHz),
                                      unit: "Hz",
                                      icon: "waveform",
                                      tint: .cyan)
                            MetricRow(label: "Pulse (PPG)",
                                      value: engine.heart.bpm > 0 ? String(format: "%.0f", engine.heart.bpm) : "—",
                                      unit: engine.heart.bpm > 0 ? "bpm" : "",
                                      icon: "heart.fill",
                                      tint: .red)
                            MetricRow(label: "HRV (RMSSD)",
                                      value: engine.heart.hrvMs > 0 ? String(format: "%.0f", engine.heart.hrvMs) : "—",
                                      unit: engine.heart.hrvMs > 0 ? "ms" : "",
                                      icon: "heart.text.square",
                                      tint: .orange)
                            MetricRow(label: "RF density",
                                      value: String(format: "%.0f%%", engine.ble.rfDensity * 100),
                                      icon: "antenna.radiowaves.left.and.right",
                                      tint: .purple)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Quick controls")
                            HStack(spacing: 10) {
                                ActionButton(title: "Start all receivers",
                                             systemImage: "dot.radiowaves.left.and.right",
                                             tint: .cyan) {
                                    engine.startAllReceivers()
                                }
                                ActionButton(title: "Emit all",
                                             systemImage: "antenna.radiowaves.left.and.right",
                                             tint: .pink) {
                                    engine.emitAll()
                                }
                            }
                            HStack(spacing: 10) {
                                ActionButton(title: "Silence all",
                                             systemImage: "speaker.slash.fill",
                                             tint: .orange) {
                                    engine.silenceAll()
                                }
                                ActionButton(title: "Stop receivers",
                                             systemImage: "stop.circle",
                                             tint: .purple) {
                                    engine.stopAllReceivers()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Wave Coherence")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("Multi-sensor field engine — \(engine.preset.category.rawValue) preset")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

private struct ActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(tint.opacity(0.6), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CoherenceRing: View {
    let score: Double
    let phase: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: max(0.02, score))
                    .stroke(
                        AngularGradient(colors: [.cyan, .blue, .purple, .pink, .cyan],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
                    .scaleEffect(0.85 + 0.05 * CGFloat(sin(phase * 2 * .pi)))
                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", score * 100))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    Text("Coherence")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(2)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity)
        }
    }
}

import SwiftUI

struct CoherenceView: View {
    @EnvironmentObject private var engine: CoherenceEngine

    var body: some View {
        ZStack {
            if engine.screenFlasherOn {
                ScreenFlasher(phase: engine.phase, frequencyHz: engine.preset.frequencyHz)
            }
            ScrollView {
                VStack(spacing: 16) {
                    header

                    GlassCard {
                        VStack(spacing: 16) {
                            VisualizationCanvas(phase: engine.phase,
                                                coherence: engine.coherenceScore,
                                                frequency: engine.preset.frequencyHz)
                                .frame(height: 260)
                            HStack {
                                GlassPill(label: String(format: "%.2f Hz", engine.preset.frequencyHz),
                                          systemImage: "waveform.path",
                                          tint: .cyan)
                                GlassPill(label: "ϕ \(String(format: "%.2f", engine.phase))",
                                          systemImage: "circle.dotted",
                                          tint: .pink)
                                GlassPill(label: String(format: "%.0f%% coh", engine.coherenceScore * 100),
                                          systemImage: "circle.hexagongrid.fill",
                                          tint: .purple)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Master controls",
                                          subtitle: "Synchronize every emitter and receiver")
                            HStack(spacing: 10) {
                                ActionButton(title: "Activate field",
                                             systemImage: "bolt.fill",
                                             tint: .pink) {
                                    engine.startAllReceivers()
                                    engine.emitAll()
                                }
                                ActionButton(title: "Stand down",
                                             systemImage: "stop.circle",
                                             tint: .orange) {
                                    engine.silenceAll()
                                    engine.stopAllReceivers()
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "What this does",
                                          subtitle: "Honest mechanism summary")
                            BulletRow(text: "Locks the audio carrier, Taptic Engine, screen flasher and flashlight to the same phase clock at the chosen frequency.")
                            BulletRow(text: "Broadcasts a Bluetooth LE advertisement tagged with that frequency so a companion device — or another iPhone running this app — can detect it.")
                            BulletRow(text: "Continuously samples your magnetometer, motion, barometer, microphone, camera-PPG and BLE neighbours, and combines them into a coherence score.")
                            BulletRow(text: "Effects on your perception come from the real audio/visual/haptic stimulation. Effects on the room are the actual physical waves your phone emits — no more, no less.")
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
            Text("Coherence engine")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(engine.preset.name)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct BulletRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(.cyan).frame(width: 6, height: 6).padding(.top, 7)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
    }
}

struct VisualizationCanvas: View {
    let phase: Double
    let coherence: Double
    let frequency: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let cy = h / 2
            let baseRadius = min(w, h) / 2 - 24
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    let t = Double(i) / 8.0
                    let r = baseRadius * (0.4 + 0.6 * (1 - t))
                    let alpha = (0.10 + 0.45 * (1 - t)) * (0.5 + 0.5 * coherence)
                    Circle()
                        .stroke(LinearGradient(colors: [.cyan, .pink, .purple],
                                              startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5)
                        .frame(width: r * 2, height: r * 2)
                        .position(x: cx, y: cy)
                        .opacity(alpha)
                        .scaleEffect(1.0 + 0.07 * CGFloat(sin(phase * 2 * .pi + Double(i) * 0.6)))
                }
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.85), .clear],
                                         center: .center, startRadius: 0, endRadius: 40))
                    .frame(width: 80, height: 80)
                    .position(x: cx, y: cy)
                    .opacity(0.6 + 0.4 * CGFloat(sin(phase * 2 * .pi)))
            }
        }
    }
}

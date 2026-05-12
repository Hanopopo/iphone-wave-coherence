import CoreBluetooth
import SwiftUI

struct EmittersView: View {
    @EnvironmentObject private var engine: CoherenceEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionHeader(title: "Emitters", subtitle: "Generate waves from your phone")
                    .padding(.horizontal, 4)

                audioCard
                hapticCard
                screenCard
                torchCard
                beaconCard

                disclaimer
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private var audioCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                emitterHeader(title: "Audio tone",
                              subtitle: "Pure / binaural / isochronic",
                              on: engine.audioOn) { engine.toggleAudio() }

                Picker("Mode", selection: $engine.toneMode) {
                    Text("Pure").tag(ToneEmitter.Mode.pure)
                    Text("Binaural").tag(ToneEmitter.Mode.binaural)
                    Text("Isochronic").tag(ToneEmitter.Mode.isochronic)
                }
                .pickerStyle(.segmented)
                .onChange(of: engine.toneMode) { _ in engine.applyPresetToTone() }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Amplitude")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Slider(value: $engine.amplitude, in: 0...0.5)
                        .tint(.cyan)
                        .onChange(of: engine.amplitude) { _ in engine.applyPresetToTone() }
                }

                HStack {
                    GlassPill(label: String(format: "Carrier %.0f Hz", engine.preset.carrierHz),
                              systemImage: "waveform", tint: .cyan)
                    GlassPill(label: String(format: "Beat %.2f Hz", engine.preset.binauralOffsetHz),
                              systemImage: "metronome", tint: .pink)
                }
            }
        }
    }

    private var hapticCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                emitterHeader(title: "Taptic Engine",
                              subtitle: "Mechanical vibration at \(String(format: "%.2f", engine.preset.frequencyHz)) Hz",
                              on: engine.hapticOn) { engine.toggleHaptic() }
                Text("Below 30 Hz the device pulses once per cycle; above 30 Hz it produces a continuous vibration whose sharpness follows the frequency.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var screenCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                emitterHeader(title: "Screen flasher",
                              subtitle: "SSVEP-style brightness modulation",
                              on: engine.screenFlasherOn) { engine.toggleScreenFlasher() }
                Text("Modulates the display brightness in phase with the master clock. Best perceived in the 5–25 Hz range (peak SSVEP 12–18 Hz, PLOS One 2013).")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var torchCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                emitterHeader(title: "Flashlight LED",
                              subtitle: "Rear LED pulsed up to ~12 Hz",
                              on: engine.torchOn) { engine.toggleTorch() }
                Text("iOS rate-limits torch toggling, so we cap the pulse rate to 12 Hz. For higher frequencies use the screen flasher.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var beaconCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                emitterHeader(title: "BLE intention beacon",
                              subtitle: "Broadcasts a 2.4 GHz advertisement",
                              on: engine.beaconOn) { engine.toggleBeacon() }
                TextField("Intention tag",
                          text: Binding(
                            get: { engine.bleAdvertiser.intentionTag },
                            set: { engine.bleAdvertiser.intentionTag = $0 }
                          ))
                    .textFieldStyle(.roundedBorder)
                Text("State: \(stateLabel(engine.bleAdvertiser.state))  \(engine.bleAdvertiser.isAdvertising ? "advertising" : "idle")")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var disclaimer: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Label("Honest scope", systemImage: "info.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text("Wave Coherence emits real, measurable signals (audio, haptic vibration, screen light, LED light, BLE 2.4 GHz). Any effect on perception, mood, or physiology comes from those measurable signals — not from supernatural channels. Claims tied to specific frequencies (Solfeggio, 'manifestation') are presented with citations in RESEARCH.md and clearly marked when evidence is weak.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private func emitterHeader(title: String, subtitle: String, on: Bool, toggle: @escaping () -> Void) -> some View {
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

    private func stateLabel(_ s: CBManagerState) -> String {
        switch s {
        case .poweredOn: return "poweredOn"
        case .poweredOff: return "poweredOff"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .resetting: return "resetting"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }
}

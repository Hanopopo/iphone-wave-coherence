import SwiftUI

struct PresetsView: View {
    @EnvironmentObject private var engine: CoherenceEngine
    @State private var category: FrequencyPreset.Category = .schumann

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionHeader(title: "Presets", subtitle: "Pick a research-backed frequency")
                    .padding(.horizontal, 4)

                Picker("Category", selection: $category) {
                    ForEach(FrequencyPreset.Category.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 4)

                ForEach(Presets.all.filter { $0.category == category }) { preset in
                    Button {
                        engine.setPreset(preset)
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    Image(systemName: preset.symbol)
                                        .font(.title2)
                                        .foregroundStyle(.cyan)
                                        .frame(width: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.name)
                                            .font(.system(.headline, design: .rounded, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text(String(format: "%.2f Hz · carrier %.0f Hz", preset.frequencyHz, preset.carrierHz))
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    if engine.preset.id == preset.id {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.cyan)
                                    }
                                }
                                Text(preset.blurb)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }
}

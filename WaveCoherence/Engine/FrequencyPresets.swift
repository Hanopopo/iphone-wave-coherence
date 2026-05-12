import Foundation

// MARK: - Frequency presets
// Each preset documents the published research it is based on.
// References live in RESEARCH.md at the repo root.

struct FrequencyPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let symbol: String
    let frequencyHz: Double
    let binauralOffsetHz: Double
    let carrierHz: Double
    let category: Category
    let blurb: String

    enum Category: String, CaseIterable, Identifiable {
        case schumann = "Schumann"
        case brainwave = "Brainwaves"
        case solfeggio = "Solfeggio"
        case coherence = "Coherence"
        var id: String { rawValue }
    }
}

enum Presets {
    static let all: [FrequencyPreset] = [
        FrequencyPreset(
            name: "Schumann 1st mode",
            symbol: "globe.europe.africa.fill",
            frequencyHz: 7.83,
            binauralOffsetHz: 7.83,
            carrierHz: 200,
            category: .schumann,
            blurb: "Earth-ionosphere cavity resonance. Cardioprotective at 7.8 Hz / 90 nT in cell cultures (Elhalel et al., Nature Sci Rep 2019)."
        ),
        FrequencyPreset(
            name: "Schumann 2nd mode",
            symbol: "globe.europe.africa",
            frequencyHz: 14.3,
            binauralOffsetHz: 14.3,
            carrierHz: 220,
            category: .schumann,
            blurb: "Second mode of the Earth-ionosphere cavity. Observed in EEG harmonics (Saroka et al., PLOS One 2016)."
        ),
        FrequencyPreset(
            name: "Schumann 3rd mode",
            symbol: "circle.dotted",
            frequencyHz: 20.8,
            binauralOffsetHz: 20.8,
            carrierHz: 240,
            category: .schumann,
            blurb: "Third mode of the Earth-ionosphere cavity."
        ),
        FrequencyPreset(
            name: "Delta (deep sleep)",
            symbol: "moon.zzz.fill",
            frequencyHz: 2.0,
            binauralOffsetHz: 2.0,
            carrierHz: 120,
            category: .brainwave,
            blurb: "0.5–4 Hz. Slow-wave sleep, restorative."
        ),
        FrequencyPreset(
            name: "Theta (meditation)",
            symbol: "leaf.fill",
            frequencyHz: 6.0,
            binauralOffsetHz: 6.0,
            carrierHz: 150,
            category: .brainwave,
            blurb: "4–8 Hz. Deep meditation, creativity, hypnagogic states."
        ),
        FrequencyPreset(
            name: "Alpha (relaxed focus)",
            symbol: "circle.hexagonpath.fill",
            frequencyHz: 10.0,
            binauralOffsetHz: 10.0,
            carrierHz: 200,
            category: .brainwave,
            blurb: "8–12 Hz. Calm alertness. Binaural beats meta-analysis: g=0.45 effect on cognition/anxiety (Garcia-Argibay 2018)."
        ),
        FrequencyPreset(
            name: "Beta (active thinking)",
            symbol: "bolt.fill",
            frequencyHz: 18.0,
            binauralOffsetHz: 18.0,
            carrierHz: 240,
            category: .brainwave,
            blurb: "12–30 Hz. Engaged cognition, alertness."
        ),
        FrequencyPreset(
            name: "Gamma (peak attention)",
            symbol: "sparkle",
            frequencyHz: 40.0,
            binauralOffsetHz: 40.0,
            carrierHz: 300,
            category: .brainwave,
            blurb: "30–80 Hz. Cross-region binding, peak attention."
        ),
        FrequencyPreset(
            name: "Solfeggio 174 Hz",
            symbol: "drop.fill",
            frequencyHz: 174,
            binauralOffsetHz: 6,
            carrierHz: 174,
            category: .solfeggio,
            blurb: "Pre-modern tone. Modern claims have minimal peer-reviewed support — included for completeness."
        ),
        FrequencyPreset(
            name: "Solfeggio 396 Hz",
            symbol: "flame.fill",
            frequencyHz: 396,
            binauralOffsetHz: 6,
            carrierHz: 396,
            category: .solfeggio,
            blurb: "Tradition: 'release of fear'. No replicated RCTs."
        ),
        FrequencyPreset(
            name: "Solfeggio 528 Hz",
            symbol: "heart.fill",
            frequencyHz: 528,
            binauralOffsetHz: 6,
            carrierHz: 528,
            category: .solfeggio,
            blurb: "Tradition: 'love'. Rat-brain study: anxiolytic effect at 528 Hz/100 dB (Akimoto et al., PubMed 30414050)."
        ),
        FrequencyPreset(
            name: "Solfeggio 639 Hz",
            symbol: "person.2.fill",
            frequencyHz: 639,
            binauralOffsetHz: 6,
            carrierHz: 639,
            category: .solfeggio,
            blurb: "Tradition: 'connection'. No replicated RCTs."
        ),
        FrequencyPreset(
            name: "Solfeggio 741 Hz",
            symbol: "drop.triangle.fill",
            frequencyHz: 741,
            binauralOffsetHz: 6,
            carrierHz: 741,
            category: .solfeggio,
            blurb: "Tradition: 'expression / intuition'. No replicated RCTs."
        ),
        FrequencyPreset(
            name: "Solfeggio 852 Hz",
            symbol: "eye.fill",
            frequencyHz: 852,
            binauralOffsetHz: 6,
            carrierHz: 852,
            category: .solfeggio,
            blurb: "Tradition: 'intuition / order'. No replicated RCTs."
        ),
        FrequencyPreset(
            name: "Solfeggio 963 Hz",
            symbol: "infinity",
            frequencyHz: 963,
            binauralOffsetHz: 6,
            carrierHz: 963,
            category: .solfeggio,
            blurb: "Tradition: 'unity'. No replicated RCTs."
        ),
        FrequencyPreset(
            name: "Heart coherence 0.1 Hz",
            symbol: "heart.text.square.fill",
            frequencyHz: 0.1,
            binauralOffsetHz: 0,
            carrierHz: 180,
            category: .coherence,
            blurb: "Resonant breathing ~6 bpm. Maximizes HRV / baroreflex gain (Lehrer & Gevirtz 2014)."
        ),
        FrequencyPreset(
            name: "Heart coherence 0.05 Hz",
            symbol: "lungs.fill",
            frequencyHz: 0.05,
            binauralOffsetHz: 0,
            carrierHz: 180,
            category: .coherence,
            blurb: "Resonant breathing ~3 bpm. Reported peak coherence for some individuals."
        )
    ]

    static func defaultPreset() -> FrequencyPreset {
        all.first { $0.name == "Schumann 1st mode" } ?? all[0]
    }
}

import SwiftUI

// Overlay that pulses brightness in phase with the engine's clock — a primitive
// SSVEP stimulator. Wrapped as a SwiftUI view so it can be conditionally
// composed over any tab.
struct ScreenFlasher: View {
    let phase: Double           // 0...1
    let frequencyHz: Double
    var tint: Color = Color(red: 0.85, green: 0.40, blue: 1.00)
    var intensity: Double = 0.45

    var body: some View {
        // Sinusoidal brightness modulation in phase with the master clock.
        let alpha = (sin(phase * 2 * .pi - .pi / 2) + 1) / 2 * intensity
        ZStack {
            tint.opacity(alpha)
            RadialGradient(colors: [tint.opacity(alpha * 0.8), .clear],
                           center: .center, startRadius: 30, endRadius: 600)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

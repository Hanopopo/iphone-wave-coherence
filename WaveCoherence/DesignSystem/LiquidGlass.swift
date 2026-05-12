import SwiftUI

// MARK: - Liquid Glass design tokens
// Apple's "Liquid Glass" aesthetic uses translucent materials over a dynamic
// gradient backdrop, soft inner highlights, and a thin specular border.

enum Glass {
    static let cornerRadius: CGFloat = 24
    static let strokeWidth: CGFloat = 0.75
    static let shadowRadius: CGFloat = 22
}

struct LiquidBackground: View {
    @State private var t: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.10),
                    Color(red: 0.05, green: 0.02, blue: 0.18),
                    Color(red: 0.02, green: 0.08, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Drifting colored blobs
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(blobGradient(i))
                    .frame(width: 380, height: 380)
                    .blur(radius: 90)
                    .offset(
                        x: CGFloat(sin(t + Double(i) * 1.7)) * 140,
                        y: CGFloat(cos(t * 0.8 + Double(i) * 2.1)) * 220
                    )
                    .opacity(0.55)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                t = .pi * 2
            }
        }
    }

    private func blobGradient(_ i: Int) -> RadialGradient {
        let colors: [Color] = [
            Color(red: 0.20, green: 0.90, blue: 1.00),
            Color(red: 0.85, green: 0.40, blue: 1.00),
            Color(red: 0.40, green: 0.70, blue: 1.00),
            Color(red: 1.00, green: 0.55, blue: 0.85)
        ]
        return RadialGradient(
            colors: [colors[i % colors.count].opacity(0.55), .clear],
            center: .center,
            startRadius: 0,
            endRadius: 220
        )
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.55),
                                .white.opacity(0.05),
                                .white.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Glass.strokeWidth
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: Glass.shadowRadius, x: 0, y: 12)
    }
}

struct GlassPill: View {
    let label: String
    let systemImage: String
    var tint: Color = .cyan

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 0.75)
        )
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    var unit: String = ""
    var icon: String = "waveform"
    var tint: Color = .cyan

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

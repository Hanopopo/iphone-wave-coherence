import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var engine: CoherenceEngine
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        ZStack {
            LiquidBackground()
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(AppTab.dashboard)
                    .tabItem { Label("Dashboard", systemImage: "waveform.path.ecg") }

                ScannerView()
                    .tag(AppTab.scanner)
                    .tabItem { Label("Receivers", systemImage: "dot.radiowaves.left.and.right") }

                EmittersView()
                    .tag(AppTab.emitters)
                    .tabItem { Label("Emitters", systemImage: "antenna.radiowaves.left.and.right") }

                CoherenceView()
                    .tag(AppTab.coherence)
                    .tabItem { Label("Coherence", systemImage: "circle.hexagongrid.fill") }

                PresetsView()
                    .tag(AppTab.presets)
                    .tabItem { Label("Presets", systemImage: "sparkles") }
            }
            .tint(.cyan)
        }
    }
}

enum AppTab: Hashable {
    case dashboard, scanner, emitters, coherence, presets
}

#Preview {
    ContentView()
        .environmentObject(CoherenceEngine())
}

import SwiftUI

@main
struct WaveCoherenceApp: App {
    @StateObject private var engine = CoherenceEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
        }
    }
}

import SwiftUI

@main
struct TradorApp: App {
    @StateObject private var progress = ProgressStore()
    @StateObject private var market = MarketSim()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progress)
                .environmentObject(market)
        }
    }
}

import SwiftUI

struct RootView: View {
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var market: MarketSim

    var body: some View {
        TabView {
            LearnView()
                .tabItem { Label("Apprendre", systemImage: "book.fill") }
            TradingFloorView()
                .tabItem { Label("Trader", systemImage: "chart.line.uptrend.xyaxis") }
            GlossaryView()
                .tabItem { Label("Glossaire", systemImage: "character.book.closed.fill") }
            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle.fill") }
        }
        .overlay(alignment: .top) {
            if let message = market.banner {
                BannerView(message: message)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { market.banner = nil }
            }
        }
        .overlay {
            if let level = progress.levelUp {
                LevelUpView(level: level) {
                    withAnimation { progress.levelUp = nil }
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.3), value: market.banner)
        .onChange(of: market.banner) { _, newValue in
            guard let shown = newValue else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if market.banner == shown { market.banner = nil }
            }
        }
        .onAppear {
            let store = progress
            let sim = market
            sim.onMission = { [weak sim] id in
                if let mission = store.completeMission(id) {
                    sim?.banner = "Mission accomplie : \(mission.title) +\(mission.xp) XP"
                }
            }
        }
    }
}

struct BannerView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 4)
            .padding(.horizontal)
    }
}

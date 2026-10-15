import SwiftUI

/// Tap to open a mystery chest. The reward is random, so every chest is a small surprise.
struct ChestView: View {
    @EnvironmentObject var progress: ProgressStore
    @State private var rarity: ChestRarity?
    @State private var shaking = false
    @State private var opening = false

    var body: some View {
        VStack(spacing: 10) {
            if let rarity {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(rarity.color)
                    .symbolEffect(.bounce, value: rarity)
                Text("\(rarity.rawValue) chest!")
                    .font(.title2.bold())
                    .foregroundStyle(rarity.color)
                Text("+\(rarity.xp) XP" + (rarity.givesFreeze ? " and a streak freeze" : ""))
                    .font(.headline)
            } else {
                Button {
                    open()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.orange)
                            .rotationEffect(.degrees(shaking ? 8 : -8))
                            .scaleEffect(opening ? 1.3 : 1)
                        Text(opening ? "Opening..." : "Tap to open your mystery chest")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(opening)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                shaking = true
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: rarity)
    }

    private func open() {
        withAnimation(.spring(duration: 0.4)) { opening = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(duration: 0.5, bounce: 0.5)) {
                rarity = progress.openChest()
            }
        }
    }
}

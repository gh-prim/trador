import SwiftUI

/// Falling confetti drawn with Canvas. Plays once.
struct ConfettiView: View {
    private struct Piece {
        let x: Double
        let delay: Double
        let speed: Double
        let spin: Double
        let sway: Double
        let color: Color
    }

    @State private var start = Date()
    @State private var pieces: [Piece] = (0..<90).map { _ in
        Piece(
            x: Double.random(in: 0...1),
            delay: Double.random(in: 0...0.8),
            speed: Double.random(in: 0.35...0.7),
            spin: Double.random(in: -6...6),
            sway: Double.random(in: 0...(2 * Double.pi)),
            color: [Color.orange, .green, .blue, .pink, .yellow, .purple].randomElement() ?? .orange
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let t = elapsed - piece.delay
                    guard t > 0 else { continue }
                    let y = -20 + t * piece.speed * size.height
                    guard y < size.height + 20 else { continue }
                    let x = piece.x * size.width + sin(t * 3 + piece.sway) * 18
                    var pieceContext = context
                    pieceContext.translateBy(x: x, y: y)
                    pieceContext.rotate(by: .radians(t * piece.spin))
                    pieceContext.fill(Path(CGRect(x: -4, y: -6, width: 8, height: 12)), with: .color(piece.color))
                }
            }
        }
    }
}

/// Full screen "Level up!" moment.
struct LevelUpView: View {
    let level: Int
    let onClose: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            VStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(Color.orange)
                    .scaleEffect(appeared ? 1 : 0.3)
                Text("Niveau supérieur !")
                    .font(.largeTitle.bold())
                Text("Niveau \(level)")
                    .font(.title.bold())
                    .foregroundStyle(Color.orange)
                Text("Nouveau rang : \(ProgressStore.rank(for: level))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Button(action: onClose) {
                    Text("Continuer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(.systemBackground)))
            .padding(32)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: appeared)
    }
}

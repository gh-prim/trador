import SwiftUI

/// Five quick questions from lessons you finished. Combos give bonus XP. XP once per day.
struct DailyChallengeView: View {
    @EnvironmentObject var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [QuizQuestion] = []
    @State private var index = 0
    @State private var selected: Int?
    @State private var correct = 0
    @State private var combo = 0
    @State private var bestCombo = 0
    @State private var runXP = 0
    @State private var awarded = 0
    @State private var finished = false
    @State private var alreadyDone = false

    private let color = Color.orange

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(finished ? questions.count : index), total: Double(max(questions.count, 1)))
                    .tint(color)
                Label("\(runXP)", systemImage: "star.fill")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
            .padding()

            if questions.isEmpty {
                Spacer()
            } else if finished {
                resultView
            } else {
                quizView
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            if questions.isEmpty {
                alreadyDone = progress.dailyChallengeDoneToday
                questions = progress.dailyQuestions()
            }
        }
    }

    private var quizView: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Défi du jour", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
                if alreadyDone {
                    Text("Mode entraînement")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            ScrollView {
                QuizCard(
                    question: questions[index],
                    number: index + 1,
                    total: questions.count,
                    color: color,
                    combo: combo,
                    selected: $selected
                ) { right in
                    withAnimation {
                        if right {
                            correct += 1
                            combo += 1
                            bestCombo = max(bestCombo, combo)
                            runXP += ProgressStore.dailyXPPerCorrect + (combo >= 3 ? ProgressStore.dailyComboBonus : 0)
                        } else {
                            combo = 0
                        }
                    }
                }
            }
            Button {
                next()
            } label: {
                Text(index + 1 < questions.count ? "Continuer" : "Terminer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(color)
            .disabled(selected == nil)
        }
        .padding(24)
        .id("daily\(index)")
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
    }

    private func next() {
        withAnimation {
            selected = nil
            if index + 1 < questions.count {
                index += 1
            } else {
                runXP += ProgressStore.dailyFinishBonus
                awarded = progress.finishDailyChallenge(xp: runXP)
                finished = true
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundStyle(color)
            Text("Série de \(progress.currentStreak) jours")
                .font(.largeTitle.bold())
            Text("\(correct) sur \(questions.count) justes · meilleur combo \(bestCombo)")
                .font(.headline)
                .foregroundStyle(.secondary)
            if awarded > 0 {
                Text("+\(awarded) XP")
                    .font(.title.bold())
                    .foregroundStyle(color)
            } else {
                Text("Entraînement. Nouveau défi dans \(ProgressStore.hoursUntilTomorrow) h.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            if awarded > 0 {
                ChestView()
            }
            Text("Reviens demain pour garder ta série.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Terminé")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(color)
        }
        .padding(24)
        .overlay {
            if awarded > 0 {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}

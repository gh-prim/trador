import SwiftUI

struct LessonView: View {
    @EnvironmentObject var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson
    let color: Color

    private enum Phase {
        case cards, quiz, result
    }

    @State private var phase: Phase = .cards
    @State private var cardIndex = 0
    @State private var questionIndex = 0
    @State private var selected: Int?
    @State private var correctCount = 0
    @State private var combo = 0
    @State private var earnedXP = 0
    @State private var passed = false

    private var totalSteps: Int { lesson.cards.count + lesson.quiz.count }

    private var currentStep: Int {
        switch phase {
        case .cards: return cardIndex
        case .quiz: return lesson.cards.count + questionIndex
        case .result: return totalSteps
        }
    }

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
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .tint(color)
                    .animation(.easeInOut, value: currentStep)
            }
            .padding()

            switch phase {
            case .cards:
                cardView
            case .quiz:
                quizView
            case .result:
                resultView
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: Cards

    private var cardView: some View {
        let card = lesson.cards[cardIndex]
        return VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: card.icon)
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(RoundedRectangle(cornerRadius: 14).fill(color.gradient))
                        Text(card.title)
                            .font(.title2.bold())
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let visual = card.visual {
                        LessonVisualView(visual: visual, color: color)
                    }
                    Text(card.text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    if let example = card.example {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Exemple", systemImage: "lightbulb.fill")
                                .font(.caption.bold())
                                .foregroundStyle(color)
                            Text(example)
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.12)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 12) {
                if cardIndex > 0 {
                    Button {
                        withAnimation { cardIndex -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 44)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(color)
                }
                Button {
                    withAnimation {
                        if cardIndex + 1 < lesson.cards.count {
                            cardIndex += 1
                        } else {
                            phase = .quiz
                        }
                    }
                } label: {
                    Text(cardIndex + 1 < lesson.cards.count ? "Suivant" : "Commencer le quiz")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(color)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .id("card\(cardIndex)")
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
    }

    // MARK: Quiz

    private var quizView: some View {
        VStack(spacing: 16) {
            ScrollView {
                QuizCard(
                    question: lesson.quiz[questionIndex],
                    number: questionIndex + 1,
                    total: lesson.quiz.count,
                    color: color,
                    combo: combo,
                    selected: $selected
                ) { right in
                    if right {
                        correctCount += 1
                        combo += 1
                    } else {
                        combo = 0
                    }
                }
            }
            Button {
                nextQuestion()
            } label: {
                Text(questionIndex + 1 < lesson.quiz.count ? "Continuer" : "Voir les résultats")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(color)
            .disabled(selected == nil)
        }
        .padding(24)
        .id("question\(questionIndex)")
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
    }

    private func nextQuestion() {
        withAnimation {
            selected = nil
            if questionIndex + 1 < lesson.quiz.count {
                questionIndex += 1
            } else {
                let result = progress.finishLesson(lesson, correct: correctCount)
                earnedXP = result.xp
                passed = result.passed
                phase = .result
            }
        }
    }

    // MARK: Result

    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: passed ? "trophy.fill" : "arrow.counterclockwise.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(passed ? Color.orange : color)
            Text(passed ? "Leçon terminée !" : "Presque")
                .font(.largeTitle.bold())
            Text("\(correctCount) sur \(lesson.quiz.count) justes")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(earnedXP > 0 ? "+\(earnedXP) XP" : "Pas de nouvel XP cette fois")
                .font(.title2.bold())
                .foregroundStyle(Color.orange)
            if !passed {
                let needed = Int((Double(lesson.quiz.count) * ProgressStore.passRatio).rounded(.up))
                Text(needed - correctCount == 1 ? "Si près ! Une seule bonne réponse de plus débloque la leçon suivante." : "Il faut au moins \(needed) bonnes réponses pour débloquer la leçon suivante.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            if passed && earnedXP >= ProgressStore.lessonBonusXP {
                ChestView()
            }
            Spacer()
            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text(passed ? "Continuer" : "Retour")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(color)

                Button {
                    restart()
                } label: {
                    Text("Réessayer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(color)
            }
        }
        .padding(24)
        .overlay {
            if passed {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .transition(.opacity)
    }

    private func restart() {
        withAnimation {
            phase = .cards
            cardIndex = 0
            questionIndex = 0
            selected = nil
            correctCount = 0
            combo = 0
            earnedXP = 0
            passed = false
        }
    }
}

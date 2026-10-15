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
        return VStack(spacing: 24) {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: card.icon)
                        .font(.system(size: 64))
                        .foregroundStyle(color)
                        .padding(.top, 40)
                    Text(card.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(card.text)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
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
                Text(cardIndex + 1 < lesson.cards.count ? "Next" : "Start quiz")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(color)
        }
        .padding(24)
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
                Text(questionIndex + 1 < lesson.quiz.count ? "Continue" : "See results")
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
            Text(passed ? "Lesson complete!" : "Almost there")
                .font(.largeTitle.bold())
            Text("\(correctCount) of \(lesson.quiz.count) correct")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(earnedXP > 0 ? "+\(earnedXP) XP" : "No new XP this time")
                .font(.title2.bold())
                .foregroundStyle(Color.orange)
            if !passed {
                let needed = Int((Double(lesson.quiz.count) * ProgressStore.passRatio).rounded(.up))
                Text(needed - correctCount == 1 ? "So close! Just 1 more right answer unlocks the next lesson." : "Get at least \(needed) right to unlock the next lesson.")
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
                    Text(passed ? "Continue" : "Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(color)

                Button {
                    restart()
                } label: {
                    Text("Try again")
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

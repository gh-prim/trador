import SwiftUI

/// One quiz question with answer buttons, feedback and haptics. Used by lessons and the Daily Challenge.
struct QuizCard: View {
    let question: QuizQuestion
    let number: Int
    let total: Int
    let color: Color
    let combo: Int
    @Binding var selected: Int?
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Question \(number) sur \(total)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if combo >= 2 {
                    Label("\(combo) d'affilée", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color.orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            Text(question.prompt)
                .font(.title3.bold())
                .fixedSize(horizontal: false, vertical: true)

            ForEach(question.options.indices, id: \.self) { index in
                Button {
                    guard selected == nil else { return }
                    withAnimation(.spring(duration: 0.3)) {
                        selected = index
                    }
                    onAnswer(index == question.answer)
                } label: {
                    HStack {
                        Text(question.options[index])
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if let choice = selected {
                            if index == question.answer {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green)
                            } else if index == choice {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(Color.red)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(background(for: index))
                    )
                    .scaleEffect(selected == index && index == question.answer ? 1.03 : 1)
                }
                .buttonStyle(.plain)
            }

            if let choice = selected {
                let right = choice == question.answer
                VStack(alignment: .leading, spacing: 6) {
                    Text(right ? "Bonne réponse !" : "Pas tout à fait")
                        .font(.headline)
                        .foregroundStyle(right ? Color.green : Color.red)
                    Text(question.explanation)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sensoryFeedback(trigger: selected) { _, newValue in
            guard let choice = newValue else { return nil }
            return choice == question.answer ? .success : .error
        }
    }

    private func background(for index: Int) -> Color {
        guard let choice = selected else { return Color(.secondarySystemGroupedBackground) }
        if index == question.answer { return Color.green.opacity(0.2) }
        if index == choice { return Color.red.opacity(0.2) }
        return Color(.secondarySystemGroupedBackground)
    }
}

import SwiftUI

struct ModuleView: View {
    @EnvironmentObject var progress: ProgressStore
    let module: Module
    @State private var activeLesson: Lesson?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: module.icon)
                        .font(.largeTitle)
                        .foregroundStyle(module.color)
                    Text(module.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            Section("Lessons") {
                ForEach(Array(module.lessons.enumerated()), id: \.element.id) { index, lesson in
                    let unlocked = progress.isUnlocked(lesson: lesson, in: module)
                    let done = progress.isCompleted(lesson)
                    Button {
                        activeLesson = lesson
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: done ? "checkmark.circle.fill" : (unlocked ? "play.circle.fill" : "lock.circle.fill"))
                                .font(.title)
                                .foregroundStyle(done ? Color.green : (unlocked ? module.color : Color.gray))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(index + 1). \(lesson.title)")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                                Text(lesson.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let best = progress.bestScores[lesson.id] {
                                Text("\(best)/\(lesson.quiz.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(!unlocked)
                }
            }
        }
        .navigationTitle(module.title)
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonView(lesson: lesson, color: module.color)
                .environmentObject(progress)
        }
    }
}

import SwiftUI

struct LearnView: View {
    @EnvironmentObject var progress: ProgressStore
    @State private var showDaily = false
    @State private var quickLesson: Lesson?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StreakHeader()
                    XPHeader()
                    dailyChallengeCard
                    if let next = progress.nextLesson {
                        continueCard(module: next.module, lesson: next.lesson)
                    }
                    ForEach(Array(Curriculum.modules.enumerated()), id: \.element.id) { index, module in
                        let unlocked = progress.isUnlocked(module: module)
                        NavigationLink(value: module.id) {
                            ModuleCard(module: module, number: index + 1, unlocked: unlocked)
                        }
                        .buttonStyle(.plain)
                        .disabled(!unlocked)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trador")
            .navigationDestination(for: String.self) { id in
                if let module = Curriculum.module(id: id) {
                    ModuleView(module: module)
                }
            }
            .fullScreenCover(isPresented: $showDaily) {
                DailyChallengeView()
                    .environmentObject(progress)
            }
            .fullScreenCover(item: $quickLesson) { lesson in
                LessonView(lesson: lesson, color: progress.nextLessonColor(for: lesson))
                    .environmentObject(progress)
            }
        }
    }

    private var dailyChallengeCard: some View {
        let done = progress.dailyChallengeDoneToday
        return Button {
            showDaily = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: done ? "checkmark.circle.fill" : "bolt.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(done ? Color.green : Color.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Challenge")
                        .font(.headline)
                    Text(done ? "Done! New one in \(ProgressStore.hoursUntilTomorrow)h. Play again for practice." : "5 quick questions, combo bonus, mystery chest.")
                        .font(.subheadline)
                        .opacity(0.9)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(done ? Color.primary : Color.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(done ? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                               : AnyShapeStyle(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)))
            )
        }
        .buttonStyle(.plain)
    }

    private func continueCard(module: Module, lesson: Lesson) -> some View {
        Button {
            quickLesson = lesson
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(module.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue: \(module.title)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text("+\(ProgressStore.lessonBonusXP + lesson.quiz.count * ProgressStore.xpPerCorrectAnswer) XP and a mystery chest")
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                }
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }
}

/// Streak flame and daily goal ring. Loss aversion keeps players coming back.
struct StreakHeader: View {
    @EnvironmentObject var progress: ProgressStore

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress.dailyGoalProgress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(progress.playedToday ? Color.orange : Color.gray)
                    .symbolEffect(.pulse, isActive: progress.streakAtRisk)
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(progress.currentStreak) day streak")
                    .font(.title3.bold())
                if progress.streakAtRisk {
                    Text("Play today or lose your streak!")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.red)
                } else {
                    Text("Daily goal: \(min(progress.todayXP, ProgressStore.dailyGoal))/\(ProgressStore.dailyGoal) XP")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if progress.streakFreezes > 0 {
                Label("\(progress.streakFreezes)", systemImage: "snowflake")
                    .font(.headline)
                    .foregroundStyle(Color.cyan)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .animation(.easeOut, value: progress.dailyGoalProgress)
    }
}

struct XPHeader: View {
    @EnvironmentObject var progress: ProgressStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Level \(progress.level)")
                        .font(.title2.bold())
                    Text(progress.rankTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label("\(progress.xp) XP", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundStyle(Color.orange)
            }
            ProgressView(value: progress.levelProgress)
                .tint(.orange)
            Text("\(progress.xpToNextLevel) XP to level \(progress.level + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}

struct ModuleCard: View {
    @EnvironmentObject var progress: ProgressStore
    let module: Module
    let number: Int
    let unlocked: Bool

    var body: some View {
        let done = progress.completedCount(in: module)
        let total = module.lessons.count
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(unlocked ? module.color : Color.gray.opacity(0.4))
                    .frame(width: 56, height: 56)
                Image(systemName: unlocked ? module.icon : "lock.fill")
                    .font(.title2)
                    .foregroundStyle(Color.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Module \(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(module.title)
                    .font(.headline)
                Text(unlocked ? module.subtitle : "Finish the previous module to unlock.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressView(value: Double(done), total: Double(total))
                    .tint(module.color)
                Text("\(done)/\(total) lessons")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if done == total {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .opacity(unlocked ? 1 : 0.7)
    }
}

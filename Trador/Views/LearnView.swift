import SwiftUI

struct LearnView: View {
    @EnvironmentObject var progress: ProgressStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    XPHeader()
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
        }
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

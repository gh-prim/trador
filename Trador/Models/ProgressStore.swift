import Foundation

/// Saves XP, finished lessons and missions on the device.
final class ProgressStore: ObservableObject {
    @Published private(set) var xp: Int = 0
    @Published private(set) var completedLessons: Set<String> = []
    @Published private(set) var bestScores: [String: Int] = [:]
    @Published private(set) var completedMissions: Set<String> = []

    static let xpPerCorrectAnswer = 10
    static let lessonBonusXP = 25
    static let xpPerLevel = 100
    static let passRatio = 0.6

    private let storageKey = "trador.progress.v1"

    private struct Snapshot: Codable {
        var xp: Int
        var completedLessons: [String]
        var bestScores: [String: Int]
        var completedMissions: [String]
    }

    init() {
        load()
    }

    // MARK: Levels

    var level: Int { xp / Self.xpPerLevel + 1 }

    var levelProgress: Double {
        Double(xp % Self.xpPerLevel) / Double(Self.xpPerLevel)
    }

    var xpToNextLevel: Int { Self.xpPerLevel - xp % Self.xpPerLevel }

    var rankTitle: String {
        switch level {
        case 1: return "Rookie"
        case 2: return "Paper Trader"
        case 3...4: return "Chart Reader"
        case 5...6: return "Risk Manager"
        case 7...8: return "Options Apprentice"
        case 9...11: return "Futures Pro"
        case 12...14: return "Perp Master"
        default: return "Derivatives Guru"
        }
    }

    // MARK: Lessons

    func isCompleted(_ lesson: Lesson) -> Bool {
        completedLessons.contains(lesson.id)
    }

    func completedCount(in module: Module) -> Int {
        module.lessons.filter { isCompleted($0) }.count
    }

    func isUnlocked(module: Module) -> Bool {
        guard let index = Curriculum.modules.firstIndex(where: { $0.id == module.id }) else { return false }
        if index == 0 { return true }
        let previous = Curriculum.modules[index - 1]
        return completedCount(in: previous) == previous.lessons.count
    }

    func isUnlocked(lesson: Lesson, in module: Module) -> Bool {
        guard isUnlocked(module: module),
              let index = module.lessons.firstIndex(where: { $0.id == lesson.id }) else { return false }
        if index == 0 { return true }
        return isCompleted(module.lessons[index - 1])
    }

    /// Records a quiz result. XP is only given for beating your best score, so replays cannot farm XP.
    func finishLesson(_ lesson: Lesson, correct: Int) -> (xp: Int, passed: Bool) {
        let total = max(lesson.quiz.count, 1)
        let passed = Double(correct) / Double(total) >= Self.passRatio
        let previousBest = bestScores[lesson.id] ?? 0
        var earned = max(0, correct - previousBest) * Self.xpPerCorrectAnswer
        if correct > previousBest {
            bestScores[lesson.id] = correct
        }
        if passed && !completedLessons.contains(lesson.id) {
            completedLessons.insert(lesson.id)
            earned += Self.lessonBonusXP
        }
        xp += earned
        save()
        return (earned, passed)
    }

    // MARK: Missions

    func isMissionDone(_ mission: Mission) -> Bool {
        completedMissions.contains(mission.id)
    }

    /// Returns the mission the first time it is completed, nil otherwise.
    func completeMission(_ id: String) -> Mission? {
        guard !completedMissions.contains(id),
              let mission = Missions.all.first(where: { $0.id == id }) else { return nil }
        completedMissions.insert(id)
        xp += mission.xp
        save()
        return mission
    }

    // MARK: Storage

    func resetAll() {
        xp = 0
        completedLessons = []
        bestScores = [:]
        completedMissions = []
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        xp = snapshot.xp
        completedLessons = Set(snapshot.completedLessons)
        bestScores = snapshot.bestScores
        completedMissions = Set(snapshot.completedMissions)
    }

    private func save() {
        let snapshot = Snapshot(
            xp: xp,
            completedLessons: Array(completedLessons),
            bestScores: bestScores,
            completedMissions: Array(completedMissions)
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

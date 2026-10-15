import SwiftUI

/// A surprise reward. Unpredictable rewards are the strongest dopamine trigger in games.
enum ChestRarity: String, CaseIterable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    var xp: Int {
        switch self {
        case .common: return 10
        case .rare: return 25
        case .epic: return 60
        case .legendary: return 150
        }
    }

    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }

    /// Epic and Legendary chests also give a streak freeze.
    var givesFreeze: Bool { self == .epic || self == .legendary }

    static func roll() -> ChestRarity {
        let r = Double.random(in: 0..<1)
        if r < 0.03 { return .legendary }
        if r < 0.15 { return .epic }
        if r < 0.45 { return .rare }
        return .common
    }
}

/// Saves XP, streaks, finished lessons and missions on the device.
final class ProgressStore: ObservableObject {
    @Published private(set) var xp: Int = 0
    @Published private(set) var completedLessons: Set<String> = []
    @Published private(set) var bestScores: [String: Int] = [:]
    @Published private(set) var completedMissions: Set<String> = []
    @Published private(set) var streak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var lastActiveDay: String?
    @Published private(set) var dailyXP: Int = 0
    @Published private(set) var dailyXPDay: String?
    @Published private(set) var dailyChallengeDay: String?
    @Published private(set) var streakFreezes: Int = 0
    @Published private(set) var chestsOpened: Int = 0
    /// Set when the player reaches a new level, so the app can celebrate.
    @Published var levelUp: Int?

    static let xpPerCorrectAnswer = 10
    static let lessonBonusXP = 25
    static let xpPerLevel = 100
    static let passRatio = 0.6
    static let dailyGoal = 50
    static let dailyChallengeSize = 5
    static let dailyXPPerCorrect = 15
    static let dailyComboBonus = 10
    static let dailyFinishBonus = 30

    private let storageKey = "trador.progress.v1"

    private struct Snapshot: Codable {
        var xp: Int
        var completedLessons: [String]
        var bestScores: [String: Int]
        var completedMissions: [String]
        var streak: Int?
        var bestStreak: Int?
        var lastActiveDay: String?
        var dailyXP: Int?
        var dailyXPDay: String?
        var dailyChallengeDay: String?
        var streakFreezes: Int?
        var chestsOpened: Int?
    }

    init() {
        load()
    }

    // MARK: Days

    static func dayString(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static var today: String { dayString(Date()) }

    private static var yesterday: String { daysAgo(1) }

    private static func daysAgo(_ days: Int) -> String {
        dayString(Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date())
    }

    /// Hours left until a new Daily Challenge.
    static var hoursUntilTomorrow: Int {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else { return 24 }
        return max(1, Int(ceil(tomorrow.timeIntervalSinceNow / 3600)))
    }

    // MARK: Levels

    var level: Int { xp / Self.xpPerLevel + 1 }

    var levelProgress: Double {
        Double(xp % Self.xpPerLevel) / Double(Self.xpPerLevel)
    }

    var xpToNextLevel: Int { Self.xpPerLevel - xp % Self.xpPerLevel }

    var rankTitle: String { Self.rank(for: level) }

    static func rank(for level: Int) -> String {
        switch level {
        case 1: return "Rookie"
        case 2: return "Paper Trader"
        case 3...4: return "Chart Reader"
        case 5...6: return "Risk Manager"
        case 7...8: return "Options Apprentice"
        case 9...11: return "Futures Pro"
        case 12...14: return "Perp Master"
        case 15...19: return "Hedge Wizard"
        default: return "Derivatives Legend"
        }
    }

    // MARK: Streak and daily goal

    /// The streak only counts if you played today or yesterday (or two days ago with a freeze ready).
    var currentStreak: Int {
        guard let last = lastActiveDay else { return 0 }
        if last == Self.today || last == Self.yesterday { return streak }
        if last == Self.daysAgo(2) && streakFreezes > 0 { return streak }
        return 0
    }

    /// True when the streak will be lost if you do not play today.
    var streakAtRisk: Bool { currentStreak > 0 && !playedToday }

    var playedToday: Bool { lastActiveDay == Self.today }

    var todayXP: Int { dailyXPDay == Self.today ? dailyXP : 0 }

    var dailyGoalProgress: Double {
        min(1, Double(todayXP) / Double(Self.dailyGoal))
    }

    var dailyChallengeDoneToday: Bool { dailyChallengeDay == Self.today }

    /// Every XP gain goes through here so streaks, daily goal and level ups stay in sync.
    private func award(_ amount: Int) {
        guard amount > 0 else { return }
        let oldLevel = level
        xp += amount

        let today = Self.today
        if dailyXPDay != today {
            dailyXPDay = today
            dailyXP = 0
        }
        dailyXP += amount

        if lastActiveDay != today {
            if lastActiveDay == Self.yesterday {
                streak += 1
            } else if lastActiveDay == Self.daysAgo(2) && streakFreezes > 0 {
                // A freeze covers the missed day.
                streakFreezes -= 1
                streak += 1
            } else {
                streak = 1
            }
            lastActiveDay = today
            bestStreak = max(bestStreak, streak)
        }

        if level > oldLevel {
            levelUp = level
        }
        save()

        if streak >= 3 { _ = completeMission("streak_3") }
        if streak >= 7 { _ = completeMission("streak_7") }
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

    /// The next lesson to play, for the "Continue" button.
    var nextLesson: (module: Module, lesson: Lesson)? {
        for module in Curriculum.modules where isUnlocked(module: module) {
            for lesson in module.lessons where !isCompleted(lesson) && isUnlocked(lesson: lesson, in: module) {
                return (module, lesson)
            }
        }
        return nil
    }

    func nextLessonColor(for lesson: Lesson) -> Color {
        Curriculum.modules.first { $0.lessons.contains { $0.id == lesson.id } }?.color ?? .blue
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
        if earned > 0 {
            award(earned)
        } else {
            save()
        }
        return (earned, passed)
    }

    // MARK: Daily challenge

    /// Random questions from lessons you finished. Falls back to the first lesson for new players.
    func dailyQuestions() -> [QuizQuestion] {
        let finished = Curriculum.modules.flatMap(\.lessons).filter { isCompleted($0) }
        let pool = finished.isEmpty ? (Curriculum.modules.first?.lessons.first?.quiz ?? []) : finished.flatMap(\.quiz)
        return Array(pool.shuffled().prefix(Self.dailyChallengeSize))
    }

    /// Gives the XP once per day. Returns what was actually awarded.
    func finishDailyChallenge(xp earned: Int) -> Int {
        guard !dailyChallengeDoneToday else { return 0 }
        dailyChallengeDay = Self.today
        award(earned)
        _ = completeMission("daily_done")
        return earned
    }

    // MARK: Chests

    /// Opens a mystery chest and gives its reward.
    func openChest() -> ChestRarity {
        let rarity = ChestRarity.roll()
        chestsOpened += 1
        if rarity.givesFreeze { streakFreezes += 1 }
        award(rarity.xp)
        save()
        return rarity
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
        award(mission.xp)
        return mission
    }

    // MARK: Storage

    func resetAll() {
        xp = 0
        completedLessons = []
        bestScores = [:]
        completedMissions = []
        streak = 0
        bestStreak = 0
        lastActiveDay = nil
        dailyXP = 0
        dailyXPDay = nil
        dailyChallengeDay = nil
        streakFreezes = 0
        chestsOpened = 0
        levelUp = nil
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        xp = snapshot.xp
        completedLessons = Set(snapshot.completedLessons)
        bestScores = snapshot.bestScores
        completedMissions = Set(snapshot.completedMissions)
        streak = snapshot.streak ?? 0
        bestStreak = snapshot.bestStreak ?? 0
        lastActiveDay = snapshot.lastActiveDay
        dailyXP = snapshot.dailyXP ?? 0
        dailyXPDay = snapshot.dailyXPDay
        dailyChallengeDay = snapshot.dailyChallengeDay
        streakFreezes = snapshot.streakFreezes ?? 0
        chestsOpened = snapshot.chestsOpened ?? 0
    }

    private func save() {
        let snapshot = Snapshot(
            xp: xp,
            completedLessons: Array(completedLessons),
            bestScores: bestScores,
            completedMissions: Array(completedMissions),
            streak: streak,
            bestStreak: bestStreak,
            lastActiveDay: lastActiveDay,
            dailyXP: dailyXP,
            dailyXPDay: dailyXPDay,
            dailyChallengeDay: dailyChallengeDay,
            streakFreezes: streakFreezes,
            chestsOpened: chestsOpened
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

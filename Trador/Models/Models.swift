import SwiftUI

struct LessonCard: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let text: String
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let options: [String]
    let answer: Int
    let explanation: String
}

struct Lesson: Identifiable {
    let id: String
    let title: String
    let summary: String
    let cards: [LessonCard]
    let quiz: [QuizQuestion]
}

struct Module: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let lessons: [Lesson]
}

struct Mission: Identifiable {
    let id: String
    let title: String
    let detail: String
    let xp: Int
}

struct GlossaryTerm: Identifiable {
    var id: String { term }
    let term: String
    let definition: String
}

enum Fmt {
    static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }

    static func signedMoney(_ value: Double) -> String {
        (value >= 0 ? "+" : "") + money(value)
    }

    static func price(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    static func percent(_ value: Double) -> String {
        String(format: "%+.1f%%", value * 100)
    }

    static func rate(_ value: Double) -> String {
        String(format: "%+.3f%%", value * 100)
    }
}

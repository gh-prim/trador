import SwiftUI

struct LessonCard: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let text: String
    /// Optional worked example shown in a highlighted box.
    var example: String? = nil
    /// Optional interactive chart or animation shown above the text.
    var visual: LessonVisual? = nil
}

/// Payoff diagrams at expiry. Underlying starts at 100.
enum PayoffKind: Equatable {
    case longSpot
    case shortSpot
    case longCall(strike: Double, premium: Double)
    case longPut(strike: Double, premium: Double)
    case shortCall(strike: Double, premium: Double)
    case protectivePut(strike: Double, premium: Double)
    case coveredCall(strike: Double, premium: Double)
    case collar(putStrike: Double, callStrike: Double)
    case longFuture
    case shortFuture
}

/// Interactive visuals that explain a concept with a chart or animation.
enum LessonVisual: Equatable {
    /// Order book ladder with bids, asks and the spread.
    case orderBook
    /// Slider for exit price, shows P&L for a long and a short.
    case longVsShort
    /// Price chart with a limit buy, stop loss and take profit.
    case orderTypes
    /// Bars: lose X% then need Y% to recover. Slider for the loss.
    case lossRecovery
    /// Risk vs reward bars and a win rate slider showing expected profit.
    case riskReward
    /// Underlying price slider moving a derivative (call) value.
    case derivativeLink
    /// Hedger vs speculator: price moves, hedged and unhedged results.
    case hedgeVsSpeculate
    /// Leverage and price move sliders, margin P&L and liquidation.
    case leverage
    /// Payoff diagram with a draggable price at expiry.
    case payoff(PayoffKind)
    /// Spot slider vs a 100 strike: ITM, ATM, OTM for calls and puts.
    case moneyness
    /// Option value melting as expiry approaches (theta).
    case timeDecay
    /// Calm vs wild price paths and their option prices (vega).
    case volatility
    /// Delta: option price moves less than the underlying.
    case delta
    /// Futures price converging to spot as expiry approaches.
    case futuresConvergence
    /// Daily mark to market: margin balance with a margin call line.
    case markToMarket
    /// Perp vs spot gap slider, who pays funding and how much.
    case funding
    /// Animated price path hitting the liquidation price.
    case liquidation
    /// Spot + short hedge = flat total line.
    case deltaNeutral
    /// Two assets with a correlation slider.
    case correlation
    /// Timeline of market history with one event highlighted (index into HistoryTimeline.events).
    case timeline(highlight: Int)
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

import Foundation

enum InstrumentKind: String, CaseIterable, Identifiable {
    case spot = "Spot"
    case option = "Option"
    case future = "Future"
    case perp = "Perp"

    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .spot:
            return "Tu achètes le coin lui-même. Pas de levier, pas de liquidation. Tu gagnes si le prix monte."
        case .option:
            return "Tu paies une prime pour le droit d'acheter (call) ou de vendre (put) au strike. Ta perte max est la prime."
        case .future:
            return "Long ou short avec levier. Expire dans \(MarketSim.futureLife) ticks et se règle au prix spot."
        case .perp:
            return "Comme un future sans échéance. Le funding est payé tous les \(MarketSim.fundingInterval) ticks."
        }
    }
}

enum Side: String, CaseIterable, Identifiable {
    case long = "Long"
    case short = "Short"

    var id: String { rawValue }
    var sign: Double { self == .long ? 1 : -1 }
}

enum OptionType: String, CaseIterable, Identifiable {
    case call = "Call"
    case put = "Put"

    var id: String { rawValue }
}

enum StrikeChoice: String, CaseIterable, Identifiable {
    case itm = "ITM"
    case atm = "ATM"
    case otm = "OTM"

    var id: String { rawValue }
}

struct Position: Identifiable {
    let id = UUID()
    let kind: InstrumentKind
    let side: Side
    let quantity: Double
    /// Price paid per unit. For options this is the premium.
    let entryPrice: Double
    /// Cash locked in the trade (cost, margin or premium).
    let margin: Double
    let leverage: Double
    let openedTick: Int
    var optionType: OptionType? = nil
    var strike: Double = 0
    var expiryTick: Int? = nil
    /// Positive means you paid funding, negative means you received it.
    var fundingPaid: Double = 0

    var title: String {
        switch kind {
        case .spot:
            return "Spot TDC"
        case .option:
            return "\(optionType?.rawValue ?? "") \(Fmt.price(strike))"
        case .future, .perp:
            return "\(kind.rawValue) \(side.rawValue) \(Int(leverage))x"
        }
    }

    var isLeveraged: Bool { kind == .future || kind == .perp }

    /// Price where the trade gets closed by the exchange (ignores funding).
    var liquidationPrice: Double? {
        guard isLeveraged else { return nil }
        let room = (1 - MarketSim.maintenanceRatio) / leverage
        return side == .long ? entryPrice * (1 - room) : entryPrice * (1 + room)
    }
}

/// A finished trade, kept for the history list.
struct ClosedTrade: Identifiable, Codable {
    var id = UUID()
    let title: String
    let pnl: Double
    let margin: Double
    let reason: String
    let date: Date

    var returnRatio: Double { margin > 0 ? pnl / margin : 0 }
}

/// A fake market for a made up coin called TDC. Prices follow a random walk.
final class MarketSim: ObservableObject {
    static let startingCash = 10_000.0
    static let fundingInterval = 8
    static let optionLife = 30
    static let futureLife = 40
    static let tickVolatility = 0.012
    static let maintenanceRatio = 0.1
    static let futureCarryPerTick = 0.0004
    private static let cashKey = "trador.market.cash"
    private static let tradesKey = "trador.market.trades"
    static let maxSavedTrades = 100

    @Published private(set) var tick = 0
    @Published private(set) var history: [Double] = []
    @Published private(set) var cash: Double
    @Published private(set) var positions: [Position] = []
    @Published private(set) var fundingRate = 0.0003
    @Published private(set) var realizedPnL = 0.0
    @Published private(set) var closedTrades: [ClosedTrade] = []
    @Published var banner: String?

    /// Called with a mission id when the player does something a mission asks for.
    var onMission: ((String) -> Void)?

    private var drift = 0.0

    init() {
        let saved = UserDefaults.standard.object(forKey: Self.cashKey) as? Double
        cash = saved ?? Self.startingCash
        var price = 100.0
        var start: [Double] = []
        for _ in 0..<60 {
            price = Self.step(price, drift: 0)
            start.append(price)
        }
        history = start
        if let data = UserDefaults.standard.data(forKey: Self.tradesKey),
           let saved = try? JSONDecoder().decode([ClosedTrade].self, from: data) {
            closedTrades = saved
        }
    }

    // MARK: Stats

    var winRate: Double {
        guard !closedTrades.isEmpty else { return 0 }
        return Double(closedTrades.filter { $0.pnl > 0 }.count) / Double(closedTrades.count)
    }

    var bestTrade: ClosedTrade? { closedTrades.max { $0.pnl < $1.pnl } }

    /// Wins in a row, counting back from the latest trade.
    var winStreak: Int {
        var count = 0
        for trade in closedTrades {
            guard trade.pnl > 0 else { break }
            count += 1
        }
        return count
    }

    private func record(_ position: Position, pnl: Double, reason: String) {
        let trade = ClosedTrade(title: position.title, pnl: pnl, margin: position.margin, reason: reason, date: Date())
        closedTrades.insert(trade, at: 0)
        if closedTrades.count > Self.maxSavedTrades {
            closedTrades.removeLast(closedTrades.count - Self.maxSavedTrades)
        }
        if let data = try? JSONEncoder().encode(closedTrades) {
            UserDefaults.standard.set(data, forKey: Self.tradesKey)
        }
    }

    var price: Double { history.last ?? 100 }

    var ticksToFunding: Int {
        Self.fundingInterval - tick % Self.fundingInterval
    }

    var openValue: Double {
        positions.reduce(0) { $0 + max(0, $1.margin + pnl($1)) }
    }

    // MARK: Pricing

    private static func gaussian() -> Double {
        let u1 = Double.random(in: 0.0001..<1)
        let u2 = Double.random(in: 0..<1)
        return sqrt(-2 * log(u1)) * cos(2 * Double.pi * u2)
    }

    private static func step(_ price: Double, drift: Double) -> Double {
        let move = drift + tickVolatility * gaussian()
        return max(1, price * exp(move))
    }

    func futurePrice(ticksLeft: Int) -> Double {
        price * (1 + Self.futureCarryPerTick * Double(max(ticksLeft, 0)))
    }

    /// Simple option model (Bachelier). Time value shrinks as expiry gets closer.
    static func optionValue(type: OptionType, spot: Double, strike: Double, ticksLeft: Int) -> Double {
        let spread = spot * tickVolatility * sqrt(Double(max(ticksLeft, 0)))
        let callIntrinsic = spot - strike
        if spread < 1e-9 {
            return type == .call ? max(0, callIntrinsic) : max(0, -callIntrinsic)
        }
        let d = callIntrinsic / spread
        let pdf = exp(-0.5 * d * d) / sqrt(2 * Double.pi)
        let cdf = 0.5 * (1 + erf(d / sqrt(2)))
        switch type {
        case .call:
            return callIntrinsic * cdf + spread * pdf
        case .put:
            return -callIntrinsic * (1 - cdf) + spread * pdf
        }
    }

    func strike(for type: OptionType, choice: StrikeChoice) -> Double {
        let raw: Double
        switch (type, choice) {
        case (_, .atm): raw = price
        case (.call, .itm), (.put, .otm): raw = price * 0.95
        case (.call, .otm), (.put, .itm): raw = price * 1.05
        }
        return (raw * 2).rounded() / 2
    }

    func markPrice(_ position: Position) -> Double {
        switch position.kind {
        case .spot, .perp:
            return price
        case .future:
            return futurePrice(ticksLeft: (position.expiryTick ?? tick) - tick)
        case .option:
            return Self.optionValue(
                type: position.optionType ?? .call,
                spot: price,
                strike: position.strike,
                ticksLeft: (position.expiryTick ?? tick) - tick
            )
        }
    }

    func pnl(_ position: Position) -> Double {
        let move = markPrice(position) - position.entryPrice
        return position.side.sign * move * position.quantity - position.fundingPaid
    }

    // MARK: Trading

    func open(kind: InstrumentKind, side: Side, amount: Double, leverage: Double,
              optionType: OptionType, strikeChoice: StrikeChoice) {
        guard amount > 0, amount <= cash + 0.001 else {
            banner = "Pas assez de liquidités pour ce trade"
            return
        }
        let position: Position
        switch kind {
        case .spot:
            position = Position(kind: .spot, side: .long, quantity: amount / price, entryPrice: price,
                                margin: amount, leverage: 1, openedTick: tick)
        case .perp:
            position = Position(kind: .perp, side: side, quantity: amount * leverage / price, entryPrice: price,
                                margin: amount, leverage: leverage, openedTick: tick)
        case .future:
            let entry = futurePrice(ticksLeft: Self.futureLife)
            position = Position(kind: .future, side: side, quantity: amount * leverage / entry, entryPrice: entry,
                                margin: amount, leverage: leverage, openedTick: tick,
                                expiryTick: tick + Self.futureLife)
        case .option:
            let strikePrice = strike(for: optionType, choice: strikeChoice)
            let premium = max(0.01, Self.optionValue(type: optionType, spot: price, strike: strikePrice,
                                                     ticksLeft: Self.optionLife))
            position = Position(kind: .option, side: .long, quantity: amount / premium, entryPrice: premium,
                                margin: amount, leverage: 1, openedTick: tick, optionType: optionType,
                                strike: strikePrice, expiryTick: tick + Self.optionLife)
        }
        cash -= amount
        positions.insert(position, at: 0)
        saveCash()
        banner = "Ouvert : \(position.title)"
        onMission?("first_trade")
        checkHedges()
    }

    /// Hedging missions: a spot coin protected by a put, or by a short future or perp.
    private func checkHedges() {
        guard positions.contains(where: { $0.kind == .spot }) else { return }
        if positions.contains(where: { $0.kind == .option && $0.optionType == .put }) {
            onMission?("hedge_put")
        }
        if positions.contains(where: { $0.isLeveraged && $0.side == .short }) {
            onMission?("hedge_short")
        }
    }

    func close(_ id: UUID) {
        guard let index = positions.firstIndex(where: { $0.id == id }) else { return }
        settle(at: index, reason: "Clôturé")
    }

    private func settle(at index: Int, reason: String) {
        let position = positions[index]
        let profit = pnl(position)
        let payout = max(0, position.margin + profit)
        cash += payout
        realizedPnL += payout - position.margin
        positions.remove(at: index)
        saveCash()
        record(position, pnl: payout - position.margin, reason: reason)
        let streakNote = winStreak >= 2 ? "  |  \(winStreak) gains d'affilée !" : ""
        banner = "\(reason) \(position.title): \(Fmt.signedMoney(payout - position.margin))\(streakNote)"

        if position.kind == .future && reason == "Réglé" {
            onMission?("future_expiry")
        }
        guard profit > 0 else { return }
        if position.kind == .spot { onMission?("spot_profit") }
        if position.side == .short { onMission?("short_profit") }
        if position.kind == .option {
            onMission?(position.optionType == .put ? "put_profit" : "call_profit")
        }
        if position.kind == .perp && position.leverage >= 10 { onMission?("lev_profit") }
    }

    // MARK: Time

    func advance() {
        if Int.random(in: 0..<15) == 0 {
            drift = Double.random(in: -0.004...0.004)
        }
        tick += 1
        history.append(Self.step(price, drift: drift))
        if history.count > 120 {
            history.removeFirst(history.count - 120)
        }
        if tick % Self.fundingInterval == 0 {
            applyFunding()
        }
        settleExpiries()
        checkLiquidations()
        saveCash()
    }

    private func applyFunding() {
        var received = false
        for i in positions.indices where positions[i].kind == .perp {
            let payment = positions[i].side.sign * fundingRate * positions[i].quantity * price
            positions[i].fundingPaid += payment
            if payment < 0 { received = true }
        }
        if positions.contains(where: { $0.kind == .perp }) {
            banner = "Funding \(Fmt.rate(fundingRate)): " + (fundingRate >= 0 ? "les longs ont payé les shorts" : "les shorts ont payé les longs")
        }
        if received { onMission?("funding_received") }
        // Usually positive, like real markets where traders lean long.
        fundingRate = Double.random(in: -0.0008...0.0012)
    }

    private func settleExpiries() {
        let due = positions.filter { ($0.expiryTick ?? Int.max) <= tick }.map(\.id)
        for id in due {
            if let index = positions.firstIndex(where: { $0.id == id }) {
                settle(at: index, reason: "Réglé")
            }
        }
    }

    private func checkLiquidations() {
        let liquidated = positions.filter {
            $0.isLeveraged && $0.margin + pnl($0) <= $0.margin * Self.maintenanceRatio
        }
        for position in liquidated {
            positions.removeAll { $0.id == position.id }
            realizedPnL -= position.margin
            record(position, pnl: -position.margin, reason: "Liquidé")
            banner = "Liquidé ! \(position.title) a perdu \(Fmt.money(position.margin))"
        }
    }

    func resetAccount() {
        cash = Self.startingCash
        positions = []
        realizedPnL = 0
        closedTrades = []
        UserDefaults.standard.removeObject(forKey: Self.tradesKey)
        saveCash()
        banner = "Compte remis à \(Fmt.money(Self.startingCash))"
    }

    /// Open trades are not saved, so their current value goes back to cash on the next launch.
    private func saveCash() {
        UserDefaults.standard.set(cash + openValue, forKey: Self.cashKey)
    }
}

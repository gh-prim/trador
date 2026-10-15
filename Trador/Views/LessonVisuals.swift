import SwiftUI
import Charts

// MARK: - Entry point

/// Draws the interactive chart or animation attached to a lesson card.
struct LessonVisualView: View {
    let visual: LessonVisual
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .tint(color)
    }

    @ViewBuilder
    private var content: some View {
        switch visual {
        case .orderBook: OrderBookVisual()
        case .longVsShort: LongVsShortVisual()
        case .orderTypes: OrderTypesVisual()
        case .lossRecovery: LossRecoveryVisual()
        case .riskReward: RiskRewardVisual()
        case .derivativeLink: DerivativeLinkVisual()
        case .hedgeVsSpeculate: HedgeVsSpeculateVisual()
        case .leverage: LeverageVisual()
        case .payoff(let kind): PayoffVisual(kind: kind)
        case .moneyness: MoneynessVisual()
        case .timeDecay: TimeDecayVisual()
        case .volatility: VolatilityVisual()
        case .delta: DeltaVisual()
        case .futuresConvergence: FuturesConvergenceVisual()
        case .markToMarket: MarkToMarketVisual()
        case .funding: FundingVisual()
        case .liquidation: LiquidationVisual()
        case .deltaNeutral: DeltaNeutralVisual()
        case .correlation: CorrelationVisual()
        case .timeline(let highlight): TimelineVisual(highlight: highlight)
        }
    }
}

// MARK: - Helpers

/// Repeatable random numbers so charts look the same every time.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

enum VisualMath {
    static func gaussian(_ rng: inout SeededGenerator) -> Double {
        let u1 = Double.random(in: 0.0001..<1, using: &rng)
        let u2 = Double.random(in: 0..<1, using: &rng)
        return sqrt(-2 * log(u1)) * cos(2 * Double.pi * u2)
    }

    static func randomPath(seed: UInt64, count: Int, start: Double, vol: Double, drift: Double = 0) -> [Double] {
        var rng = SeededGenerator(seed: seed)
        var price = start
        var path: [Double] = [start]
        for _ in 1..<count {
            price *= exp(drift + vol * gaussian(&rng))
            path.append(price)
        }
        return path
    }

    static func normalCDF(_ x: Double) -> Double { 0.5 * (1 + erf(x / sqrt(2))) }
    static func normalPDF(_ x: Double) -> Double { exp(-0.5 * x * x) / sqrt(2 * Double.pi) }

    /// Simple option price. `spread` is the expected move size (spot x vol x sqrt(time)).
    static func callValue(spot: Double, strike: Double, spread: Double) -> Double {
        guard spread > 1e-9 else { return max(0, spot - strike) }
        let d = (spot - strike) / spread
        return (spot - strike) * normalCDF(d) + spread * normalPDF(d)
    }
}

/// Label + big value pair used across visuals.
struct ValueBadge: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemGroupedBackground)))
    }
}

struct VisualTitle: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "hand.tap.fill")
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }
}

private func dollars(_ value: Double, decimals: Int = 0) -> String {
    String(format: "%.\(decimals)f $", value)
}

private func signedDollars(_ value: Double, decimals: Int = 0) -> String {
    String(format: "%+.\(decimals)f $", value)
}

private func pnlColor(_ value: Double) -> Color {
    value > 0.0001 ? .green : (value < -0.0001 ? .red : .secondary)
}

// MARK: - Order book

struct OrderBookVisual: View {
    @State private var side: Int = 0
    @State private var appeared = false

    private let asks: [(Double, Double)] = [(101.4, 0.5), (101.3, 0.8), (101.2, 0.4), (101.1, 0.9), (101.0, 0.6)]
    private let bids: [(Double, Double)] = [(100.0, 0.7), (99.9, 1.0), (99.8, 0.5), (99.7, 0.8), (99.6, 0.4)]

    var body: some View {
        VisualTitle(text: "Carnet d'ordres : touche Acheter ou Vendre")
        VStack(spacing: 3) {
            ForEach(asks.indices, id: \.self) { i in
                row(price: asks[i].0, size: asks[i].1, color: .red, best: i == asks.count - 1 && side == 1)
            }
            HStack {
                Rectangle().fill(Color.orange).frame(height: 1)
                Text("Spread 1,00 $")
                    .font(.caption.bold())
                    .foregroundStyle(Color.orange)
                Rectangle().fill(Color.orange).frame(height: 1)
            }
            .padding(.vertical, 2)
            ForEach(bids.indices, id: \.self) { i in
                row(price: bids[i].0, size: bids[i].1, color: .green, best: i == 0 && side == 2)
            }
        }
        HStack {
            Button("Acheter maintenant") { withAnimation(.spring) { side = 1 } }
                .buttonStyle(.borderedProminent).tint(.green)
            Button("Vendre maintenant") { withAnimation(.spring) { side = 2 } }
                .buttonStyle(.borderedProminent).tint(.red)
        }
        .font(.caption.bold())
        Text(side == 1 ? "Tu achètes au meilleur ask : 101,00 $. C'est le vendeur le moins cher."
             : side == 2 ? "Tu vends au meilleur bid : 100,00 $. C'est l'acheteur le plus généreux."
             : "En rouge les vendeurs (ask), en vert les acheteurs (bid).")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear { withAnimation(.easeOut(duration: 0.8)) { appeared = true } }
    }

    private func row(price: Double, size: Double, color: Color, best: Bool) -> some View {
        HStack(spacing: 8) {
            Text(String(format: "%.2f", price))
                .font(.caption.monospacedDigit().bold())
                .frame(width: 52, alignment: .leading)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(best ? 0.9 : 0.35))
                    .frame(width: geo.size.width * (appeared ? size : 0.05))
            }
            .frame(height: 14)
        }
        .scaleEffect(best ? 1.04 : 1, anchor: .leading)
    }
}

// MARK: - Long vs short

struct LongVsShortVisual: View {
    @State private var exit: Double = 100

    var body: some View {
        let longPnl = exit - 100
        VisualTitle(text: "Bouge le prix de sortie (entrée à 100 $)")
        Chart {
            RuleMark(y: .value("Entrée", 100))
                .foregroundStyle(Color.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            LineMark(x: .value("t", 0), y: .value("Prix", 100))
            LineMark(x: .value("t", 1), y: .value("Prix", (100 + exit) / 2 + (exit > 100 ? -3 : 3)))
            LineMark(x: .value("t", 2), y: .value("Prix", exit))
            PointMark(x: .value("t", 2), y: .value("Prix", exit))
                .foregroundStyle(pnlColor(longPnl))
                .symbolSize(120)
        }
        .chartYScale(domain: 65...135)
        .chartXAxis(.hidden)
        .frame(height: 140)
        Slider(value: $exit, in: 70...130, step: 1)
        HStack {
            ValueBadge(label: "Long (acheté à 100)", value: signedDollars(longPnl), color: pnlColor(longPnl))
            ValueBadge(label: "Short (vendu à 100)", value: signedDollars(-longPnl), color: pnlColor(-longPnl))
        }
        Text("Prix de sortie : \(dollars(exit)). Le long et le short sont des miroirs : ce que l'un gagne, l'autre le perd.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Order types

struct OrderTypesVisual: View {
    @State private var shown = 2
    private let path: [Double] = {
        let raw = VisualMath.randomPath(seed: 42, count: 60, start: 100, vol: 0.012, drift: -0.002)
        // Bend it so it dips to the limit then rallies to the target.
        return raw.enumerated().map { i, p in
            let t = Double(i) / 59
            return p - 9 * sin(t * Double.pi) * (t < 0.5 ? 1 : 0.2) + (t > 0.5 ? (t - 0.5) * 30 : 0)
        }
    }()
    private let limit = 95.0
    private let stop = 89.0
    private let target = 108.0

    var body: some View {
        let visible = Array(path.prefix(shown).enumerated())
        let current = path[min(shown, path.count) - 1]
        VisualTitle(text: "Regarde les ordres se déclencher")
        Chart {
            ForEach(visible, id: \.offset) { point in
                LineMark(x: .value("t", point.offset), y: .value("Prix", point.element))
                    .interpolationMethod(.monotone)
            }
            RuleMark(y: .value("Limite", limit))
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .annotation(position: .top, alignment: .leading) { Text("Achat limite 95").font(.caption2).foregroundStyle(Color.blue) }
            RuleMark(y: .value("Stop", stop))
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .annotation(position: .bottom, alignment: .leading) { Text("Stop loss 89").font(.caption2).foregroundStyle(Color.red) }
            RuleMark(y: .value("Objectif", target))
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .annotation(position: .top, alignment: .leading) { Text("Take profit 108").font(.caption2).foregroundStyle(Color.green) }
        }
        .chartXScale(domain: 0...59)
        .chartYScale(domain: 84...116)
        .chartXAxis(.hidden)
        .frame(height: 170)
        Text(status(current: current))
            .font(.footnote.bold())
            .fixedSize(horizontal: false, vertical: true)
        Button("Rejouer") { Task { await play() } }
            .buttonStyle(.bordered)
            .font(.caption)
            .task { await play() }
    }

    private func status(current: Double) -> String {
        let prefix = path.prefix(shown)
        guard let fillIndex = prefix.firstIndex(where: { $0 <= limit }) else {
            return "Le prix descend vers ton ordre limite d'achat..."
        }
        if prefix[fillIndex...].contains(where: { $0 >= target }) {
            return "Take profit touché : position vendue avec profit."
        }
        return "Ordre limite exécuté à 95 $. Le stop à 89 $ te protège."
    }

    @MainActor
    private func play() async {
        shown = 2
        for i in 2...path.count {
            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.linear(duration: 0.07)) { shown = i }
        }
    }
}

// MARK: - Loss recovery

struct LossRecoveryVisual: View {
    @State private var loss: Double = 50

    var body: some View {
        let remaining = 100 - loss
        let needed = loss / remaining * 100
        VisualTitle(text: "Choisis la perte et vois l'effort pour revenir")
        HStack(alignment: .bottom, spacing: 18) {
            bar(value: 100, label: "Départ\n100 $", color: .blue)
            bar(value: remaining, label: "Après -\(Int(loss))%\n\(dollars(remaining))", color: .red)
            bar(value: 100, label: "Il faut\n+\(Int(needed.rounded()))%", color: .green)
        }
        .frame(height: 150)
        Slider(value: $loss, in: 10...90, step: 5)
        Text("Perdre \(Int(loss))% demande de gagner \(Int(needed.rounded()))% pour revenir à zéro. Plus la perte est grosse, plus la remontée est dure.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func bar(value: Double, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 6)
                .fill(color.gradient)
                .frame(height: max(4, value * 1.1))
                .animation(.spring, value: value)
            Text(label)
                .font(.caption2.bold())
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Risk reward

struct RiskRewardVisual: View {
    @State private var winRate: Double = 40
    @State private var ratio: Double = 3

    var body: some View {
        let expectancy = winRate / 100 * ratio * 100 - (1 - winRate / 100) * 100
        VisualTitle(text: "Joue avec le taux de réussite et le ratio")
        Picker("Ratio", selection: $ratio) {
            Text("1:1").tag(1.0)
            Text("1:2").tag(2.0)
            Text("1:3").tag(3.0)
        }
        .pickerStyle(.segmented)
        HStack(alignment: .bottom, spacing: 18) {
            VStack {
                RoundedRectangle(cornerRadius: 6).fill(Color.red.gradient).frame(height: 30)
                Text("Risque 100 $").font(.caption2.bold())
            }
            VStack {
                RoundedRectangle(cornerRadius: 6).fill(Color.green.gradient).frame(height: 30 * ratio)
                    .animation(.spring, value: ratio)
                Text("Gain \(Int(ratio * 100)) $").font(.caption2.bold())
            }
        }
        .frame(height: 110, alignment: .bottom)
        Text("Trades gagnants : \(Int(winRate))%").font(.caption.bold())
        Slider(value: $winRate, in: 10...90, step: 5)
        ValueBadge(label: "Gain moyen par trade", value: signedDollars(expectancy), color: pnlColor(expectancy))
        Text("Avec un ratio 1:\(Int(ratio)), tu peux avoir tort souvent et gagner quand même.")
            .font(.footnote)
    }
}

// MARK: - Derivative link

struct DerivativeLinkVisual: View {
    @State private var spot: Double = 100

    var body: some View {
        let call = VisualMath.callValue(spot: spot, strike: 100, spread: 6)
        VisualTitle(text: "Bouge le sous-jacent, le dérivé suit")
        HStack(spacing: 12) {
            gauge(title: "Sous-jacent", value: spot, range: 80...120, color: .blue)
            Image(systemName: "arrow.right")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            gauge(title: "Option d'achat", value: call, range: 0...22, color: .orange)
        }
        Slider(value: $spot, in: 80...120, step: 1)
        Text("Le sous-jacent vaut \(dollars(spot)), l'option vaut \(dollars(call, decimals: 2)). Sa valeur dépend entièrement du sous-jacent : c'est ça, un dérivé.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func gauge(title: String, value: Double, range: ClosedRange<Double>, color: Color) -> some View {
        VStack(spacing: 6) {
            Gauge(value: min(max(value, range.lowerBound), range.upperBound), in: range) {
                EmptyView()
            } currentValueLabel: {
                Text(String(format: "%.1f", value)).font(.caption.bold())
            }
            .gaugeStyle(.accessoryCircular)
            .tint(color)
            .scaleEffect(1.3)
            .frame(height: 70)
            Text(title).font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Hedge vs speculate

struct HedgeVsSpeculateVisual: View {
    @State private var change: Double = 0

    var body: some View {
        let price = 100 * (1 + change / 100)
        let unhedged = price * 1000
        let hedged = 100.0 * 1000
        VisualTitle(text: "Un fermier vend 1 000 boisseaux de blé")
        Text("Prix du blé à la récolte : \(dollars(price))")
            .font(.subheadline.bold())
        Slider(value: $change, in: -40...40, step: 5)
        HStack(alignment: .bottom, spacing: 18) {
            bar(value: unhedged, label: "Sans couverture", color: unhedged >= hedged ? .green : .red)
            bar(value: hedged, label: "Avec un future à 100 $", color: .blue)
        }
        .frame(height: 150)
        Text("Couvert, le fermier touche 100 000 $ quoi qu'il arrive. Il renonce aux gains possibles pour ne jamais subir la baisse.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func bar(value: Double, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(dollars(value)).font(.caption.monospacedDigit().bold())
            RoundedRectangle(cornerRadius: 6)
                .fill(color.gradient)
                .frame(height: value / 1000)
                .animation(.spring, value: value)
            Text(label).font(.caption2.bold()).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leverage

struct LeverageVisual: View {
    @State private var leverage: Double = 10
    @State private var move: Double = 0

    private let margin = 1000.0

    var body: some View {
        let size = margin * leverage
        let pnl = size * move / 100
        let liquidated = pnl <= -margin * 0.9
        let shownPnl = liquidated ? -margin : pnl
        let liqDistance = 90 / leverage
        VisualTitle(text: "Marge de 1 000 $ : choisis l'effet de levier")
        HStack {
            ValueBadge(label: "Levier", value: "x\(Int(leverage))")
            ValueBadge(label: "Position", value: dollars(size))
            ValueBadge(label: "Liquidation à", value: String(format: "-%.1f%%", liqDistance), color: .red)
        }
        Slider(value: $leverage, in: 1...50, step: 1)
        Text("Mouvement du prix : \(String(format: "%+.1f", move))%")
            .font(.caption.bold())
        Slider(value: $move, in: -20...20, step: 0.5)
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(liquidated ? Color.red.opacity(0.2) : pnlColor(shownPnl).opacity(0.12))
            VStack(spacing: 4) {
                if liquidated {
                    Image(systemName: "flame.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.red)
                        .symbolEffect(.bounce, value: liquidated)
                    Text("LIQUIDÉ : tes 1 000 $ sont perdus")
                        .font(.headline)
                        .foregroundStyle(Color.red)
                } else {
                    Text(signedDollars(shownPnl))
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(pnlColor(shownPnl))
                        .contentTransition(.numericText())
                    Text(String(format: "%+.0f%% de ta marge", shownPnl / margin * 100))
                        .font(.caption)
                }
            }
            .padding()
        }
        .animation(.spring, value: liquidated)
        Text("Le levier multiplie tout. A x\(Int(leverage)), une baisse de \(String(format: "%.1f", liqDistance))% suffit pour tout perdre.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Payoff

struct PayoffVisual: View {
    let kind: PayoffKind
    @State private var price: Double = 100

    private var range: ClosedRange<Double> { 60...140 }

    private var isHedge: Bool {
        switch kind {
        case .protectivePut, .coveredCall, .collar: return true
        default: return false
        }
    }

    private var title: String {
        switch kind {
        case .longSpot: return "Achat du sous-jacent à 100 $"
        case .shortSpot: return "Vente à découvert à 100 $"
        case .longCall(let k, let p): return "Achat d'un call strike \(Int(k)), prime \(dollars(p))"
        case .longPut(let k, let p): return "Achat d'un put strike \(Int(k)), prime \(dollars(p))"
        case .shortCall(let k, let p): return "Vente d'un call strike \(Int(k)), prime \(dollars(p))"
        case .protectivePut(let k, let p): return "Coin acheté à 100 $ + put \(Int(k)) (prime \(dollars(p)))"
        case .coveredCall(let k, let p): return "Coin acheté à 100 $ + call \(Int(k)) vendu (prime \(dollars(p)))"
        case .collar(let kp, let kc): return "Collar : put \(Int(kp)) acheté, call \(Int(kc)) vendu"
        case .longFuture: return "Future acheté à 100 $"
        case .shortFuture: return "Future vendu à 100 $"
        }
    }

    private func pnl(_ s: Double) -> Double {
        switch kind {
        case .longSpot, .longFuture: return s - 100
        case .shortSpot, .shortFuture: return 100 - s
        case .longCall(let k, let p): return max(s - k, 0) - p
        case .longPut(let k, let p): return max(k - s, 0) - p
        case .shortCall(let k, let p): return p - max(s - k, 0)
        case .protectivePut(let k, let p): return s - 100 + max(k - s, 0) - p
        case .coveredCall(let k, let p): return s - 100 + p - max(s - k, 0)
        case .collar(let kp, let kc): return s - 100 + max(kp - s, 0) - max(s - kc, 0)
        }
    }

    private var breakevens: [Double] {
        var result: [Double] = []
        var previous = pnl(range.lowerBound)
        var s = range.lowerBound + 0.25
        while s <= range.upperBound {
            let value = pnl(s)
            if (previous < 0 && value >= 0) || (previous > 0 && value <= 0) {
                result.append(s)
            }
            previous = value
            s += 0.25
        }
        return result
    }

    var body: some View {
        let points = Array(stride(from: range.lowerBound, through: range.upperBound, by: 1))
        let current = pnl(price)
        VisualTitle(text: "Glisse le prix à l'échéance")
        Text(title).font(.subheadline.bold())
        Chart {
            if isHedge {
                ForEach(points, id: \.self) { s in
                    LineMark(x: .value("Prix", s), y: .value("P&L", s - 100), series: .value("Série", "Coin seul"))
                        .foregroundStyle(Color.gray.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                }
            }
            ForEach(points, id: \.self) { s in
                LineMark(x: .value("Prix", s), y: .value("P&L", pnl(s)), series: .value("Série", "Stratégie"))
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3))
            }
            RuleMark(y: .value("Zéro", 0))
                .foregroundStyle(Color.secondary)
            ForEach(breakevens, id: \.self) { b in
                RuleMark(x: .value("Point mort", b))
                    .foregroundStyle(Color.blue.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top) {
                        Text("Point mort \(Int(b.rounded()))").font(.caption2).foregroundStyle(Color.blue)
                    }
            }
            PointMark(x: .value("Prix", price), y: .value("P&L", current))
                .foregroundStyle(pnlColor(current))
                .symbolSize(160)
        }
        .chartXScale(domain: range)
        .chartXAxisLabel("Prix du sous-jacent à l'échéance")
        .chartYAxisLabel("Gain / perte")
        .frame(height: 210)
        Slider(value: $price, in: range, step: 1)
        HStack {
            ValueBadge(label: "Prix à l'échéance", value: dollars(price))
            ValueBadge(label: "Résultat", value: signedDollars(current), color: pnlColor(current))
        }
        if isHedge {
            Text("Pointillés gris : le coin seul, sans protection. Compare les deux courbes en bas et en haut.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Moneyness

struct MoneynessVisual: View {
    @State private var spot: Double = 110

    var body: some View {
        let callIntrinsic = max(spot - 100, 0)
        let putIntrinsic = max(100 - spot, 0)
        VisualTitle(text: "Strike à 100 $ : déplace le prix")
        GeometryReader { geo in
            let w = geo.size.width
            let x: (Double) -> CGFloat = { v in CGFloat((v - 80) / 40) * w }
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Rectangle().fill(Color.red.opacity(0.18)).frame(width: x(100))
                    Rectangle().fill(Color.green.opacity(0.18))
                }
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                Rectangle().fill(Color.primary).frame(width: 2, height: 52).offset(x: x(100) - 1)
                Circle().fill(Color.orange).frame(width: 22, height: 22).offset(x: x(spot) - 11)
                    .shadow(radius: 2)
                    .animation(.spring, value: spot)
            }
        }
        .frame(height: 52)
        HStack {
            Text("80").font(.caption2)
            Spacer()
            Text("Strike 100").font(.caption2.bold())
            Spacer()
            Text("120").font(.caption2)
        }
        Slider(value: $spot, in: 80...120, step: 1)
        HStack {
            status(title: "Call", intrinsic: callIntrinsic)
            status(title: "Put", intrinsic: putIntrinsic)
        }
        Text("Prix actuel : \(dollars(spot)). Un call gagne de la valeur quand le prix passe au dessus du strike, un put quand il passe en dessous.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func status(title: String, intrinsic: Double) -> some View {
        let label: String
        let color: Color
        if abs(spot - 100) < 1 {
            label = "À la monnaie (ATM)"
            color = .orange
        } else if intrinsic > 0 {
            label = "Dans la monnaie (ITM)"
            color = .green
        } else {
            label = "Hors de la monnaie (OTM)"
            color = .red
        }
        return VStack(spacing: 4) {
            Text(title).font(.headline)
            Text(label).font(.caption.bold()).foregroundStyle(color).multilineTextAlignment(.center)
            Text("Valeur intrinsèque \(dollars(intrinsic))").font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)))
    }
}

// MARK: - Time decay

struct TimeDecayVisual: View {
    @State private var daysLeft: Double = 30
    @State private var playing = false

    private func value(_ days: Double) -> Double {
        VisualMath.callValue(spot: 100, strike: 100, spread: 100 * 0.02 * sqrt(max(days, 0)))
    }

    var body: some View {
        let days = Array(stride(from: 30.0, through: 0, by: -1))
        let current = value(daysLeft)
        VisualTitle(text: "Une option à la monnaie qui fond avec le temps")
        Chart {
            ForEach(days, id: \.self) { d in
                AreaMark(x: .value("Jours restants", d), y: .value("Valeur", value(d)))
                    .foregroundStyle(Color.orange.opacity(0.15))
                LineMark(x: .value("Jours restants", d), y: .value("Valeur", value(d)))
                    .foregroundStyle(Color.orange)
            }
            PointMark(x: .value("Jours restants", daysLeft), y: .value("Valeur", current))
                .foregroundStyle(Color.red)
                .symbolSize(140)
        }
        .chartXScale(domain: .automatic(reversed: true))
        .chartXAxisLabel("Jours avant l'échéance")
        .frame(height: 170)
        Slider(value: $daysLeft, in: 0...30, step: 1)
        HStack {
            ValueBadge(label: "Jours restants", value: "\(Int(daysLeft))")
            ValueBadge(label: "Valeur temps", value: dollars(current, decimals: 2), color: .orange)
            Button {
                Task { await play() }
            } label: {
                Image(systemName: "play.fill").padding(10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(playing)
        }
        Text("La valeur temps fond chaque jour, et de plus en plus vite à la fin. A l'échéance, il ne reste que la valeur intrinsèque.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    @MainActor
    private func play() async {
        playing = true
        daysLeft = 30
        for d in stride(from: 29.0, through: 0, by: -1) {
            try? await Task.sleep(nanoseconds: 90_000_000)
            withAnimation(.linear(duration: 0.09)) { daysLeft = d }
        }
        playing = false
    }
}

// MARK: - Volatility

struct VolatilityVisual: View {
    @State private var vol: Double = 1

    var body: some View {
        let spread = 6 * vol
        let xs = Array(stride(from: 70.0, through: 130, by: 1))
        let premium = VisualMath.callValue(spot: 100, strike: 105, spread: spread)
        VisualTitle(text: "Plus le marché bouge, plus l'option coûte cher")
        Chart {
            ForEach(xs, id: \.self) { x in
                BarMark(x: .value("Prix", x), y: .value("Probabilité", VisualMath.normalPDF((x - 100) / spread) / spread), width: 4)
                    .foregroundStyle(x >= 105 ? Color.green.opacity(0.7) : Color.blue.opacity(0.35))
            }
            RuleMark(x: .value("Strike", 105))
                .foregroundStyle(Color.orange)
                .annotation(position: .top) { Text("Strike 105").font(.caption2).foregroundStyle(Color.orange) }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...0.14)
        .chartXAxisLabel("Prix possibles à l'échéance")
        .frame(height: 160)
        .animation(.easeInOut, value: vol)
        Picker("Volatilité", selection: $vol) {
            Text("Calme").tag(0.5)
            Text("Normal").tag(1.0)
            Text("Agité").tag(2.0)
            Text("Tempête").tag(3.0)
        }
        .pickerStyle(.segmented)
        ValueBadge(label: "Prix du call 105", value: dollars(premium, decimals: 2), color: .orange)
        Text("La zone verte, c'est quand le call paie. Un marché agité étale les prix possibles : plus de chances de finir loin, donc une option plus chère.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Delta

struct DeltaVisual: View {
    @State private var spot: Double = 100

    private let spread = 8.0

    var body: some View {
        let xs = Array(stride(from: 80.0, through: 120, by: 1))
        let value = VisualMath.callValue(spot: spot, strike: 100, spread: spread)
        let delta = VisualMath.normalCDF((spot - 100) / spread)
        VisualTitle(text: "Le delta : la pente de la courbe")
        Chart {
            ForEach(xs, id: \.self) { x in
                LineMark(x: .value("Sous-jacent", x), y: .value("Option", VisualMath.callValue(spot: x, strike: 100, spread: spread)), series: .value("Série", "Option"))
                    .foregroundStyle(Color.orange)
            }
            LineMark(x: .value("Sous-jacent", spot - 8), y: .value("Option", value - 8 * delta), series: .value("Série", "Pente"))
                .foregroundStyle(Color.blue)
            LineMark(x: .value("Sous-jacent", spot + 8), y: .value("Option", value + 8 * delta), series: .value("Série", "Pente"))
                .foregroundStyle(Color.blue)
            PointMark(x: .value("Sous-jacent", spot), y: .value("Option", value))
                .foregroundStyle(Color.blue)
                .symbolSize(130)
        }
        .chartXScale(domain: 78...122)
        .chartXAxisLabel("Prix du sous-jacent")
        .frame(height: 180)
        Slider(value: $spot, in: 82...118, step: 1)
        HStack {
            ValueBadge(label: "Prix du call", value: dollars(value, decimals: 2), color: .orange)
            ValueBadge(label: "Delta", value: String(format: "%.2f", delta), color: .blue)
        }
        Text("Si le sous-jacent monte de 1 $, le call monte d'environ \(String(format: "%.2f", delta)) $. Loin sous le strike, le delta est proche de 0. Très au dessus, il approche 1.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Futures convergence

struct FuturesConvergenceVisual: View {
    @State private var day = 40
    private let spot = VisualMath.randomPath(seed: 7, count: 41, start: 100, vol: 0.01)

    private func future(_ t: Int) -> Double { spot[t] * (1 + 0.0012 * Double(40 - t)) }

    var body: some View {
        let shown = Array(0...day)
        let basis = future(day) - spot[day]
        VisualTitle(text: "Le future rejoint le spot à l'échéance")
        Chart {
            ForEach(shown, id: \.self) { t in
                LineMark(x: .value("Jour", t), y: .value("Prix", spot[t]), series: .value("Série", "Spot"))
                    .foregroundStyle(Color.blue)
                LineMark(x: .value("Jour", t), y: .value("Prix", future(t)), series: .value("Série", "Future"))
                    .foregroundStyle(Color.orange)
            }
        }
        .chartXScale(domain: 0...40)
        .chartXAxisLabel("Jours")
        .frame(height: 170)
        HStack {
            ValueBadge(label: "Jour", value: "\(day)/40")
            ValueBadge(label: "Base (future - spot)", value: dollars(basis, decimals: 2), color: .orange)
        }
        Button("Rejouer") { Task { await play() } }
            .buttonStyle(.bordered)
            .font(.caption)
            .task { await play() }
        Text("Au début, le future coûte plus cher que le spot (contango). Chaque jour l'écart se réduit. Le dernier jour, base = 0 : les deux prix se rejoignent.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    @MainActor
    private func play() async {
        day = 0
        for t in 1...40 {
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.linear(duration: 0.08)) { day = t }
        }
    }
}

// MARK: - Mark to market

struct MarkToMarketVisual: View {
    @State private var shownDays = 0
    private let moves: [Double] = [0, 150, -100, -250, 80, -320, -150]
    private let maintenance = 600.0

    private var balances: [Double] {
        var total = 1000.0
        return moves.map { total += $0; return total }
    }

    var body: some View {
        let visible = Array(balances.prefix(shownDays + 1).enumerated())
        let current = balances[shownDays]
        let call = current < maintenance
        VisualTitle(text: "Ton compte de marge, jour après jour")
        Chart {
            ForEach(visible, id: \.offset) { item in
                BarMark(x: .value("Jour", "J\(item.offset)"), y: .value("Solde", item.element))
                    .foregroundStyle(item.element < maintenance ? Color.red : Color.teal)
                    .annotation(position: .top) {
                        Text(item.offset == 0 ? "" : signedDollars(moves[item.offset]))
                            .font(.caption2)
                            .foregroundStyle(pnlColor(moves[item.offset]))
                    }
            }
            RuleMark(y: .value("Marge de maintien", maintenance))
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Marge de maintien 600 $").font(.caption2).foregroundStyle(Color.red)
                }
        }
        .chartXScale(domain: (0..<moves.count).map { "J\($0)" })
        .chartYScale(domain: 0...1400)
        .frame(height: 180)
        Text(call ? "Appel de marge ! Solde \(dollars(current)) sous 600 $ : il faut remettre de l'argent ou la position est fermée."
             : "Solde : \(dollars(current)). Gains et pertes sont réglés chaque soir.")
            .font(.footnote.bold())
            .foregroundStyle(call ? Color.red : Color.primary)
            .fixedSize(horizontal: false, vertical: true)
        Button("Rejouer") { Task { await play() } }
            .buttonStyle(.bordered)
            .font(.caption)
            .task { await play() }
    }

    @MainActor
    private func play() async {
        shownDays = 0
        for d in 1..<moves.count {
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.spring) { shownDays = d }
        }
    }
}

// MARK: - Funding

struct FundingVisual: View {
    @State private var gap: Double = 0.5
    @State private var flow = false

    var body: some View {
        let rate = gap / 10
        let payment = 10_000 * abs(rate) / 100
        let longsPay = rate > 0.0001
        let shortsPay = rate < -0.0001
        VisualTitle(text: "Écart entre le perp et le spot")
        HStack {
            side(title: "Longs", icon: "arrow.up.right", color: .green)
            ZStack {
                if longsPay || shortsPay {
                    Image(systemName: longsPay ? "arrow.right" : "arrow.left")
                        .font(.title.bold())
                        .foregroundStyle(Color.orange)
                        .offset(x: flow ? (longsPay ? 22 : -22) : (longsPay ? -22 : 22))
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false), value: flow)
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.orange)
                        .offset(x: flow ? (longsPay ? 30 : -30) : (longsPay ? -30 : 30), y: -22)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false), value: flow)
                } else {
                    Text("=").font(.title.bold())
                }
            }
            .frame(width: 90, height: 60)
            side(title: "Shorts", icon: "arrow.down.right", color: .red)
        }
        .onAppear { flow = true }
        Text(String(format: "Perp %+.2f%% par rapport au spot", gap))
            .font(.caption.bold())
        Slider(value: $gap, in: -1...1, step: 0.05)
        HStack {
            ValueBadge(label: "Taux de funding", value: String(format: "%+.3f%%", rate), color: .orange)
            ValueBadge(label: "Paiement sur 10 000 $", value: dollars(payment, decimals: 2))
        }
        Text(longsPay ? "Le perp est plus cher que le spot : trop d'acheteurs. Les longs paient les shorts, ce qui pousse le prix vers le bas."
             : shortsPay ? "Le perp est moins cher que le spot : trop de vendeurs. Les shorts paient les longs."
             : "Perp et spot au même prix : personne ne paie.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func side(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(color.gradient))
            Text(title).font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Liquidation

struct LiquidationVisual: View {
    @State private var leverage: Double = 10
    @State private var shown = 1
    private let path: [Double] = {
        let raw = VisualMath.randomPath(seed: 11, count: 50, start: 100, vol: 0.008)
        return raw.enumerated().map { i, p in p - Double(i) * 0.32 }
    }()

    var body: some View {
        let liquidationPrice = 100 * (1 - 0.9 / leverage)
        let visible = Array(path.prefix(shown).enumerated())
        let hitIndex = path.firstIndex { $0 <= liquidationPrice }
        let liquidated = hitIndex.map { shown > $0 } ?? false
        VisualTitle(text: "Long à 100 $ : le prix baisse")
        Picker("Levier", selection: $leverage) {
            Text("x2").tag(2.0)
            Text("x5").tag(5.0)
            Text("x10").tag(10.0)
            Text("x25").tag(25.0)
        }
        .pickerStyle(.segmented)
        .onChange(of: leverage) { _, _ in Task { await play() } }
        Chart {
            ForEach(visible, id: \.offset) { point in
                LineMark(x: .value("t", point.offset), y: .value("Prix", point.element))
                    .foregroundStyle(liquidated ? Color.red : Color.blue)
            }
            RuleMark(y: .value("Liquidation", liquidationPrice))
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                .annotation(position: .bottom, alignment: .leading) {
                    Text("Liquidation \(String(format: "%.1f", liquidationPrice))").font(.caption2.bold()).foregroundStyle(Color.red)
                }
        }
        .chartXScale(domain: 0...49)
        .chartYScale(domain: 50...105)
        .chartXAxis(.hidden)
        .frame(height: 170)
        Text(liquidated ? "LIQUIDÉ ! A x\(Int(leverage)), une baisse de \(String(format: "%.1f", 90 / leverage))% a suffi à effacer ta marge."
             : "A x\(Int(leverage)), tu es liquidé si le prix tombe sous \(String(format: "%.1f", liquidationPrice)) $.")
            .font(.footnote.bold())
            .foregroundStyle(liquidated ? Color.red : Color.primary)
            .fixedSize(horizontal: false, vertical: true)
        Button("Rejouer") { Task { await play() } }
            .buttonStyle(.bordered)
            .font(.caption)
            .task { await play() }
    }

    @MainActor
    private func play() async {
        shown = 1
        let liquidationPrice = 100 * (1 - 0.9 / leverage)
        for i in 2...path.count {
            try? await Task.sleep(nanoseconds: 60_000_000)
            withAnimation(.linear(duration: 0.06)) { shown = i }
            if path[i - 1] <= liquidationPrice { break }
        }
    }
}

// MARK: - Delta neutral

struct DeltaNeutralVisual: View {
    @State private var price: Double = 100

    var body: some View {
        let xs = Array(stride(from: 70.0, through: 130, by: 5))
        let spotPnl = price - 100
        VisualTitle(text: "1 coin acheté + 1 coin vendu en perp")
        Chart {
            ForEach(xs, id: \.self) { x in
                LineMark(x: .value("Prix", x), y: .value("P&L", x - 100), series: .value("Série", "Coin"))
                    .foregroundStyle(Color.green)
                LineMark(x: .value("Prix", x), y: .value("P&L", 100 - x), series: .value("Série", "Short perp"))
                    .foregroundStyle(Color.red)
                LineMark(x: .value("Prix", x), y: .value("P&L", 0), series: .value("Série", "Total"))
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 4))
            }
            PointMark(x: .value("Prix", price), y: .value("P&L", spotPnl)).foregroundStyle(Color.green)
            PointMark(x: .value("Prix", price), y: .value("P&L", -spotPnl)).foregroundStyle(Color.red)
            PointMark(x: .value("Prix", price), y: .value("P&L", 0)).foregroundStyle(Color.blue).symbolSize(150)
        }
        .frame(height: 180)
        Slider(value: $price, in: 70...130, step: 1)
        HStack {
            ValueBadge(label: "Coin", value: signedDollars(spotPnl), color: pnlColor(spotPnl))
            ValueBadge(label: "Short", value: signedDollars(-spotPnl), color: pnlColor(-spotPnl))
            ValueBadge(label: "Total", value: signedDollars(0), color: .blue)
        }
        Text("Quel que soit le prix, les deux jambes s'annulent : tu es delta neutre. Ton gain vient alors d'ailleurs, par exemple du funding.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Correlation

struct CorrelationVisual: View {
    @State private var rho: Double = 0.8

    private let shocksA: [Double] = {
        var rng = SeededGenerator(seed: 21)
        return (0..<40).map { _ in VisualMath.gaussian(&rng) }
    }()
    private let shocksB: [Double] = {
        var rng = SeededGenerator(seed: 99)
        return (0..<40).map { _ in VisualMath.gaussian(&rng) }
    }()

    var body: some View {
        let seriesA = path(shocks: shocksA.map { $0 })
        let seriesB = path(shocks: zip(shocksA, shocksB).map { rho * $0 + sqrt(max(0, 1 - rho * rho)) * $1 })
        VisualTitle(text: "Deux actifs : règle leur corrélation")
        Chart {
            ForEach(Array(seriesA.enumerated()), id: \.offset) { item in
                LineMark(x: .value("t", item.offset), y: .value("Prix", item.element), series: .value("Série", "Actif A"))
                    .foregroundStyle(Color.blue)
            }
            ForEach(Array(seriesB.enumerated()), id: \.offset) { item in
                LineMark(x: .value("t", item.offset), y: .value("Prix", item.element), series: .value("Série", "Actif B"))
                    .foregroundStyle(Color.orange)
            }
        }
        .chartXAxis(.hidden)
        .frame(height: 170)
        .animation(.easeInOut, value: rho)
        Text(String(format: "Corrélation : %+.1f", rho)).font(.caption.bold())
        Slider(value: $rho, in: -1...1, step: 0.1)
        Text(rho > 0.6 ? "Ils bougent ensemble : les avoir tous les deux ne réduit presque pas le risque."
             : rho < -0.4 ? "Ils bougent en sens inverse : l'un compense l'autre. Idéal pour se couvrir."
             : "Ils bougent un peu chacun de leur côté : les combiner lisse ton portefeuille.")
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func path(shocks: [Double]) -> [Double] {
        var price = 100.0
        return shocks.map { shock in
            price *= exp(0.02 * shock)
            return price
        }
    }
}

// MARK: - History timeline

struct HistoryEvent {
    let year: String
    let title: String
    let icon: String
}

enum HistoryTimeline {
    static let events: [HistoryEvent] = [
        HistoryEvent(year: "-1750", title: "Code d'Hammurabi", icon: "building.columns.fill"),
        HistoryEvent(year: "-600", title: "Thalès et les pressoirs", icon: "leaf.fill"),
        HistoryEvent(year: "1637", title: "Tulipomanie", icon: "camera.macro"),
        HistoryEvent(year: "1730", title: "Riz de Dojima", icon: "bag.fill"),
        HistoryEvent(year: "1848", title: "CBOT à Chicago", icon: "building.2.fill"),
        HistoryEvent(year: "1972", title: "Futures financiers", icon: "dollarsign.circle.fill"),
        HistoryEvent(year: "1973", title: "Black-Scholes et CBOE", icon: "function"),
        HistoryEvent(year: "1981", title: "Swap IBM", icon: "arrow.triangle.swap"),
        HistoryEvent(year: "1987", title: "Lundi noir", icon: "chart.line.downtrend.xyaxis"),
        HistoryEvent(year: "1995", title: "Faillite de Barings", icon: "person.fill.xmark"),
        HistoryEvent(year: "1998", title: "LTCM", icon: "graduationcap.fill"),
        HistoryEvent(year: "2008", title: "Crise des subprimes", icon: "house.fill"),
        HistoryEvent(year: "2016", title: "Perp de BitMEX", icon: "infinity"),
        HistoryEvent(year: "2020", title: "Krach de mars", icon: "flame.fill"),
        HistoryEvent(year: "2022", title: "Effondrement LUNA", icon: "moon.fill"),
        HistoryEvent(year: "2022", title: "Faillite FTX", icon: "xmark.octagon.fill"),
    ]
}

struct TimelineVisual: View {
    let highlight: Int
    @State private var appeared = false

    var body: some View {
        VisualTitle(text: "4 000 ans de marchés")
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(HistoryTimeline.events.indices, id: \.self) { i in
                        let event = HistoryTimeline.events[i]
                        let active = i == highlight
                        VStack(spacing: 6) {
                            Text(event.year)
                                .font(active ? .headline : .caption.bold())
                                .foregroundStyle(active ? Color.brown : Color.secondary)
                            ZStack {
                                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 2)
                                Image(systemName: event.icon)
                                    .font(active ? .title2 : .caption)
                                    .foregroundStyle(.white)
                                    .frame(width: active ? 50 : 30, height: active ? 50 : 30)
                                    .background(Circle().fill(active ? Color.brown : Color.gray.opacity(0.6)))
                                    .scaleEffect(active && appeared ? 1.1 : 1)
                            }
                            Text(event.title)
                                .font(.caption2)
                                .fontWeight(active ? .bold : .regular)
                                .multilineTextAlignment(.center)
                                .frame(width: 84)
                        }
                        .id(i)
                        .opacity(active ? 1 : 0.6)
                    }
                }
                .padding(.vertical, 6)
            }
            .onAppear {
                proxy.scrollTo(highlight, anchor: .center)
                withAnimation(.spring(duration: 0.6, bounce: 0.5).repeatCount(3, autoreverses: true)) { appeared = true }
            }
        }
    }
}

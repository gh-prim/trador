import SwiftUI
import Charts

struct TradingFloorView: View {
    @EnvironmentObject var market: MarketSim

    @State private var kind: InstrumentKind = .spot
    @State private var side: Side = .long
    @State private var leverage: Double = 2
    @State private var optionType: OptionType = .call
    @State private var strikeChoice: StrikeChoice = .atm
    @State private var amount: Double = 500
    @State private var playing = false
    @State private var confirmReset = false

    private let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    private let leverageChoices: [Double] = [1, 2, 5, 10, 20]
    private let amountChoices: [Double] = [100, 500, 1_000, 2_500]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    balanceCard
                    chartCard
                    orderTicket
                    positionsCard
                    historyCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Salle de marché")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Réinitialiser") { confirmReset = true }
                }
            }
            .confirmationDialog("Remettre ton compte fictif à \(Fmt.money(MarketSim.startingCash)) ?",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Réinitialiser le compte", role: .destructive) { market.resetAccount() }
            }
        }
        .onReceive(timer) { _ in
            if playing { market.advance() }
        }
        .onDisappear { playing = false }
    }

    // MARK: Balance

    private var balanceCard: some View {
        let total = market.cash + market.openValue
        let change = total - MarketSim.startingCash
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Valeur du compte")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Fmt.money(total))
                    .font(.title.bold().monospacedDigit())
                Text("\(Fmt.signedMoney(change)) depuis le début")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(change >= 0 ? Color.green : Color.red)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Liquidités")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Fmt.money(market.cash))
                    .font(.headline.monospacedDigit())
                Text("Argent fictif")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: Chart

    private struct ChartLevel: Identifiable {
        let id: UUID
        let value: Double
        let label: String
    }

    private var chartLevels: [ChartLevel] {
        market.positions.compactMap { position in
            switch position.kind {
            case .spot, .perp:
                return ChartLevel(id: position.id, value: position.entryPrice, label: "\(position.title) entry")
            case .option:
                return ChartLevel(id: position.id, value: position.strike, label: "\(position.title) strike")
            case .future:
                return nil
            }
        }
    }

    private var chartCard: some View {
        let points = Array(market.history.enumerated())
        let first = market.history.first ?? market.price
        let up = market.price >= first
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TDC  Trador Coin")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(Fmt.price(market.price))
                        .font(.largeTitle.bold().monospacedDigit())
                }
                Spacer()
                Text(Fmt.percent(market.price / first - 1))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(up ? Color.green : Color.red)
            }

            Chart {
                ForEach(points, id: \.offset) { point in
                    LineMark(
                        x: .value("Tick", point.offset),
                        y: .value("Price", point.element)
                    )
                    .foregroundStyle(up ? Color.green : Color.red)
                    .interpolationMethod(.monotone)
                }
                ForEach(chartLevels) { level in
                    RuleMark(y: .value("Level", level.value))
                        .foregroundStyle(Color.orange.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text(level.label)
                                .font(.caption2)
                                .foregroundStyle(Color.orange)
                        }
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis(.hidden)
            .frame(height: 200)

            HStack {
                Button {
                    playing.toggle()
                } label: {
                    Label(playing ? "Pause" : "Lecture", systemImage: playing ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    market.advance()
                } label: {
                    Label("Tick suivant", systemImage: "forward.frame.fill")
                }
                .buttonStyle(.bordered)
                .disabled(playing)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Tick \(market.tick)")
                        .font(.caption.monospacedDigit())
                    Text("Funding \(Fmt.rate(market.fundingRate)) dans \(market.ticksToFunding)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: Order ticket

    private var orderTicket: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nouveau trade")
                .font(.headline)

            Picker("Instrument", selection: $kind) {
                ForEach(InstrumentKind.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            Text(kind.blurb)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if kind == .future || kind == .perp {
                Picker("Sens", selection: $side) {
                    ForEach(Side.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Text("Effet de levier")
                    .font(.subheadline.bold())
                Picker("Levier", selection: $leverage) {
                    ForEach(leverageChoices, id: \.self) { Text("\(Int($0))x").tag($0) }
                }
                .pickerStyle(.segmented)
            }

            if kind == .option {
                Picker("Type", selection: $optionType) {
                    ForEach(OptionType.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("Strike", selection: $strikeChoice) {
                    ForEach(StrikeChoice.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Text(kind == .spot || kind == .option ? "Montant à investir" : "Marge")
                .font(.subheadline.bold())
            Picker("Montant", selection: $amount) {
                ForEach(amountChoices, id: \.self) { Text(Fmt.money($0)).tag($0) }
            }
            .pickerStyle(.segmented)

            orderPreview

            Button {
                market.open(kind: kind, side: side, amount: amount, leverage: leverage,
                            optionType: optionType, strikeChoice: strikeChoice)
            } label: {
                Text(openButtonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(side == .short && (kind == .future || kind == .perp) ? Color.red : Color.green)
            .disabled(amount > market.cash)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var openButtonTitle: String {
        switch kind {
        case .spot: return "Acheter du TDC"
        case .option: return "Acheter un \(optionType.rawValue)"
        case .future, .perp: return "Ouvrir \(side.rawValue) x\(Int(leverage))"
        }
    }

    @ViewBuilder
    private var orderPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch kind {
            case .spot:
                previewRow("Tu reçois", String(format: "%.3f TDC", amount / market.price))
                previewRow("Perte max", Fmt.money(amount))
            case .option:
                let strike = market.strike(for: optionType, choice: strikeChoice)
                let premium = max(0.01, MarketSim.optionValue(type: optionType, spot: market.price,
                                                              strike: strike, ticksLeft: MarketSim.optionLife))
                let breakeven = optionType == .call ? strike + premium : strike - premium
                previewRow("Strike", Fmt.price(strike))
                previewRow("Prime par TDC", Fmt.price(premium))
                previewRow("Point mort à l'échéance", Fmt.price(breakeven))
                previewRow("Échéance dans", "\(MarketSim.optionLife) ticks")
                previewRow("Perte max", Fmt.money(amount))
            case .future, .perp:
                let entry = kind == .future ? market.futurePrice(ticksLeft: MarketSim.futureLife) : market.price
                let room = (1 - MarketSim.maintenanceRatio) / leverage
                let liquidation = side == .long ? entry * (1 - room) : entry * (1 + room)
                previewRow("Taille de position", Fmt.money(amount * leverage))
                previewRow(kind == .future ? "Prix du future" : "Prix d'entrée", Fmt.price(entry))
                if kind == .future {
                    previewRow("Base vs spot", Fmt.price(entry - market.price))
                }
                previewRow("Liquidation vers", Fmt.price(liquidation))
            }
        }
        .font(.footnote)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemGroupedBackground)))
    }

    private func previewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
    }

    // MARK: Positions

    private var positionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Positions ouvertes")
                    .font(.headline)
                Spacer()
                Text("Réalisé \(Fmt.signedMoney(market.realizedPnL))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(market.realizedPnL >= 0 ? Color.green : Color.red)
            }
            if market.positions.isEmpty {
                Text("Aucune position. Choisis un instrument, ouvre un trade, puis appuie sur Lecture pour voir le marché bouger.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(market.positions) { position in
                    PositionRow(position: position)
                    if position.id != market.positions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}

extension TradingFloorView {
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique des trades")
                .font(.headline)
            if market.closedTrades.isEmpty {
                Text("Tes trades clôturés apparaissent ici avec leur gain ou leur perte.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    statBox("Trades", "\(market.closedTrades.count)")
                    statBox("Réussite", String(format: "%.0f%%", market.winRate * 100))
                    statBox("Série gagnante", "\(market.winStreak)")
                }
                if let best = market.bestTrade, best.pnl > 0 {
                    Text("Meilleur trade : \(best.title) \(Fmt.signedMoney(best.pnl))")
                        .font(.caption.bold())
                        .foregroundStyle(Color.green)
                }
                ForEach(market.closedTrades.prefix(15)) { trade in
                    HStack {
                        Image(systemName: trade.pnl > 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                            .foregroundStyle(trade.pnl > 0 ? Color.green : Color.red)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(trade.title)
                                .font(.subheadline.bold())
                            Text("\(trade.reason) \(trade.date.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(Fmt.signedMoney(trade.pnl))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(trade.pnl > 0 ? Color.green : Color.red)
                            Text(Fmt.percent(trade.returnRatio))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    private func statBox(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemGroupedBackground)))
    }
}

struct PositionRow: View {
    @EnvironmentObject var market: MarketSim
    let position: Position

    var body: some View {
        let profit = market.pnl(position)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(position.title)
                    .font(.subheadline.bold())
                Spacer()
                Text(Fmt.signedMoney(profit))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(profit >= 0 ? Color.green : Color.red)
            }
            HStack {
                Text("Entrée \(Fmt.price(position.entryPrice))")
                Text("Actuel \(Fmt.price(market.markPrice(position)))")
                Spacer()
                Text(Fmt.percent(profit / position.margin))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            HStack {
                if let liquidation = position.liquidationPrice {
                    Text("Liq. \(Fmt.price(liquidation))")
                        .foregroundStyle(Color.red)
                }
                if let expiry = position.expiryTick {
                    Text("Échéance dans \(max(0, expiry - market.tick)) ticks")
                }
                if position.kind == .perp {
                    Text("Funding \(Fmt.signedMoney(-position.fundingPaid))")
                }
                Spacer()
                Button("Clôturer") {
                    market.close(position.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .font(.caption.monospacedDigit())
        }
    }
}

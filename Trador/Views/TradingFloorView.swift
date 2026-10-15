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
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trading Floor")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") { confirmReset = true }
                }
            }
            .confirmationDialog("Reset your fake account to \(Fmt.money(MarketSim.startingCash))?",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset account", role: .destructive) { market.resetAccount() }
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
                Text("Account value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Fmt.money(total))
                    .font(.title.bold().monospacedDigit())
                Text("\(Fmt.signedMoney(change)) since start")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(change >= 0 ? Color.green : Color.red)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Cash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Fmt.money(market.cash))
                    .font(.headline.monospacedDigit())
                Text("Fake money only")
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
                    Label(playing ? "Pause" : "Play", systemImage: playing ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    market.advance()
                } label: {
                    Label("Next tick", systemImage: "forward.frame.fill")
                }
                .buttonStyle(.bordered)
                .disabled(playing)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Tick \(market.tick)")
                        .font(.caption.monospacedDigit())
                    Text("Funding \(Fmt.rate(market.fundingRate)) in \(market.ticksToFunding)")
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
            Text("New trade")
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
                Picker("Side", selection: $side) {
                    ForEach(Side.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Text("Leverage")
                    .font(.subheadline.bold())
                Picker("Leverage", selection: $leverage) {
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

            Text(kind == .spot || kind == .option ? "Amount to spend" : "Margin")
                .font(.subheadline.bold())
            Picker("Amount", selection: $amount) {
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
        case .spot: return "Buy TDC"
        case .option: return "Buy \(optionType.rawValue)"
        case .future, .perp: return "Open \(side.rawValue) \(Int(leverage))x"
        }
    }

    @ViewBuilder
    private var orderPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch kind {
            case .spot:
                previewRow("You get", String(format: "%.3f TDC", amount / market.price))
                previewRow("Max loss", Fmt.money(amount))
            case .option:
                let strike = market.strike(for: optionType, choice: strikeChoice)
                let premium = max(0.01, MarketSim.optionValue(type: optionType, spot: market.price,
                                                              strike: strike, ticksLeft: MarketSim.optionLife))
                let breakeven = optionType == .call ? strike + premium : strike - premium
                previewRow("Strike", Fmt.price(strike))
                previewRow("Premium per TDC", Fmt.price(premium))
                previewRow("Breakeven at expiry", Fmt.price(breakeven))
                previewRow("Expires in", "\(MarketSim.optionLife) ticks")
                previewRow("Max loss", Fmt.money(amount))
            case .future, .perp:
                let entry = kind == .future ? market.futurePrice(ticksLeft: MarketSim.futureLife) : market.price
                let room = (1 - MarketSim.maintenanceRatio) / leverage
                let liquidation = side == .long ? entry * (1 - room) : entry * (1 + room)
                previewRow("Position size", Fmt.money(amount * leverage))
                previewRow(kind == .future ? "Future price" : "Entry price", Fmt.price(entry))
                if kind == .future {
                    previewRow("Basis vs spot", Fmt.price(entry - market.price))
                }
                previewRow("Liquidation near", Fmt.price(liquidation))
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
                Text("Open positions")
                    .font(.headline)
                Spacer()
                Text("Realized \(Fmt.signedMoney(market.realizedPnL))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(market.realizedPnL >= 0 ? Color.green : Color.red)
            }
            if market.positions.isEmpty {
                Text("No open trades. Pick an instrument above, open a trade, then press Play to watch the market move.")
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
                Text("Entry \(Fmt.price(position.entryPrice))")
                Text("Now \(Fmt.price(market.markPrice(position)))")
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
                    Text("Expires in \(max(0, expiry - market.tick)) ticks")
                }
                if position.kind == .perp {
                    Text("Funding \(Fmt.signedMoney(-position.fundingPaid))")
                }
                Spacer()
                Button("Close") {
                    market.close(position.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .font(.caption.monospacedDigit())
        }
    }
}

import SwiftUI

private func card(_ icon: String, _ title: String, _ text: String) -> LessonCard {
    LessonCard(icon: icon, title: title, text: text)
}

private func q(_ prompt: String, _ options: [String], _ answer: Int, _ explanation: String) -> QuizQuestion {
    QuizQuestion(prompt: prompt, options: options, answer: answer, explanation: explanation)
}

enum Curriculum {
    static let modules: [Module] = [basics, derivatives, options, futures, perps]

    static func module(id: String) -> Module? {
        modules.first { $0.id == id }
    }

    static var lessonCount: Int {
        modules.reduce(0) { $0 + $1.lessons.count }
    }

    // MARK: 1. Trading basics

    static let basics = Module(
        id: "basics",
        title: "Trading Basics",
        subtitle: "Markets, long vs short, orders and risk.",
        icon: "chart.bar.fill",
        color: .blue,
        lessons: [
            Lesson(
                id: "basics.market",
                title: "What is a market?",
                summary: "Bid, ask, spread and liquidity.",
                cards: [
                    card("building.columns.fill", "A place to swap",
                         "A market is where buyers and sellers meet. The price is simply the last deal they agreed on."),
                    card("arrow.left.arrow.right", "Bid and ask",
                         "The bid is the best price a buyer offers. The ask is the best price a seller accepts. You buy at the ask and sell at the bid."),
                    card("arrow.up.and.down", "The spread",
                         "The gap between bid and ask is the spread. It is a hidden cost: if you buy and sell right away, you lose the spread."),
                    card("drop.fill", "Liquidity",
                         "A liquid market has lots of buyers and sellers. Spreads are tight and big orders barely move the price."),
                ],
                quiz: [
                    q("You want to buy right now. Which price do you pay?",
                      ["The bid", "The ask", "The average"], 1,
                      "Sellers wait at the ask, so an instant buy fills there."),
                    q("Bid is $99, ask is $101. What is the spread?",
                      ["$1", "$2", "$100"], 1,
                      "Spread = ask minus bid = 101 - 99 = $2."),
                    q("What does a liquid market usually have?",
                      ["Wide spreads", "Tight spreads and many traders", "No sellers"], 1,
                      "More traders means more competition, so the spread gets tight."),
                ]
            ),
            Lesson(
                id: "basics.longshort",
                title: "Long and short",
                summary: "Make money when price goes up or down.",
                cards: [
                    card("arrow.up.right", "Going long",
                         "Buy first, sell later. You profit if price goes up. Buy at $100, sell at $120: profit $20."),
                    card("arrow.down.right", "Going short",
                         "Sell first, buy back later. You profit if price goes down. Short at $100, buy back at $80: profit $20."),
                    card("exclamationmark.triangle.fill", "Short risk",
                         "A long can lose at most what you paid. A short keeps losing as price keeps rising, so shorts need care."),
                    card("plusminus", "P&L",
                         "Profit and loss. Long: (exit - entry) x size. Short: (entry - exit) x size."),
                ],
                quiz: [
                    q("You buy 2 coins at $50 and sell at $60. P&L?",
                      ["+$10", "+$20", "-$20"], 1,
                      "(60 - 50) x 2 = +$20."),
                    q("You short at $200 and buy back at $220. P&L per coin?",
                      ["+$20", "-$20", "$0"], 1,
                      "Shorts lose when price rises: 200 - 220 = -$20."),
                    q("When does a short make money?",
                      ["When price goes up", "When price goes down", "Never"], 1,
                      "You sold high first, so you want to buy back lower."),
                ]
            ),
            Lesson(
                id: "basics.orders",
                title: "Order types",
                summary: "Market, limit, stop loss, take profit.",
                cards: [
                    card("bolt.fill", "Market order",
                         "Buy or sell now at the best available price. Fast, but the exact price is not guaranteed."),
                    card("scope", "Limit order",
                         "Buy or sell only at your price or better. The price is guaranteed, but it might never fill."),
                    card("hand.raised.fill", "Stop loss",
                         "Closes your trade if price hits a level you choose. It caps how much you can lose."),
                    card("target", "Take profit",
                         "Closes your trade at a target price to lock in gains before the market turns."),
                ],
                quiz: [
                    q("You want a guaranteed price, even if it may not fill. Use a...",
                      ["Market order", "Limit order", "Stop loss"], 1,
                      "A limit order only fills at your price or better."),
                    q("What does a stop loss do?",
                      ["Adds to your position", "Limits your loss", "Doubles your profit"], 1,
                      "It exits the trade automatically when price goes against you."),
                    q("Which order fills fastest?",
                      ["Market order", "Limit order far from price", "None of them"], 0,
                      "A market order takes the best price available right now."),
                ]
            ),
            Lesson(
                id: "basics.risk",
                title: "Risk management",
                summary: "How pros stay in the game.",
                cards: [
                    card("shield.lefthalf.filled", "Protect your capital",
                         "Pros focus on not losing big. A 50% loss needs a 100% gain just to get back to even."),
                    card("percent", "The 1% rule",
                         "Risk a small slice per trade, like 1 to 2% of your account. Ten losses in a row will not wipe you out."),
                    card("scalemass.fill", "Risk vs reward",
                         "Aim to win more than you risk. Risk $10 to make $30 and you can be wrong often and still profit."),
                    card("brain.head.profile", "Emotions",
                         "Fear and greed cause bad trades. Plan your entry, stop and target before you click."),
                ],
                quiz: [
                    q("Account of $10,000 with the 1% rule. Max risk per trade?",
                      ["$10", "$100", "$1,000"], 1,
                      "1% of $10,000 is $100."),
                    q("After a 50% loss, what gain gets you back to even?",
                      ["50%", "75%", "100%"], 2,
                      "$100 drops to $50. Getting back to $100 needs +$50, which is 100% of $50."),
                    q("You risk $20 to make $60. Risk to reward is...",
                      ["1:3", "3:1", "1:1"], 0,
                      "You risk 1 part to make 3 parts."),
                ]
            ),
        ]
    )

    // MARK: 2. Derivatives 101

    static let derivatives = Module(
        id: "derivatives",
        title: "Derivatives 101",
        subtitle: "What derivatives are and why traders use them.",
        icon: "link",
        color: .purple,
        lessons: [
            Lesson(
                id: "deriv.what",
                title: "What is a derivative?",
                summary: "A contract based on something else.",
                cards: [
                    card("link", "Value borrowed",
                         "A derivative is a contract whose value comes from something else, called the underlying. Like a concert ticket whose price depends on the band."),
                    card("cube.fill", "Underlyings",
                         "The underlying can be a stock, a coin, gold, oil, an interest rate or an index."),
                    card("doc.text.fill", "It is a contract",
                         "You do not own the asset itself. You own an agreement between two sides about that asset."),
                    card("square.grid.2x2.fill", "The big ones",
                         "Options, futures, perpetual swaps (perps) and swaps. This game covers the first three."),
                ],
                quiz: [
                    q("A derivative gets its value from...",
                      ["Itself", "An underlying asset", "The government"], 1,
                      "That is the whole idea: value derived from an underlying."),
                    q("Which one is NOT a derivative?",
                      ["A call option", "A futures contract", "Owning a share of stock"], 2,
                      "Owning a share means you own the asset itself."),
                    q("For Bitcoin futures, what is the underlying?",
                      ["Dollars", "Bitcoin", "Gold"], 1,
                      "The contract tracks the price of Bitcoin."),
                ]
            ),
            Lesson(
                id: "deriv.why",
                title: "Why use derivatives?",
                summary: "Hedging, speculation, leverage.",
                cards: [
                    card("umbrella.fill", "Hedging",
                         "Protection. A farmer can lock in a wheat price today so a crash later does not hurt."),
                    card("dice.fill", "Speculation",
                         "Betting on price moves, up or down, often with less money upfront."),
                    card("arrow.up.forward.circle.fill", "Leverage",
                         "Control a big position with a small deposit. Gains AND losses get bigger."),
                    card("arrow.triangle.2.circlepath", "Zero sum",
                         "For every winner on a derivative there is a loser on the other side, before fees."),
                ],
                quiz: [
                    q("An airline locks in fuel prices to avoid surprises. That is...",
                      ["Speculating", "Hedging", "Gambling"], 1,
                      "They reduce risk instead of chasing profit."),
                    q("Leverage makes...",
                      ["Only gains bigger", "Only losses bigger", "Gains and losses bigger"], 2,
                      "Leverage multiplies every move, good or bad."),
                    q("Derivatives are zero sum because...",
                      ["Fees are zero", "One side wins what the other loses", "Prices never move"], 1,
                      "Money moves from one side of the contract to the other."),
                ]
            ),
            Lesson(
                id: "deriv.leverage",
                title: "Leverage and margin",
                summary: "Small deposit, big position, big risk.",
                cards: [
                    card("banknote.fill", "Margin",
                         "Margin is the deposit you put up to open a leveraged trade. It is collateral, not a fee."),
                    card("multiply.circle.fill", "Leverage math",
                         "$1,000 margin at 10x controls a $10,000 position. A 1% move = $100 = 10% of your margin."),
                    card("flame.fill", "Liquidation",
                         "If losses eat most of your margin, the exchange closes your trade for you. That margin is gone."),
                    card("lightbulb.fill", "Rule of thumb",
                         "At 10x, a move of about 10% against you wipes you out. At 50x, just 2%."),
                ],
                quiz: [
                    q("$500 margin with 4x leverage controls...",
                      ["$125", "$2,000", "$500"], 1,
                      "500 x 4 = $2,000."),
                    q("At 10x, price moves 3% your way. Gain on your margin?",
                      ["3%", "10%", "30%"], 2,
                      "3% x 10 = 30%."),
                    q("Roughly what move against you wipes out a 20x long?",
                      ["5%", "20%", "50%"], 0,
                      "100% / 20 = 5%."),
                ]
            ),
        ]
    )

    // MARK: 3. Options

    static let options = Module(
        id: "options",
        title: "Options",
        subtitle: "Calls, puts, strikes and premiums.",
        icon: "slider.horizontal.3",
        color: .orange,
        lessons: [
            Lesson(
                id: "options.callsputs",
                title: "Calls and puts",
                summary: "The right to buy or sell.",
                cards: [
                    card("arrow.up.circle.fill", "Call option",
                         "The right, not the obligation, to BUY at a set price (the strike) before a date (the expiry). Buy calls when you think price goes up."),
                    card("arrow.down.circle.fill", "Put option",
                         "The right to SELL at the strike before expiry. Buy puts when you think price goes down, or to protect what you own."),
                    card("tag.fill", "Premium",
                         "The price you pay for the option. As a buyer, the premium is the most you can lose."),
                    card("person.2.fill", "Buyer vs seller",
                         "The buyer pays premium and gets the right. The seller collects premium but must deliver if asked. Sellers can lose a lot."),
                ],
                quiz: [
                    q("You think a stock will rise. Which do you buy?",
                      ["A call", "A put", "Neither"], 0,
                      "A call gains value when price rises."),
                    q("Max loss when you BUY an option?",
                      ["Unlimited", "The premium paid", "The strike price"], 1,
                      "If it expires worthless, you lose only what you paid."),
                    q("A put gives you the right to...",
                      ["Buy at the strike", "Sell at the strike", "Skip fees"], 1,
                      "Put = right to sell."),
                ]
            ),
            Lesson(
                id: "options.moneyness",
                title: "Strike and expiry",
                summary: "In, at or out of the money.",
                cards: [
                    card("number.circle.fill", "Strike",
                         "The fixed price written in the contract."),
                    card("calendar", "Expiry",
                         "The last day the option lives. After that it is worth its intrinsic value or nothing."),
                    card("checkmark.seal.fill", "In the money (ITM)",
                         "Has real value now. A call is ITM when price is above the strike. A put is ITM when price is below the strike."),
                    card("circle.dashed", "At or out of the money",
                         "ATM: price is near the strike. OTM: no real value yet, only hope. OTM options are cheap but often expire worthless."),
                ],
                quiz: [
                    q("Stock is $110. A $100 call is...",
                      ["ITM", "ATM", "OTM"], 0,
                      "You could buy at $100 something worth $110."),
                    q("Stock is $110. A $100 put is...",
                      ["ITM", "ATM", "OTM"], 2,
                      "Selling at $100 something worth $110 makes no sense, so no real value."),
                    q("OTM options at expiry are worth...",
                      ["Their premium", "Zero", "The strike"], 1,
                      "No intrinsic value and no time left means zero."),
                ]
            ),
            Lesson(
                id: "options.payoff",
                title: "Payoff and breakeven",
                summary: "When does an option make money?",
                cards: [
                    card("function", "Intrinsic value",
                         "Call: price - strike. Put: strike - price. Never below zero."),
                    card("equal.circle.fill", "Breakeven",
                         "Call breakeven = strike + premium. Put breakeven = strike - premium. Price must pass it for profit at expiry."),
                    card("chart.line.uptrend.xyaxis", "Call example",
                         "Buy a $100 call for $5. At expiry price is $115. Value $15, profit $15 - $5 = $10."),
                    card("chart.line.downtrend.xyaxis", "Put example",
                         "Buy a $100 put for $4. At expiry price is $90. Value $10, profit $6. If price ends at $105, you lose the $4."),
                ],
                quiz: [
                    q("$50 call with a $3 premium. Breakeven?",
                      ["$47", "$53", "$50"], 1,
                      "Strike + premium = 50 + 3 = $53."),
                    q("$100 call bought for $5. At expiry price is $102. Profit?",
                      ["+$2", "-$3", "-$5"], 1,
                      "Value is $2, you paid $5: 2 - 5 = -$3."),
                    q("$80 put bought for $2. At expiry price is $70. Profit?",
                      ["+$8", "+$10", "-$2"], 0,
                      "Value is 80 - 70 = $10, minus $2 premium = +$8."),
                ]
            ),
            Lesson(
                id: "options.greeks",
                title: "Time and volatility",
                summary: "Why option prices change.",
                cards: [
                    card("hourglass", "Time value",
                         "Before expiry, an option is worth more than its intrinsic value. The extra is time value: the chance it moves your way."),
                    card("clock.arrow.circlepath", "Time decay (theta)",
                         "Every day, time value melts a bit, faster near expiry. Buyers fight the clock, sellers earn it."),
                    card("waveform.path.ecg", "Volatility (vega)",
                         "Bigger expected swings make options pricier, for calls and puts alike."),
                    card("speedometer", "Delta",
                         "How much the option moves when the underlying moves $1. ATM options have a delta near 0.5."),
                ],
                quiz: [
                    q("As expiry gets closer, time value...",
                      ["Grows", "Shrinks", "Stays the same"], 1,
                      "Less time means less chance to move, so less time value."),
                    q("Volatility jumps. Option prices usually...",
                      ["Rise", "Fall", "Do not change"], 0,
                      "Bigger swings mean a bigger chance of a big payoff."),
                    q("Call delta is 0.5 and the stock rises $2. The option moves about...",
                      ["+$0.50", "+$1", "+$2"], 1,
                      "0.5 x $2 = $1."),
                ]
            ),
        ]
    )

    // MARK: 4. Futures

    static let futures = Module(
        id: "futures",
        title: "Futures",
        subtitle: "Contracts with a date, margin and settlement.",
        icon: "calendar.badge.clock",
        color: .teal,
        lessons: [
            Lesson(
                id: "futures.what",
                title: "What is a future?",
                summary: "A promise to trade later at a fixed price.",
                cards: [
                    card("calendar.badge.clock", "A promise with a date",
                         "A futures contract is an agreement to buy or sell an asset at a set price on a future date. Both sides MUST honor it."),
                    card("leaf.fill", "Born from farming",
                         "Farmers and bakers used futures to lock prices for crops long before computers."),
                    card("arrow.up.arrow.down", "Long or short",
                         "Long future: you gain if price rises. Short future: you gain if price falls. Shorting is as easy as buying."),
                    card("building.2.fill", "Exchange traded",
                         "Futures trade on exchanges with standard sizes and dates. A clearing house guarantees both sides."),
                ],
                quiz: [
                    q("Main difference from an option?",
                      ["Futures are optional", "Both sides must honor a future", "Futures never expire"], 1,
                      "An option is a right. A future is an obligation."),
                    q("You think oil will fall. Which position?",
                      ["Long future", "Short future", "Buy a call"], 1,
                      "A short future gains when price drops."),
                    q("Who guarantees exchange traded futures?",
                      ["The clearing house", "The buyer", "Nobody"], 0,
                      "The clearing house stands between both sides."),
                ]
            ),
            Lesson(
                id: "futures.margin",
                title: "Margin and mark to market",
                summary: "Daily settlement and margin calls.",
                cards: [
                    card("banknote", "Initial margin",
                         "A deposit, often 5 to 15% of the contract value, to open a position."),
                    card("arrow.clockwise", "Mark to market",
                         "Every day gains and losses are settled in cash. Your margin goes up or down with price."),
                    card("bell.fill", "Margin call",
                         "If your balance drops below the maintenance margin, you must add money or get closed out."),
                    card("multiply", "Built in leverage",
                         "Small margin, big contract. Same leverage rules apply: small moves, big P&L."),
                ],
                quiz: [
                    q("Contract worth $50,000, margin 10%. Deposit?",
                      ["$500", "$5,000", "$50,000"], 1,
                      "10% of $50,000 = $5,000."),
                    q("Mark to market means...",
                      ["P&L is settled every day", "Prices are fixed", "No margin is needed"], 0,
                      "Gains and losses hit your account daily."),
                    q("Your balance falls below maintenance margin. You get a...",
                      ["Bonus", "Margin call", "Dividend"], 1,
                      "Add funds or the position gets closed."),
                ]
            ),
            Lesson(
                id: "futures.basis",
                title: "Expiry, basis and hedging",
                summary: "Futures meet spot at the end.",
                cards: [
                    card("flag.checkered", "Expiry and settlement",
                         "At expiry the future settles: either the real asset is delivered or, more often, cash for the difference."),
                    card("arrow.left.and.right", "Basis",
                         "Futures price minus spot price. It shrinks to zero as expiry nears: the future converges to spot."),
                    card("chart.line.uptrend.xyaxis", "Contango and backwardation",
                         "Contango: future above spot (normal, cost of carry). Backwardation: future below spot (tight supply)."),
                    card("umbrella.fill", "Hedging example",
                         "You own 1 BTC and fear a drop. Short 1 BTC future. If BTC falls, the short gains and offsets your loss."),
                ],
                quiz: [
                    q("Spot is $100 and the future is $103. Basis?",
                      ["$3", "-$3", "$103"], 0,
                      "Future - spot = 103 - 100 = $3."),
                    q("At expiry, the future price...",
                      ["Doubles", "Converges to spot", "Goes to zero"], 1,
                      "On the last day the future and spot are the same thing."),
                    q("A future priced below spot is in...",
                      ["Contango", "Backwardation", "Liquidation"], 1,
                      "Backwardation means future below spot."),
                ]
            ),
        ]
    )

    // MARK: 5. Perpetuals

    static let perps = Module(
        id: "perps",
        title: "Perpetuals",
        subtitle: "No expiry, funding rates and liquidations.",
        icon: "infinity",
        color: .pink,
        lessons: [
            Lesson(
                id: "perps.what",
                title: "What is a perp?",
                summary: "A future that never expires.",
                cards: [
                    card("infinity", "No expiry",
                         "A perpetual swap (perp) works like a future but has no expiry date. You can hold it as long as you have margin."),
                    card("bitcoinsign.circle.fill", "Crypto native",
                         "Perps were made popular by crypto exchanges and are now the most traded crypto product."),
                    card("scope", "Tracking spot",
                         "With no expiry pulling price to spot, perps use a trick called funding to stay close to the spot price."),
                    card("arrow.up.arrow.down.circle.fill", "Long or short with leverage",
                         "Like futures, you can go long or short with leverage, often 50x or more. That is dangerous."),
                ],
                quiz: [
                    q("Main difference between a perp and a future?",
                      ["Perps have no expiry", "Perps cannot be shorted", "Perps need no margin"], 0,
                      "Perpetual means it never ends."),
                    q("What keeps a perp near the spot price?",
                      ["Funding payments", "Dividends", "The strike price"], 0,
                      "Funding nudges traders to push the perp back toward spot."),
                    q("Can you short a perp?",
                      ["Yes", "No", "Only on weekends"], 0,
                      "Long and short are both one tap away."),
                ]
            ),
            Lesson(
                id: "perps.funding",
                title: "Funding rate",
                summary: "Longs and shorts pay each other.",
                cards: [
                    card("arrow.left.arrow.right.circle.fill", "Who pays who",
                         "Every few hours (often 8h) longs and shorts pay each other. It is between traders, not the exchange."),
                    card("plus.circle.fill", "Positive funding",
                         "Perp above spot (too many longs). Longs pay shorts. This pushes price back down."),
                    card("minus.circle.fill", "Negative funding",
                         "Perp below spot (too many shorts). Shorts pay longs."),
                    card("dollarsign.circle.fill", "Cost math",
                         "Payment = position size x rate. A $10,000 position at 0.01% pays $1 per period. It adds up over time."),
                ],
                quiz: [
                    q("Funding is positive. Who pays?",
                      ["Shorts pay longs", "Longs pay shorts", "The exchange pays everyone"], 1,
                      "Positive funding: longs pay shorts."),
                    q("$20,000 long, funding 0.05%. Payment?",
                      ["$1", "$10", "$100"], 1,
                      "20,000 x 0.0005 = $10."),
                    q("The perp trades below spot. Funding is usually...",
                      ["Positive", "Negative", "Zero"], 1,
                      "Too many shorts, so shorts pay longs."),
                ]
            ),
            Lesson(
                id: "perps.liquidation",
                title: "Liquidation and mark price",
                summary: "How leveraged traders get wiped out.",
                cards: [
                    card("flame.fill", "Liquidation price",
                         "The price where your margin is almost gone and the exchange closes you. Higher leverage = closer liquidation."),
                    card("function", "Quick estimate",
                         "Long liquidation is about entry x (1 - 1/leverage). At 10x from $100, roughly $90, a bit higher due to maintenance margin."),
                    card("ruler.fill", "Mark price",
                         "Exchanges use a fair mark price (from spot indexes) for liquidations, so one weird trade does not liquidate everyone."),
                    card("checkmark.shield.fill", "Survive",
                         "Use low leverage, set a stop loss and never risk money you cannot lose. Most beginners get liquidated by high leverage."),
                ],
                quiz: [
                    q("Which position is closest to liquidation?",
                      ["2x long", "5x long", "25x long"], 2,
                      "The higher the leverage, the smaller the move that wipes you out."),
                    q("10x long from $200. Rough liquidation price?",
                      ["$180", "$100", "$20"], 0,
                      "200 x (1 - 1/10) = $180."),
                    q("Why do exchanges use a mark price?",
                      ["To avoid unfair liquidations from spikes", "To set fees", "To pick the strike"], 0,
                      "A fair price protects traders from one odd trade."),
                ]
            ),
            Lesson(
                id: "perps.compare",
                title: "Spot vs options vs futures vs perps",
                summary: "Pick the right tool.",
                cards: [
                    card("bag.fill", "Spot",
                         "You own the coin. No leverage, no liquidation, no funding. Simplest and safest."),
                    card("slider.horizontal.3", "Options",
                         "Rights, not obligations. You pay a premium and know your max loss when buying."),
                    card("calendar", "Futures",
                         "Expiry date, price converges to spot, leverage, easy to short."),
                    card("infinity", "Perps",
                         "No expiry, funding payments, leverage, easy to short. The most popular in crypto."),
                ],
                quiz: [
                    q("Which one has no liquidation risk?",
                      ["Spot (no leverage)", "Perp at 10x", "Future at 5x"], 0,
                      "Without leverage, nobody can force you out."),
                    q("Which one pays funding?",
                      ["Spot", "Perps", "Options"], 1,
                      "Funding is how perps track spot."),
                    q("You want a leveraged bet with a known max loss. Best fit?",
                      ["Buy an option", "20x perp", "Short a future"], 0,
                      "Buying an option caps your loss at the premium."),
                ]
            ),
        ]
    )
}

enum Missions {
    static let all: [Mission] = [
        Mission(id: "first_trade", title: "First steps", detail: "Open any trade on the Trade tab.", xp: 20),
        Mission(id: "spot_profit", title: "Buy low, sell high", detail: "Close a spot trade in profit.", xp: 30),
        Mission(id: "short_profit", title: "Win on the way down", detail: "Close a short (future or perp) in profit.", xp: 40),
        Mission(id: "call_profit", title: "Call it", detail: "Make money with a call option.", xp: 40),
        Mission(id: "put_profit", title: "Put to work", detail: "Make money with a put option.", xp: 40),
        Mission(id: "future_expiry", title: "Hold to expiry", detail: "Keep a future open until it settles.", xp: 40),
        Mission(id: "funding_received", title: "Paid to wait", detail: "Receive a funding payment on a perp.", xp: 40),
        Mission(id: "lev_profit", title: "Steady hands", detail: "Close a 10x or higher perp in profit.", xp: 60),
    ]
}

enum Glossary {
    static let terms: [GlossaryTerm] = [
        GlossaryTerm(term: "Ask", definition: "The lowest price a seller accepts. You buy here."),
        GlossaryTerm(term: "Backwardation", definition: "When a future trades below the spot price."),
        GlossaryTerm(term: "Basis", definition: "Futures price minus spot price. Goes to zero at expiry."),
        GlossaryTerm(term: "Bid", definition: "The highest price a buyer offers. You sell here."),
        GlossaryTerm(term: "Breakeven", definition: "The price where a trade makes zero profit. Call: strike + premium. Put: strike - premium."),
        GlossaryTerm(term: "Call", definition: "An option giving the right to buy at the strike before expiry."),
        GlossaryTerm(term: "Contango", definition: "When a future trades above the spot price."),
        GlossaryTerm(term: "Delta", definition: "How much an option price moves for a $1 move in the underlying."),
        GlossaryTerm(term: "Derivative", definition: "A contract whose value comes from an underlying asset."),
        GlossaryTerm(term: "Expiry", definition: "The date an option or future ends and settles."),
        GlossaryTerm(term: "Funding rate", definition: "Periodic payment between perp longs and shorts that keeps the perp near spot."),
        GlossaryTerm(term: "Future", definition: "An obligation to buy or sell an asset at a set price on a set date."),
        GlossaryTerm(term: "Hedge", definition: "A trade that reduces the risk of another position."),
        GlossaryTerm(term: "Intrinsic value", definition: "What an option would be worth if exercised now. Never below zero."),
        GlossaryTerm(term: "Leverage", definition: "Using margin to control a bigger position. Multiplies gains and losses."),
        GlossaryTerm(term: "Limit order", definition: "An order to trade only at your price or better."),
        GlossaryTerm(term: "Liquidation", definition: "When the exchange force closes a leveraged trade because margin is almost gone."),
        GlossaryTerm(term: "Liquidity", definition: "How easily you can trade without moving the price."),
        GlossaryTerm(term: "Long", definition: "A position that profits when price goes up."),
        GlossaryTerm(term: "Margin", definition: "Collateral deposited to open a leveraged position."),
        GlossaryTerm(term: "Mark price", definition: "A fair reference price used for P&L and liquidations."),
        GlossaryTerm(term: "Market order", definition: "An order to trade right now at the best available price."),
        GlossaryTerm(term: "Perpetual (perp)", definition: "A futures style contract with no expiry that uses funding to track spot."),
        GlossaryTerm(term: "P&L", definition: "Profit and loss."),
        GlossaryTerm(term: "Premium", definition: "The price paid for an option."),
        GlossaryTerm(term: "Put", definition: "An option giving the right to sell at the strike before expiry."),
        GlossaryTerm(term: "Short", definition: "A position that profits when price goes down."),
        GlossaryTerm(term: "Spot", definition: "Buying or selling the real asset for immediate delivery."),
        GlossaryTerm(term: "Spread", definition: "The gap between the bid and the ask."),
        GlossaryTerm(term: "Stop loss", definition: "An order that closes a trade to limit losses."),
        GlossaryTerm(term: "Strike", definition: "The fixed price in an option contract."),
        GlossaryTerm(term: "Theta", definition: "How much value an option loses each day from time decay."),
        GlossaryTerm(term: "Underlying", definition: "The asset a derivative is based on."),
        GlossaryTerm(term: "Volatility", definition: "How much and how fast a price swings."),
    ]
}

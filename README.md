# Trador

App entièrement en français, avec des graphiques interactifs dans les leçons (diagrammes de gains des options, levier et liquidation, funding, convergence des futures, valeur temps, carnet d'ordres, frise historique).

A beginner friendly iOS game to learn trading, options, futures, perpetuals (perps) and derivatives.

## What is inside

- **Learn**: 7 modules, 27 short lessons. Each lesson has swipe cards and a 3 question quiz. Pass a lesson (2 of 3 right) to unlock the next one.
  1. Trading Basics
  2. Derivatives 101
  3. Options
  4. Futures
  5. Perpetuals
  6. Hedging Strategies (protective put, covered call, collar, delta neutral, cash and carry, pairs)
  7. Market History (from Mesopotamia to FTX)
- **Trade**: a fake market for a made up coin (TDC) with $10,000 of fake money. Trade spot, buy calls and puts, go long or short on futures and perps with leverage. Funding, expiry and liquidation all work like the real thing, just simplified.
- **Trade history**: every closed trade with P&L, win rate and win streak.
- **Missions**: 13 challenges that give XP, including hedging missions.

## Why it is addictive

Built on the dopamine triggers used in games:

- **Variable rewards**: a mystery chest (Common, Rare, Epic, Legendary) after each new lesson and Daily Challenge. Unpredictable rewards hit hardest.
- **Streaks and loss aversion**: daily streak with a "play today or lose it" warning. Epic chests give streak freezes.
- **Daily Challenge**: 5 questions a day with combo bonuses.
- **Goal gradient**: daily XP ring, level bar and a "Continue" card that always shows the next step.
- **Combos**: "3 in a row" flame during quizzes.
- **Near misses**: "So close! Just 1 more right answer" when you fail by one.
- **Juice**: haptics, confetti and a level up screen.
- **Glossary**: searchable list of key terms.
- **Profile**: level, XP, stats, missions.

Everything runs offline. Progress is saved on the device.

## Run it

Needs a Mac with Xcode 16 or newer. Open `Trador.xcodeproj`, pick an iPhone simulator, press Run.

## Code layout

- `Trador/Models/Curriculum.swift`: all lessons, quizzes, missions and glossary text. Edit here to add content.
- `Trador/Models/ProgressStore.swift`: XP, levels, unlocks, saving.
- `Trador/Models/MarketSim.swift`: the fake market and trading rules.
- `Trador/Views/`: SwiftUI screens.

Trador is for learning only. It is not financial advice.

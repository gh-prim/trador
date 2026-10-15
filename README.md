# Trador

A beginner friendly iOS game to learn trading, options, futures, perpetuals (perps) and derivatives.

## What is inside

- **Learn**: 5 modules, 17 short lessons. Each lesson has swipe cards and a 3 question quiz. Pass a lesson (2 of 3 right) to unlock the next one.
  1. Trading Basics
  2. Derivatives 101
  3. Options
  4. Futures
  5. Perpetuals
- **Trade**: a fake market for a made up coin (TDC) with $10,000 of fake money. Trade spot, buy calls and puts, go long or short on futures and perps with leverage. Funding, expiry and liquidation all work like the real thing, just simplified.
- **Missions**: 8 trading challenges that give XP.
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

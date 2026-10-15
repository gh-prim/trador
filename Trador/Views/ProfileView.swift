import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var progress: ProgressStore
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    XPHeader()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Statistiques") {
                    statRow("Leçons terminées", "\(progress.completedLessons.count)/\(Curriculum.lessonCount)")
                    statRow("Missions terminées", "\(progress.completedMissions.count)/\(Missions.all.count)")
                    statRow("XP total", "\(progress.xp)")
                    statRow("Série actuelle", "\(progress.currentStreak) jours")
                    statRow("Meilleure série", "\(progress.bestStreak) jours")
                    statRow("Gels de série", "\(progress.streakFreezes)")
                    statRow("Coffres ouverts", "\(progress.chestsOpened)")
                }

                Section {
                    ForEach(Missions.all) { mission in
                        let done = progress.isMissionDone(mission)
                        HStack(spacing: 12) {
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(done ? Color.green : Color.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mission.title)
                                    .font(.headline)
                                Text(mission.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("+\(mission.xp) XP")
                                .font(.caption.bold())
                                .foregroundStyle(Color.orange)
                        }
                    }
                } header: {
                    Text("Missions de trading")
                } footer: {
                    Text("Accomplis les missions dans l'onglet Trader, avec de l'argent fictif.")
                }

                Section {
                    Button("Effacer toute la progression", role: .destructive) {
                        confirmReset = true
                    }
                } footer: {
                    Text("Trador sert uniquement à apprendre. En vrai, le trading avec levier peut te faire perdre tout ton argent.")
                }
            }
            .navigationTitle("Profil")
            .confirmationDialog("Effacer tout l'XP, les leçons et les missions ?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Effacer la progression", role: .destructive) { progress.resetAll() }
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

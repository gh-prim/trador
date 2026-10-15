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

                Section("Stats") {
                    statRow("Lessons done", "\(progress.completedLessons.count)/\(Curriculum.lessonCount)")
                    statRow("Missions done", "\(progress.completedMissions.count)/\(Missions.all.count)")
                    statRow("Total XP", "\(progress.xp)")
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
                    Text("Trading missions")
                } footer: {
                    Text("Complete missions on the Trade tab with fake money.")
                }

                Section {
                    Button("Reset all progress", role: .destructive) {
                        confirmReset = true
                    }
                } footer: {
                    Text("Trador is for learning only. Real trading with leverage can lose all your money.")
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog("Erase all XP, lessons and missions?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset progress", role: .destructive) { progress.resetAll() }
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

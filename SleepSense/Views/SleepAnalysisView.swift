import SwiftUI

struct SleepAnalysisView: View {
    @StateObject private var viewModel = SleepAnalysisViewModel()
    @State private var showingNotesEntryFor: SleepEntry?
    @State private var notesText: String = ""

    var body: some View {
        VStack {
            WeeklySleepChart(data: viewModel.weeklyStats)
                .frame(height: 200)
                .padding()

            List {
                ForEach(viewModel.entries, id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate(entry.date))
                                .font(.headline)
                            Text("Total: \(formattedDuration(entry.totalSleep))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let notes = entry.notes, !notes.isEmpty {
                                Text("Notes: \(notes)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button(action: {
                            showingNotesEntryFor = entry
                            notesText = entry.notes ?? ""
                        }) {
                            Image(systemName: "square.and.pencil")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
        .navigationTitle("Sleep Analysis")
        .onAppear {
            viewModel.fetchWeek()
        }
        .sheet(item: $showingNotesEntryFor) { entry in
            NavigationView {
                Form {
                    Section(header: Text("Notes")) {
                        TextEditor(text: $notesText)
                            .frame(minHeight: 120)
                    }
                }
                .navigationBarTitle("Edit Notes", displayMode: .inline)
                .navigationBarItems(leading: Button("Cancel") {
                    showingNotesEntryFor = nil
                }, trailing: Button("Save") {
                    if let id = entry.id {
                        viewModel.updateNotes(for: id, notes: notesText)
                    }
                    showingNotesEntryFor = nil
                })
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown date" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: seconds) ?? "-"
    }
}

struct WeeklySleepChart: View {
    let data: [Date: TimeInterval]

    private var sortedEntries: [(date: Date, value: TimeInterval)] {
        data.sorted { $0.key < $1.key }
            .map { (date: $0.key, value: $0.value) }
    }

    private var maxValue: TimeInterval {
        sortedEntries.map { $0.value }.max() ?? 1
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(sortedEntries, id: \.date) { entry in
                    let heightRatio = maxValue > 0 ? entry.value / maxValue : 0
                    VStack {
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .bottom, endPoint: .top))
                            .frame(width: (geometry.size.width / CGFloat(max(sortedEntries.count, 1))) - 12,
                                   height: max(8, geometry.size.height * CGFloat(heightRatio)))
                            .cornerRadius(4)
                        Text(shortWeekday(entry.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

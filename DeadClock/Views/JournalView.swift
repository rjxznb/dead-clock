import SwiftUI

struct JournalView: View {
    enum ActiveSheet: Identifiable {
        case poster(JournalEntry)
        case summary(SummaryPeriod)

        var id: String {
            switch self {
            case .poster(let entry): return "poster-\(entry.dateKey)"
            case .summary(let period): return "summary-\(period.rawValue)"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var entries = JournalStore.load()
    @State private var activeSheet: ActiveSheet?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 52))
                            .foregroundStyle(.tertiary)
                        Text("journal.empty.title")
                            .font(.headline)
                        Text("journal.empty.body")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        Section {
                            ForEach(entries) { entry in
                                Button {
                                    activeSheet = .poster(entry)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(dateLabel(for: entry))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Theme.rainbow)
                                        Text(entry.text)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(3)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .onDelete(perform: delete)
                        } header: {
                            Text(String(format: NSLocalizedString("streak.line", comment: ""),
                                        JournalStore.streak, entries.count))
                        } footer: {
                            Text("journal.footer")
                        }
                    }
                }
            }
            .navigationTitle(Text("journal.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(SummaryPeriod.allCases) { period in
                            Button {
                                activeSheet = .summary(period)
                            } label: {
                                Text(period.titleKey)
                            }
                        }
                    } label: {
                        Label("summary.menu", systemImage: "sparkles.rectangle.stack")
                    }
                    .disabled(entries.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.done") { dismiss() }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .poster(let entry):
                PosterSheet(entry: entry)
            case .summary(let period):
                SummaryPosterSheet(period: period)
            }
        }
    }

    private func dateLabel(for entry: JournalEntry) -> String {
        guard let date = JournalStore.date(fromKey: entry.dateKey) else { return entry.dateKey }
        let label = date.formatted(.dateTime.month().day().weekday(.wide))
        if entry.dateKey == JournalStore.dateKey(for: Date()) {
            return label + NSLocalizedString("journal.today.suffix", comment: "")
        }
        return label
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            JournalStore.delete(entries[i])
        }
        entries = JournalStore.load()
    }
}

#Preview {
    JournalView()
}

import SwiftUI
import WidgetKit

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var focused: Bool

    init() {
        _text = State(initialValue: JournalStore.entry()?.text ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("checkin.title")
                .font(.title3.bold())
            Text(dateLine)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $text)
                .focused($focused)
                .frame(height: 150)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("checkin.placeholder")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }

            Button {
                save()
            } label: {
                Text("checkin.save")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.actionGradient, in: Capsule())
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
        }
        .padding(22)
        .presentationDetents([.height(340), .medium])
        .presentationDragIndicator(.visible)
        .onAppear { focused = true }
    }

    private var dateLine: String {
        let dateStr = Date().formatted(.dateTime.year().month().day().weekday(.wide))
        let dayN = Int(Date().timeIntervalSince(DeathClock.birthDate) / 86400) + 1
        let dayStr = String(format: NSLocalizedString("life.day.n", comment: ""), dayN.formatted())
        return "\(dateStr) · \(dayStr)"
    }

    private func save() {
        JournalStore.save(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        ReminderManager.reschedule()   // 今晚的提醒不再需要
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

#Preview {
    CheckInView()
}

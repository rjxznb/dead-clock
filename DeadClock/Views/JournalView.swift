import SwiftUI

struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entries = JournalStore.load()
    @State private var selected: JournalEntry?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 52))
                            .foregroundStyle(.tertiary)
                        Text("还没有记录")
                            .font(.headline)
                        Text("每天记下一件让你开心或有意义的事，\n它们会在这里慢慢积累成你的人生足迹。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        Section {
                            ForEach(entries) { entry in
                                Button {
                                    selected = entry
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
                            Text("🔥 连续 \(JournalStore.streak) 天 · 共 \(entries.count) 个美好瞬间")
                        } footer: {
                            Text("点击任意一条记录可生成分享海报")
                        }
                    }
                }
            }
            .navigationTitle("足迹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .sheet(item: $selected) { entry in
            PosterSheet(entry: entry)
        }
    }

    private func dateLabel(for entry: JournalEntry) -> String {
        guard let date = JournalStore.date(fromKey: entry.dateKey) else { return entry.dateKey }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        let label = f.string(from: date)
        if entry.dateKey == JournalStore.dateKey(for: Date()) {
            return label + " · 今天"
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

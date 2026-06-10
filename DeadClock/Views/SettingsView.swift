import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var birthDate = DeathClock.birthDate
    @State private var lifeExpectancy = DeathClock.lifeExpectancyYears

    var body: some View {
        NavigationStack {
            Form {
                Section("你的时间") {
                    DatePicker("出生日期",
                               selection: $birthDate,
                               in: ...Date(),
                               displayedComponents: .date)

                    Stepper(value: $lifeExpectancy, in: 40...120, step: 1) {
                        HStack {
                            Text("预期寿命")
                            Spacer()
                            Text("\(Int(lifeExpectancy)) 岁")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    LabeledContent("预计死亡日期") {
                        Text(deathDateString)
                    }
                } footer: {
                    Text("中国居民人均预期寿命约 78 岁。这个数字只是提醒：时间有限，现在就去做重要的事。")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        save()
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var deathDateString: String {
        let death = birthDate.addingTimeInterval(lifeExpectancy * DeathClock.secondsPerYear)
        return death.formatted(date: .long, time: .omitted)
    }

    private func save() {
        DeathClock.birthDate = birthDate
        DeathClock.lifeExpectancyYears = lifeExpectancy
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    SettingsView()
}

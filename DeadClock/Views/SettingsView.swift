import SwiftUI
import PhotosUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var birthDate = DeathClock.birthDate
    @State private var lifeExpectancy = DeathClock.lifeExpectancyYears

    @State private var theme = ThemeStore.current
    @State private var photoItem: PhotosPickerItem?
    @State private var hasPhoto = ThemeStore.loadPhoto() != nil

    @State private var reminderOn = ReminderManager.isEnabled
    @State private var reminderTime: Date = {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = ReminderManager.hour
        comps.minute = ReminderManager.minute
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var showDeniedAlert = false

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

                    LabeledContent("旅程终点") {
                        Text(deathDateString)
                    }
                }

                Section("外观") {
                    Picker("主题", selection: $theme) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.label).tag(t)
                        }
                    }

                    if theme == .photo {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(hasPhoto ? "更换背景照片" : "选择背景照片",
                                  systemImage: "photo.on.rectangle.angled")
                        }
                    }
                }

                Section {
                    Toggle("睡前提醒打卡", isOn: $reminderOn)
                    if reminderOn {
                        DatePicker("提醒时间",
                                   selection: $reminderTime,
                                   displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("每日提醒")
                } footer: {
                    Text("到点提醒你记录今天最开心或最有意义的一件事；当天已打卡的话不会打扰你。时间有限，去做让你快乐和有意义的事。")
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
            .onChange(of: photoItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        ThemeStore.savePhoto(data)
                        hasPhoto = true
                    }
                }
            }
            .onChange(of: reminderOn) { on in
                if on {
                    ReminderManager.requestAuthorizationAndEnable { granted in
                        if !granted {
                            reminderOn = false
                            showDeniedAlert = true
                        }
                    }
                } else {
                    ReminderManager.disable()
                }
            }
            .alert("通知权限未开启", isPresented: $showDeniedAlert) {
                Button("好") {}
            } message: {
                Text("请到 系统设置 → 通知 → OneLife 里允许通知，然后再打开这个开关。")
            }
        }
        .preferredColorScheme(theme.palette.isLight ? .light : .dark)
    }

    private var deathDateString: String {
        let death = birthDate.addingTimeInterval(lifeExpectancy * DeathClock.secondsPerYear)
        return death.formatted(date: .long, time: .omitted)
    }

    private func save() {
        DeathClock.birthDate = birthDate
        DeathClock.lifeExpectancyYears = lifeExpectancy
        ThemeStore.current = theme
        if reminderOn {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            ReminderManager.hour = comps.hour ?? 22
            ReminderManager.minute = comps.minute ?? 0
            ReminderManager.reschedule()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    SettingsView()
}

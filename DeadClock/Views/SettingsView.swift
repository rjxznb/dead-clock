import SwiftUI
import PhotosUI
import WidgetKit

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return String(localized: "lang.system")
        case .chinese: return "简体中文"
        case .english: return "English"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var birthDate = DeathClock.birthDate
    @State private var lifeExpectancy = DeathClock.lifeExpectancyYears

    @State private var theme = ThemeStore.current
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photoCount = ThemeStore.photoCount

    @State private var language: AppLanguage = AppLanguage(
        rawValue: UserDefaults.standard.string(forKey: "appLanguageChoice") ?? "system") ?? .system
    @State private var showRestartAlert = false

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
                Section("settings.yourtime") {
                    DatePicker("settings.birthdate",
                               selection: $birthDate,
                               in: ...Date(),
                               displayedComponents: .date)

                    Stepper(value: $lifeExpectancy, in: 40...120, step: 1) {
                        HStack {
                            Text("settings.expectancy")
                            Spacer()
                            Text(String(format: NSLocalizedString("settings.age.format", comment: ""),
                                        Int(lifeExpectancy)))
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent("settings.deathdate") {
                        Text(deathDateString)
                    }
                }

                Section("settings.appearance") {
                    Picker("settings.theme", selection: $theme) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.label).tag(t)
                        }
                    }

                    Picker("settings.language", selection: $language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.label).tag(lang)
                        }
                    }
                    .onChange(of: language) { newValue in
                        UserDefaults.standard.set(newValue.rawValue, forKey: "appLanguageChoice")
                        if newValue == .system {
                            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                        } else {
                            UserDefaults.standard.set([newValue.rawValue], forKey: "AppleLanguages")
                        }
                        showRestartAlert = true
                    }
                    .alert("settings.language.restart.title", isPresented: $showRestartAlert) {
                        Button("settings.alert.ok") {}
                    } message: {
                        Text("settings.language.restart.body")
                    }

                    if theme == .photo {
                        PhotosPicker(selection: $photoItems,
                                     maxSelectionCount: 9,
                                     matching: .images) {
                            Label(photoCount > 0
                                    ? String(format: NSLocalizedString("settings.photo.change", comment: ""), photoCount)
                                    : String(localized: "settings.photo.pick"),
                                  systemImage: "photo.on.rectangle.angled")
                        }
                    }
                }

                Section {
                    Toggle("settings.reminder.toggle", isOn: $reminderOn)
                    if reminderOn {
                        DatePicker("settings.reminder.time",
                                   selection: $reminderTime,
                                   displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("settings.reminder.section")
                } footer: {
                    Text("settings.reminder.footer")
                }
            }
            .navigationTitle(Text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.done") {
                        save()
                        dismiss()
                    }
                }
            }
            .onChange(of: photoItems) { items in
                guard !items.isEmpty else { return }
                Task {
                    var datas: [Data] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            datas.append(data)
                        }
                    }
                    if !datas.isEmpty {
                        ThemeStore.savePhotos(datas)
                        photoCount = datas.count
                    }
                }
            }
            .onChange(of: reminderTime) { newTime in
                // 改完时间立即生效，不依赖“完成”按钮
                guard reminderOn else { return }
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                ReminderManager.hour = comps.hour ?? 22
                ReminderManager.minute = comps.minute ?? 0
                ReminderManager.reschedule()
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
            .alert("settings.alert.title", isPresented: $showDeniedAlert) {
                Button("settings.alert.ok") {}
            } message: {
                Text("settings.alert.body")
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
        PhoneSync.push()   // sync to Apple Watch
    }
}

#Preview {
    SettingsView()
}

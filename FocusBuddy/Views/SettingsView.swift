import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var focusTimer: FocusTimer
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("⚙️")
                        .font(.system(size: 28))
                    
                    Text("Настройки")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Персонализируйте ваш опыт использования")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    // Notifications Settings
                    SettingsSection(title: "🔔 Уведомления", description: "Настройки оповещений и звуков") {
                        VStack(spacing: 12) {
                            SettingsToggle(
                                title: "Системные уведомления",
                                description: "Показывать уведомления macOS",
                                isOn: $focusTimer.notificationsEnabled
                            )
                            
                            SettingsToggle(
                                title: "Звуковые оповещения",
                                description: "Воспроизводить звук при смене фазы",
                                isOn: $focusTimer.soundEnabled
                            )
                        }
                    }
                    
                    // Timer Durations
                    TimerDurationSettings()
                    
                    // Appearance Settings
                    AppearanceSettings()
                    
                    // Advanced Settings
                    AdvancedSettings()
                    
                    // Debug Section (for development)
                    DebugSection()
                    
                    // About Section
                    AboutSection()
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 20)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
    }
}

struct TimerDurationSettings: View {
    @EnvironmentObject var focusTimer: FocusTimer
    @State private var focusMinutes = 25
    @State private var shortBreakMinutes = 5
    @State private var longBreakMinutes = 15
    
    var body: some View {
        SettingsSection(title: "⏱️ Длительность", description: "Настройте продолжительность каждой фазы") {
            VStack(spacing: 16) {
                DurationPicker(
                    title: "Фокус-сессия",
                    value: $focusMinutes,
                    range: 5...120
                )
                
                DurationPicker(
                    title: "Короткий перерыв",
                    value: $shortBreakMinutes,
                    range: 1...30
                )
                
                DurationPicker(
                    title: "Длинный перерыв",
                    value: $longBreakMinutes,
                    range: 5...60
                )
            }
        }
        .onAppear {
            focusMinutes = focusTimer.currentPreset.focusMinutes
            shortBreakMinutes = focusTimer.currentPreset.shortBreakMinutes
            longBreakMinutes = focusTimer.currentPreset.longBreakMinutes
        }
    }
}

struct DurationPicker: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(value) минут")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Stepper(value: $value, in: range) {
                EmptyView()
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct AppearanceSettings: View {
    @AppStorage("preferredColorScheme") private var preferredColorScheme = "system"
    @AppStorage("reducedMotion") private var reducedMotion = false
    @AppStorage("showMenuBarTime") private var showMenuBarTime = true
    
    var body: some View {
        SettingsSection(title: "🎨 Внешний вид", description: "Настройки отображения интерфейса") {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Цветовая схема")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Системная, светлая или темная")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $preferredColorScheme) {
                        Text("Системная").tag("system")
                        Text("Светлая").tag("light")
                        Text("Темная").tag("dark")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                Divider()
                
                SettingsToggle(
                    title: "Время в меню",
                    description: "Показывать оставшееся время в строке меню",
                    isOn: $showMenuBarTime
                )
                
                SettingsToggle(
                    title: "Уменьшенная анимация",
                    description: "Меньше движения в интерфейсе",
                    isOn: $reducedMotion
                )
            }
        }
    }
}

struct AdvancedSettings: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideFromDock") private var hideFromDock = false
    @AppStorage("enableAnalytics") private var enableAnalytics = true
    
    var body: some View {
        SettingsSection(title: "🔧 Дополнительно", description: "Расширенные настройки приложения") {
            VStack(spacing: 12) {
                SettingsToggle(
                    title: "Запуск при входе",
                    description: "Автоматически запускать при старте macOS",
                    isOn: $launchAtLogin
                )
                
                SettingsToggle(
                    title: "Скрыть из Dock",
                    description: "Показывать только в строке меню",
                    isOn: $hideFromDock
                )
                
                SettingsToggle(
                    title: "Аналитика использования",
                    description: "Помочь улучшить приложение (анонимно)",
                    isOn: $enableAnalytics
                )
                
                Divider()
                
                HStack {
                    Button("Сбросить статистику") {
                        resetStatistics()
                    }
                    .foregroundStyle(.red)
                    
                    Spacer()
                    
                    Button("Экспорт данных") {
                        exportData()
                    }
                }
                .font(.footnote)
            }
        }
    }
    
    private func resetStatistics() {
        // Reset statistics logic
        let alert = NSAlert()
        alert.messageText = "Сбросить статистику?"
        alert.informativeText = "Это действие нельзя отменить."
        alert.addButton(withTitle: "Сбросить")
        alert.addButton(withTitle: "Отмена")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Reset logic here
        }
    }
    
    private func exportData() {
        // Export data logic
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "focus-buddy-data.json"
        savePanel.allowedContentTypes = [.json]
        
        savePanel.begin { response in
            if response == .OK {
                // Export logic here
            }
        }
    }
}

struct AboutSection: View {
    var body: some View {
        SettingsSection(title: "ℹ️ О приложении", description: "Информация о Focus Buddy") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Focus Buddy")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Версия 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "timer")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                }
                
                Text("Современный Pomodoro таймер для macOS. Повышайте продуктивность с умными уведомлениями и отслеживанием прогресса.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                
                Divider()
                
                HStack {
                    Link("🌐 Сайт", destination: URL(string: "https://focusbuddy.app")!)
                    
                    Spacer()
                    
                    Link("💌 Поддержка", destination: URL(string: "mailto:support@focusbuddy.app")!)
                    
                    Spacer()
                    
                    Link("⭐ Оценить", destination: URL(string: "macappstore://itunes.apple.com/app/id123456789?action=write-review")!)
                }
                .font(.footnote)
            }
        }
    }
}

struct DebugSection: View {
    @EnvironmentObject var focusTimer: FocusTimer
    @State private var debugOutput: String = ""
    @State private var showConsole = false
    
    var body: some View {
        SettingsSection(title: "🐛 Отладка", description: "Инструменты для разработки (тестовая версия)") {
            VStack(spacing: 12) {
                // Request Permissions Button
                Button("🔐 Запросить разрешения") {
                    Task {
                        do {
                            try await focusTimer.requestNotificationPermissions()
                        } catch {
                            print("Failed to request permissions: \(error)")
                        }
                    }
                }
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
                
                // Check Permissions Button
                Button("🔔 Проверить разрешения") {
                    focusTimer.debugNotificationPermissions()
                }
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                // Open System Settings Button
                Button("🔧 Открыть Системные настройки") {
                    focusTimer.openNotificationSettings()
                }
                .foregroundStyle(.indigo)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.indigo.opacity(0.1))
                .cornerRadius(8)
                
                // Notification Test Button
                Button("🧪 Тестовое уведомление") {
                    focusTimer.testNotification()
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // System Notification Test
                Button("🧪 Тест уведомления") {
                    focusTimer.testNotification()
                }
                .foregroundStyle(.teal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.teal.opacity(0.1))
                .cornerRadius(8)
                
                // Direct Notification Test
                Button("📢 Тест уведомления") {
                    focusTimer.testNotification()
                }
                .foregroundStyle(.mint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.mint.opacity(0.1))
                .cornerRadius(8)
                
                // Test All Methods
                Button("🚀 Полный тест") {
                    focusTimer.testRealNotificationFlow()
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                
                // Timer State Debug
                Button("⏱️ Состояние таймера") {
                    focusTimer.debugCurrentTimerState()
                }
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                Divider()
                
                // Quick Timer Controls for Testing
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button("15s Focus") {
                            focusTimer.currentPhase = .focus
                            focusTimer.timeRemaining = 15
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                        
                        Button("5s Break") {
                            focusTimer.currentPhase = .shortBreak
                            focusTimer.timeRemaining = 5
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                        
                        Button("Reset") {
                            focusTimer.stopTimer()
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                    
                    Button("⚡ РЕАЛЬНЫЙ ТЕСТ (10с)") {
                        focusTimer.startQuickTest()
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
                    
                    // Test real notification
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Button("🧪 Симуляция завершения фазы") {
                                // Simulate phase completion for testing
                                let nextPhase: TimerPhase = focusTimer.currentPhase == .focus ? .shortBreak : .focus
                                focusTimer.debugPhaseCompletion(nextPhase: nextPhase)
                            }
                            .font(.caption2)
                            .foregroundStyle(.purple)
                            
                            Button("🔥 Полный тест") {
                                focusTimer.testRealNotificationFlow()
                            }
                            .font(.caption2)
                            .foregroundStyle(.red)
                        }
                    }
                }
                
                // Console Toggle
                Toggle("Показать консоль отладки", isOn: $showConsole)
                    .font(.caption)
                
                if showConsole {
                    ScrollView {
                        ScrollViewReader { proxy in
                            Text(focusTimer.debugOutput)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(4)
                                .id("debugLog")
                                .onChange(of: focusTimer.debugOutput) {
                                    withAnimation {
                                        proxy.scrollTo("debugLog", anchor: .bottom)
                                    }
                                }
                        }
                    }
                    .frame(height: 120)
                    
                    HStack {
                        Button("Очистить логи") {
                            focusTimer.debugOutput = "Debug log:\n"
                        }
                        .font(.caption2)
                        .foregroundStyle(.red)
                        
                        Spacer()
                        
                        Button("Копировать") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(focusTimer.debugOutput, forType: .string)
                        }
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(FocusTimer())
        .frame(width: 380, height: 600)
}
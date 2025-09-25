import Foundation
import SwiftUI
import UserNotifications
import AVFoundation

enum TimerPhase: String, CaseIterable {
    case focus = "focus"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"
    
    var emoji: String {
        switch self {
        case .focus: return ""
        case .shortBreak: return ""
        case .longBreak: return ""
        }
    }
    
    var title: String {
        switch self {
        case .focus: return "Фокус"
        case .shortBreak: return "Короткий перерыв"
        case .longBreak: return "Длинный перерыв"
        }
    }
    
    var description: String {
        switch self {
        case .focus: return "Время сосредоточиться на задаче"
        case .shortBreak: return "Небольшой отдых для восстановления"
        case .longBreak: return "Заслуженный длинный отдых"
        }
    }
}

enum TimerState {
    case stopped
    case running
    case paused
    case stoppedForToday
}

struct TimerPreset: Equatable {
    let name: String
    let emoji: String
    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let description: String
    
    static let classic = TimerPreset(
        name: "25/5",
        emoji: "⏰",
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        description: "Классический режим"
    )
    
    static let deepWork = TimerPreset(
        name: "50/10",
        emoji: "🧠",
        focusMinutes: 50,
        shortBreakMinutes: 10,
        longBreakMinutes: 20,
        description: "Глубокая работа"
    )
    
    static let sprint = TimerPreset(
        name: "15/3",
        emoji: "⚡",
        focusMinutes: 15,
        shortBreakMinutes: 3,
        longBreakMinutes: 10,
        description: "Быстрые спринты"
    )
}

class FocusTimer: ObservableObject {
    @Published var currentPhase: TimerPhase = .focus
    @Published var timeRemaining: Int = 25 * 60 // seconds
    @Published var timerState: TimerState = .stopped
    @Published var completedCycles: Int = 0
    @Published var currentPreset: TimerPreset = .classic
    @Published var todayFocusMinutes: Int = 0
    @Published var weekFocusMinutes: Int = 0
    @Published var currentStreak: Int = 0
    
    // Debug output
    @Published var debugOutput: String = "Debug log:\n"
    
    private var timer: Timer?
    private var dailyResetTimer: Timer?
    private var startTime: Date?
    private var pausedTime: Date?
    
    // Settings
    @Published var soundEnabled: Bool = true {
        didSet { saveSettings() }
    }
    @Published var notificationsEnabled: Bool = true {
        didSet { saveSettings() }
    }
    @Published var autoStartBreaks: Bool = true {
        didSet { saveSettings() }
    }
    @Published var autoStartFocus: Bool = true {
        didSet { saveSettings() }
    }
    
    
    init() {
        resetTimer()
        loadSettings()
        loadStatistics()
        addDebugLog("🚀 FocusTimer инициализирован")
    }
    
    deinit {
        timer?.invalidate()
        dailyResetTimer?.invalidate()
    }
    
    // MARK: - Timer Controls
    
    func startTimer() {
        guard timerState != .stoppedForToday else { return }

        // Stop any existing timer first
        stopTimer()

        timerState = .running
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }

        scheduleNotification()
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .paused
        pausedTime = Date()
        cancelNotification()
    }
    
    func resumeTimer() {
        guard timerState == .paused else { return }

        timerState = .running

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }

        scheduleNotification()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .stopped
        resetCurrentPhase()
        cancelNotification()
    }
    
    func stopForToday() {
        timer?.invalidate()
        timer = nil
        timerState = .stoppedForToday
        cancelNotification()
        
        // Reset at midnight
        scheduleResetForTomorrow()
    }
    
    private func updateTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.timerState == .running, self.timeRemaining > 0 else {
                self?.completeCurrentPhase()
                return
            }
            self.timeRemaining -= 1
        }
    }
    
    private func completeCurrentPhase() {
        // Prevent multiple completions
        guard timerState == .running else { return }

        timer?.invalidate()
        timer = nil

        // Record completed session
        recordCompletedSession()

        // Determine next phase
        let nextPhase = getNextPhase()

        // Show notification
        showPhaseCompletionNotification(nextPhase: nextPhase)

        // Update phase and reset timer
        currentPhase = nextPhase
        resetCurrentPhase()

        // Auto-start next phase if enabled
        if shouldAutoStartNextPhase() {
            timerState = .stopped
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self, self.timerState == .stopped else { return }
                self.startTimer()
            }
        } else {
            timerState = .stopped
        }
    }
    
    private func getNextPhase() -> TimerPhase {
        switch currentPhase {
        case .focus:
            completedCycles += 1
            return (completedCycles % 4 == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }
    
    private func shouldAutoStartNextPhase() -> Bool {
        switch currentPhase {
        case .focus:
            return autoStartBreaks
        case .shortBreak, .longBreak:
            return autoStartFocus
        }
    }
    
    // MARK: - Preset Management
    
    func changePreset(_ preset: TimerPreset) {
        currentPreset = preset
        resetTimer()
    }
    
    private func resetCurrentPhase() {
        let minutes: Int
        switch currentPhase {
        case .focus:
            minutes = currentPreset.focusMinutes
        case .shortBreak:
            minutes = currentPreset.shortBreakMinutes
        case .longBreak:
            minutes = currentPreset.longBreakMinutes
        }
        timeRemaining = minutes * 60
    }
    
    private func resetTimer() {
        currentPhase = .focus
        resetCurrentPhase()
        timerState = .stopped
    }
    
    // MARK: - Debug Functions
    
    private func addDebugLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        DispatchQueue.main.async {
            self.debugOutput += "[\(timestamp)] \(message)\n"
        }
        print("[\(timestamp)] \(message)")
    }
    
    func requestNotificationPermissions() {
        addDebugLog("🔐 Запрос разрешений на уведомления...")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    let errorCode = (error as NSError).code
                    self?.addDebugLog("❌ Ошибка запроса разрешений: \(error.localizedDescription) (код: \(errorCode))")
                    
                    if errorCode == 1 { // UNErrorCodeNotificationsNotAllowed
                        self?.addDebugLog("💡 Решение: откройте Системные настройки → Уведомления → Focus Buddy")
                        self?.addDebugLog("💡 Или попробуйте запустить: open 'x-apple.systempreferences:com.apple.preference.notifications'")
                    }
                } else if granted {
                    self?.addDebugLog("✅ Разрешения на уведомления получены")
                } else {
                    self?.addDebugLog("❌ Разрешения на уведомления отклонены пользователем")
                }
            }
        }
    }
    
    func openNotificationSettings() {
        addDebugLog("🔧 Открытие настроек уведомлений...")
        
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
            addDebugLog("✅ Настройки уведомлений открыты. Найдите 'Focus Buddy' в списке и включите уведомления")
        } else {
            addDebugLog("❌ Не удалось открыть настройки уведомлений")
        }
    }
    
    
    func sendNotification(title: String, body: String) {
        guard notificationsEnabled else {
            addDebugLog("🔕 Уведомления отключены, пропускаем: \(title)")
            return
        }

        addDebugLog("📢 Отправка уведомления: \(title)")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = soundEnabled ? .default : nil

        let request = UNNotificationRequest(
            identifier: "focus-buddy-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.addDebugLog("❌ Ошибка отправки уведомления: \(error.localizedDescription)")
                } else {
                    self?.addDebugLog("✅ Уведомление отправлено успешно!")
                }
            }
        }
    }
    
    func testNotification() {
        sendNotification(title: "🧪 Focus Buddy Test", body: "Если вы видите это - уведомления работают!")
    }
    
    func debugPhaseCompletion(nextPhase: TimerPhase) {
        addDebugLog("🧪 Симуляция завершения фазы \(currentPhase.title) -> \(nextPhase.title)")
        
        // Record the phase completion
        let currentPhaseName = currentPhase.title
        
        // Call the real notification system
        showPhaseCompletionNotification(nextPhase: nextPhase)
        
        addDebugLog("✅ Симуляция завершена для фазы: \(currentPhaseName)")
    }
    
    func testRealNotificationFlow() {
        addDebugLog("🔥 ТЕСТ: Полная проверка уведомлений при смене фазы")
        
        // Test Focus to Break transition
        addDebugLog("--- Тестируем переход Фокус -> Перерыв ---")
        currentPhase = .focus
        showPhaseCompletionNotification(nextPhase: .shortBreak)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.addDebugLog("--- Тестируем переход Перерыв -> Фокус ---")
            self?.currentPhase = .shortBreak
            self?.showPhaseCompletionNotification(nextPhase: .focus)
        }
        
        addDebugLog("🏁 Тест запущен - ожидайте 2 уведомления с интервалом в 3 секунды")
    }
    
    func startQuickTest() {
        addDebugLog("⚡ БЫСТРЫЙ ТЕСТ: Запуск 10-секундного фокус-таймера")
        
        // Stop any current timer
        stopTimer()
        
        // Set to focus phase with 10 seconds
        currentPhase = .focus
        timeRemaining = 10
        timerState = .running
        
        // Start timer
        startTimer()
        
        addDebugLog("⏰ Таймер запущен на 10 секунд. Ожидайте автоматическое уведомление о завершении!")
    }
    
    
    func debugNotificationPermissions() {
        addDebugLog("🔔 Проверка разрешений уведомлений...")
        
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                let status = self?.authStatusToString(settings.authorizationStatus) ?? "неизвестно"
                self?.addDebugLog("📋 Разрешения уведомлений:")
                self?.addDebugLog("   - Статус авторизации: \(status)")
                self?.addDebugLog("   - Алерты: \(self?.settingToString(settings.alertSetting) ?? "неизвестно")")
                self?.addDebugLog("   - Звуки: \(self?.settingToString(settings.soundSetting) ?? "неизвестно")")
                self?.addDebugLog("   - Бейджи: \(self?.settingToString(settings.badgeSetting) ?? "неизвестно")")
                self?.addDebugLog("   - Banner: \(self?.settingToString(settings.notificationCenterSetting) ?? "неизвестно")")
                self?.addDebugLog("   - Lock Screen: \(self?.settingToString(settings.lockScreenSetting) ?? "неизвестно")")
                self?.addDebugLog("   - Включены в приложении: \(self?.notificationsEnabled ?? false)")
                
            }
        }
    }
    
    
    func debugCurrentTimerState() {
        addDebugLog("⏱️ Текущее состояние таймера:")
        addDebugLog("   - Фаза: \(currentPhase.title)")
        addDebugLog("   - Состояние: \(timerStateToString(timerState))")
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        let timeFormatted = String(format: "%d:%02d", minutes, seconds)
        addDebugLog("   - Осталось времени: \(timeRemaining) секунд (\(timeFormatted))")
        addDebugLog("   - Завершенные циклы: \(completedCycles)")
        addDebugLog("   - Авто-старт перерывов: \(autoStartBreaks)")
        addDebugLog("   - Авто-старт работы: \(autoStartFocus)")
        addDebugLog("   - Пресет: \(currentPreset.name)")
    }
    
    private func authStatusToString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "не определено"
        case .denied: return "запрещено"
        case .authorized: return "разрешено"
        case .provisional: return "временное"
        case .ephemeral: return "эфемерное"
        @unknown default: return "неизвестно"
        }
    }
    
    private func settingToString(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "не поддерживается"
        case .disabled: return "отключено"
        case .enabled: return "включено"
        @unknown default: return "неизвестно"
        }
    }
    
    private func timerStateToString(_ state: TimerState) -> String {
        switch state {
        case .stopped: return "остановлен"
        case .running: return "работает"
        case .paused: return "на паузе"
        case .stoppedForToday: return "остановлен на сегодня"
        }
    }
    
    // MARK: - Notifications
    
    private func showPhaseCompletionNotification(nextPhase: TimerPhase) {
        guard notificationsEnabled else {
            addDebugLog("🔕 Уведомление о завершении фазы пропущено (отключены)")
            return
        }
        
        let (title, body) = getNotificationContent(for: nextPhase)
        addDebugLog("📢 Отправка уведомления: \(title)")

        // Use unified notification method
        sendNotification(title: title, body: body)
    }
    
    
    
    private func getNotificationContent(for nextPhase: TimerPhase) -> (title: String, body: String) {
        switch currentPhase {
        case .focus:
            return ("🎉 Отличная работа!", "Сейчас время отдохнуть - \(nextPhase.title.lowercased())")
        case .shortBreak, .longBreak:
            return ("⏰ Перерыв окончен", "Сейчас время работать - возвращаемся к задачам")
        }
    }
    
    
    private func scheduleNotification() {
        // We don't use scheduled notifications anymore since they don't work reliably
        // Notifications are sent immediately when phase completes in completeCurrentPhase()
        addDebugLog("⏰ Система планируемых уведомлений отключена - используем немедленные")
    }
    
    private func cancelNotification() {
        // Clear any pending UNUserNotificationCenter notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["timer-complete", "phase-complete"]
        )
        addDebugLog("🗑️ Планируемые уведомления очищены")
    }
    
    // MARK: - Statistics & Data
    
    private func recordCompletedSession() {
        let sessionMinutes = getCurrentPhaseMinutes()
        
        if currentPhase == .focus {
            todayFocusMinutes += sessionMinutes
            weekFocusMinutes += sessionMinutes
        }
        
        // Save to UserDefaults or Core Data
        saveStatistics()
    }
    
    private func getCurrentPhaseMinutes() -> Int {
        switch currentPhase {
        case .focus: return currentPreset.focusMinutes
        case .shortBreak: return currentPreset.shortBreakMinutes
        case .longBreak: return currentPreset.longBreakMinutes
        }
    }
    
    
    // MARK: - Persistence
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true
        autoStartBreaks = defaults.object(forKey: "autoStartBreaks") as? Bool ?? true
        autoStartFocus = defaults.object(forKey: "autoStartFocus") as? Bool ?? true
        
        if let presetName = defaults.string(forKey: "currentPreset") {
            switch presetName {
            case "classic": currentPreset = .classic
            case "deepWork": currentPreset = .deepWork  
            case "sprint": currentPreset = .sprint
            default: currentPreset = .classic
            }
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(soundEnabled, forKey: "soundEnabled")
        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(autoStartBreaks, forKey: "autoStartBreaks")
        defaults.set(autoStartFocus, forKey: "autoStartFocus")
        
        let presetName: String
        switch currentPreset.name {
        case "25/5": presetName = "classic"
        case "50/10": presetName = "deepWork"
        case "15/3": presetName = "sprint"
        default: presetName = "classic"
        }
        defaults.set(presetName, forKey: "currentPreset")
    }
    
    private func loadStatistics() {
        let defaults = UserDefaults.standard
        completedCycles = defaults.integer(forKey: "completedCycles")
        todayFocusMinutes = defaults.integer(forKey: "todayFocusMinutes")
        weekFocusMinutes = defaults.integer(forKey: "weekFocusMinutes") 
        currentStreak = defaults.integer(forKey: "currentStreak")
    }
    
    private func saveStatistics() {
        let defaults = UserDefaults.standard
        defaults.set(completedCycles, forKey: "completedCycles")
        defaults.set(todayFocusMinutes, forKey: "todayFocusMinutes")
        defaults.set(weekFocusMinutes, forKey: "weekFocusMinutes")
        defaults.set(currentStreak, forKey: "currentStreak")
    }
    
    private func scheduleResetForTomorrow() {
        // Cancel existing reset timer
        dailyResetTimer?.invalidate()
        dailyResetTimer = nil

        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            print("Failed to calculate tomorrow's date")
            return
        }
        let startOfTomorrow = calendar.startOfDay(for: tomorrow)
        let timeInterval = startOfTomorrow.timeIntervalSinceNow

        dailyResetTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.resetForNewDay()
        }
    }
    
    @objc private func resetForNewDay() {
        timerState = .stopped
        // Archive today's stats, reset daily counters
        todayFocusMinutes = 0
        saveStatistics()
    }
}
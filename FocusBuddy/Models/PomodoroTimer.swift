import Foundation
import Combine
import UserNotifications
import SwiftUI
import OSLog

// MARK: - Timer State
enum TimerState: Equatable {
    case stopped
    case running
    case paused
    case stoppedForToday
}

// MARK: - Timer Phase
enum TimerPhase: String, CaseIterable {
    case focus
    case shortBreak
    case longBreak

    var emoji: String {
        switch self {
        case .focus: return "🎯"
        case .shortBreak: return "☕️"
        case .longBreak: return "🚶"
        }
    }

    var title: String {
        switch self {
        case .focus: return "Фокус"
        case .shortBreak: return "Короткий перерыв"
        case .longBreak: return "Длинный перерыв"
        }
    }
}

// MARK: - Timer Preset
struct TimerPreset: Codable, Equatable {
    let id = UUID()
    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let name: String

    static let `default` = TimerPreset(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        name: "Default"
    )

    static let short = TimerPreset(
        focusMinutes: 15,
        shortBreakMinutes: 3,
        longBreakMinutes: 10,
        name: "Short"
    )

    static let long = TimerPreset(
        focusMinutes: 50,
        shortBreakMinutes: 10,
        longBreakMinutes: 30,
        name: "Long"
    )
}

// MARK: - Daily Statistics
struct DayStatistics: Codable {
    let date: Date
    var focusMinutes: Int = 0
    var completedCycles: Int = 0
    var totalSessions: Int = 0
}

// MARK: - Focus Timer
@MainActor
class FocusTimer: ObservableObject {
    // Published properties
    @Published var timerState: TimerState = .stopped
    @Published var currentPhase: TimerPhase = .focus
    @Published var timeRemaining: Int = 25 * 60 // 25 minutes in seconds
    @Published var currentPreset: TimerPreset = .default
    @Published var todayStats = DayStatistics(date: Date())

    // Settings properties
    @Published var notificationsEnabled: Bool = true
    @Published var soundEnabled: Bool = true
    @Published var autoStartBreaks: Bool = true
    @Published var autoStartFocus: Bool = false

    // Debug properties
    @Published var debugOutput: String = "Debug log:\n"

    // Computed properties
    var completedCycles: Int {
        todayStats.completedCycles
    }

    var todayFocusMinutes: Int {
        todayStats.focusMinutes
    }

    // Private properties
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FocusBuddy", category: "Timer")

    init() {
        resetToCurrentPhase()
        setupNotifications()
    }

    // MARK: - Timer Control

    func startTimer() {
        guard timerState != .stoppedForToday else { return }

        timerState = .running
        logger.info("Timer started for \(self.currentPhase.rawValue)")

        startInternalTimer()
    }

    func pauseTimer() {
        guard timerState == .running else { return }

        timerState = .paused
        stopInternalTimer()
        logger.info("Timer paused")
    }

    func resumeTimer() {
        guard timerState == .paused else { return }

        timerState = .running
        startInternalTimer()
        logger.info("Timer resumed")
    }

    func stopTimer() {
        stopInternalTimer()
        timerState = .stopped
        resetToCurrentPhase()
        logger.info("Timer stopped")
    }

    func resetTimer() {
        stopTimer()
        logger.info("Timer reset")
    }

    func skipToBreak() {
        guard currentPhase == .focus else { return }
        stopInternalTimer()
        completeCurrentPhase()
    }

    func stopForToday() {
        stopInternalTimer()
        timerState = .stoppedForToday
        logger.info("Timer stopped for today")
    }

    // MARK: - Phase Management

    private func completeCurrentPhase() {
        logger.info("Completing phase: \(self.currentPhase.rawValue)")

        // Update statistics
        if currentPhase == .focus {
            todayStats.focusMinutes += currentPreset.focusMinutes
            todayStats.completedCycles += 1
            todayStats.totalSessions += 1
        }

        // Move to next phase
        moveToNextPhase()

        // Send notification
        scheduleCompletionNotification()

        // Auto-start next phase for breaks
        if currentPhase != .focus && timerState == .running && autoStartBreaks {
            startTimer()
        }
    }

    private func moveToNextPhase() {
        switch currentPhase {
        case .focus:
            // After 4 focus sessions, take long break
            currentPhase = (todayStats.completedCycles % 4 == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            currentPhase = .focus
        }

        resetToCurrentPhase()
        logger.info("Moved to phase: \(self.currentPhase.rawValue)")
    }

    private func resetToCurrentPhase() {
        switch currentPhase {
        case .focus:
            timeRemaining = currentPreset.focusMinutes * 60
        case .shortBreak:
            timeRemaining = currentPreset.shortBreakMinutes * 60
        case .longBreak:
            timeRemaining = currentPreset.longBreakMinutes * 60
        }
    }

    // MARK: - Internal Timer

    private func startInternalTimer() {
        stopInternalTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopInternalTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard timerState == .running else { return }

        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completeCurrentPhase()
        }
    }

    // MARK: - Notifications

    private func setupNotifications() {
        Task {
            do {
                try await requestNotificationPermissions()
            } catch {
                logger.error("Failed to setup notifications: \(error.localizedDescription)")
            }
        }
    }

    func requestNotificationPermissions() async throws {
        let center = UNUserNotificationCenter.current()
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    private func scheduleCompletionNotification() {
        let content = UNMutableNotificationContent()

        switch currentPhase {
        case .focus:
            content.title = "Focus Session Complete! 🎯"
            content.body = "Time for a break. Great work!"
        case .shortBreak:
            content.title = "Break Time Over ☕️"
            content.body = "Ready to focus again?"
        case .longBreak:
            content.title = "Long Break Complete 🚶"
            content.body = "Time to get back to work!"
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Debug Methods (for Settings)

    func debugNotificationPermissions() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            logger.info("Notification authorization: \(settings.authorizationStatus.rawValue)")
        }
    }

    func openNotificationSettings() {
        if let settingsUrl = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(settingsUrl)
        }
    }

    func testNotification() {
        scheduleCompletionNotification()
    }

    func testRealNotificationFlow() {
        // Quick test notification
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from Focus Buddy"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func debugCurrentTimerState() {
        logger.info("Current state: \(String(describing: self.timerState))")
        logger.info("Current phase: \(self.currentPhase.rawValue)")
        logger.info("Time remaining: \(self.timeRemaining)")
    }

    func startQuickTest() {
        currentPhase = .focus
        timeRemaining = 3 // 3 seconds for testing
        startTimer()
    }

    func debugPhaseCompletion(nextPhase: TimerPhase) {
        currentPhase = nextPhase
        completeCurrentPhase()
    }

    deinit {
        Task { @MainActor in
            self.stopInternalTimer()
        }
        cancellables.removeAll()
    }
}
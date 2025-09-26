import SwiftUI
import UserNotifications
import AppKit
import Combine
import OSLog

@main
struct FocusBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var focusTimer = FocusTimer()

    // Native menu bar title with emoji indicators
    private var menuBarTitle: String {
        switch focusTimer.timerState {
        case .running:
            let minutes = focusTimer.timeRemaining / 60
            let seconds = focusTimer.timeRemaining % 60
            let phaseEmoji = focusTimer.currentPhase.emoji
            return "\(phaseEmoji) \(String(format: "%d:%02d", minutes, seconds))"
        case .paused:
            return "⏸️ Focus Buddy"
        case .stoppedForToday:
            return "✅ Done Today"
        case .stopped:
            return "⏰ Focus Buddy"
        }
    }

    var body: some Scene {
        // Main application window with proper sizing
        WindowGroup("Focus Buddy") {
            ContentView()
                .environmentObject(focusTimer)
                .frame(minWidth: 400, maxWidth: 600, minHeight: 500, maxHeight: 800)
                .onAppear {
                    setupApplication()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentMinSize)
        .defaultPosition(.center)
        .commands {
            // Native macOS menu commands
            FocusBuddyCommands(focusTimer: focusTimer)
        }

        // Enhanced menu bar with native styling
        MenuBarExtra(menuBarTitle, systemImage: "timer") {
            MenuBarView()
                .environmentObject(focusTimer)
        }
        .menuBarExtraStyle(.menu)
    }
    
    private func setupApplication() {
        // Initialize native services and permissions
        Task {
            do {
                try await focusTimer.requestNotificationPermissions()
                Logger.app.info("✅ Application setup completed successfully")
            } catch {
                Logger.app.error("❌ Application setup failed: \(error.localizedDescription)")
            }
        }

        // Configure app for optimal user experience
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)

            // Set app to stay active in background for timer functionality
            if let window = NSApp.windows.first {
                window.level = .normal
                window.center()
            }
        }
    }
}

// MARK: - Native App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure native macOS behaviors
        UNUserNotificationCenter.current().delegate = self

        // Configure main window for native appearance
        configureMainWindow()

        // Register for system events
        registerForSystemEvents()

        Logger.app.info("🚀 FocusBuddy launched with native macOS integration")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running as menu bar app
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.app.info("🔄 FocusBuddy terminating gracefully")
    }

    // MARK: - Window Management

    private func configureMainWindow() {
        guard let window = NSApp.windows.first else { return }

        // Native macOS window styling
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isMovableByWindowBackground = false

        // Set size constraints
        window.minSize = NSSize(width: 400, height: 500)
        window.maxSize = NSSize(width: 600, height: 800)

        // Center and focus
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func registerForSystemEvents() {
        // Register for sleep/wake notifications
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter

        notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func systemWillSleep() {
        Logger.app.info("😴 System going to sleep - pausing timer if running")
        NotificationCenter.default.post(name: .systemWillSleep, object: nil)
    }

    @objc private func systemDidWake() {
        Logger.app.info("😊 System woke up - resuming app functionality")
        NotificationCenter.default.post(name: .systemDidWake, object: nil)
    }

    // MARK: - Notification Delegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Logger.app.info("📱 Presenting notification: \(notification.request.content.title)")
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Logger.app.info("👆 User interacted with notification: \(response.notification.request.content.title)")

        // Bring app to foreground when notification is tapped
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }

        completionHandler()
    }
}

// MARK: - Native Menu Commands
struct FocusBuddyCommands: Commands {
    let focusTimer: FocusTimer

    var body: some Commands {
        // Timer menu commands
        CommandMenu("Timer") {
            Button("Start/Pause Timer") {
                switch focusTimer.timerState {
                case .stopped:
                    focusTimer.startTimer()
                case .running:
                    focusTimer.pauseTimer()
                case .paused:
                    focusTimer.resumeTimer()
                case .stoppedForToday:
                    break
                }
            }
            .keyboardShortcut(.space)

            Button("Reset Timer") {
                focusTimer.resetTimer()
            }
            .keyboardShortcut("r", modifiers: .command)

            Divider()

            Button("Skip to Break") {
                if focusTimer.currentPhase == .focus {
                    focusTimer.skipToBreak()
                }
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
            .disabled(focusTimer.currentPhase != .focus)
        }

        // Replace default "Help" menu
        CommandGroup(replacing: .help) {
            Button("Focus Buddy Help") {
                // Open help documentation
                if let url = URL(string: "https://github.com/your-repo/focusbuddy") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// MARK: - System Notifications
extension Notification.Name {
    static let systemWillSleep = Notification.Name("systemWillSleep")
    static let systemDidWake = Notification.Name("systemDidWake")
}

// MARK: - Logging
extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FocusBuddy", category: "App")
}
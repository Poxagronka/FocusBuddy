import SwiftUI
import UserNotifications
import AppKit

@main
struct FocusBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var focusTimer = FocusTimer()

    private var menuBarTitle: String {
        if focusTimer.timerState == .running {
            let minutes = focusTimer.timeRemaining / 60
            let seconds = focusTimer.timeRemaining % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "Focus Buddy"
    }

    var body: some Scene {
        WindowGroup("Focus Buddy", id: "main") {
            ContentView()
                .environmentObject(focusTimer)
                .frame(width: 500, height: 700)
                .onAppear {
                    setupNotifications()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        MenuBarExtra(menuBarTitle, systemImage: "timer") {
            MenuBarView()
                .environmentObject(focusTimer)
        }
        .menuBarExtraStyle(.window)
    }
    
    private func setupNotifications() {
        // Only request if not already determined
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                ) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            print("✅ Notifications permission granted automatically")
                        } else if let error = error {
                            print("❌ Notification permission error: \(error)")
                        } else {
                            print("⚠️ Notifications permission denied by user")
                        }
                    }
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Hide dock icon for menu bar app experience
        // NSApp.setActivationPolicy(.accessory)
        
        // Configure window appearance
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
        }
        
        print("🚀 AppDelegate initialized with notification delegate")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running when window closed
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 Will present notification: \(notification.request.content.title)")
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 User tapped notification: \(response.notification.request.content.title)")
        completionHandler()
    }
}
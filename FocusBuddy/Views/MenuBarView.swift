import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var focusTimer: FocusTimer
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with current status
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(focusTimer.currentPhase.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(timerStateText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if focusTimer.timerState == .running {
                        Text(timeString)
                            .font(.title2)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .foregroundStyle(phaseColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                if focusTimer.timerState == .running {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(phaseColor)
                        .padding(.horizontal, 16)
                }
            }
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Quick controls
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    MenuBarButton(
                        title: primaryActionTitle,
                        color: phaseColor,
                        isDisabled: focusTimer.timerState == .stoppedForToday
                    ) {
                        performPrimaryAction()
                    }
                    
                    if focusTimer.timerState != .stopped && focusTimer.timerState != .stoppedForToday {
                        MenuBarButton(
                            title: "Stop",
                            color: .secondary
                        ) {
                            focusTimer.stopTimer()
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    MenuBarButton(
                        title: "Open App",
                        color: .blue
                    ) {
                        openWindow(id: "main")
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    
                    MenuBarButton(
                        title: "Stop Today",
                        color: .red
                    ) {
                        focusTimer.stopForToday()
                    }
                }
            }
            .padding(16)
            
            // Stats footer
            if focusTimer.completedCycles > 0 || focusTimer.todayFocusMinutes > 0 {
                Divider()
                
                HStack {
                    Label("\(focusTimer.completedCycles)", systemImage: "repeat")
                    
                    Spacer()
                    
                    Label("\(focusTimer.todayFocusMinutes) мин", systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 280)
    }
    
    // MARK: - Computed Properties
    
    private var timeString: String {
        let minutes = focusTimer.timeRemaining / 60
        let seconds = focusTimer.timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var progress: Double {
        let totalTime = Double(getCurrentPhaseSeconds())
        let elapsed = totalTime - Double(focusTimer.timeRemaining)
        return elapsed / totalTime
    }
    
    private var phaseColor: Color {
        switch focusTimer.currentPhase {
        case .focus: return .blue
        case .shortBreak: return .green
        case .longBreak: return .orange
        }
    }
    
    private var timerStateText: String {
        switch focusTimer.timerState {
        case .stopped: return "Готов к запуску"
        case .running: return "В процессе"
        case .paused: return "На паузе"
        case .stoppedForToday: return "Остановлено на сегодня"
        }
    }
    
    private var primaryActionTitle: String {
        switch focusTimer.timerState {
        case .stopped, .stoppedForToday: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }
    
    
    // MARK: - Actions
    
    private func performPrimaryAction() {
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
    
    private func getCurrentPhaseSeconds() -> Int {
        switch focusTimer.currentPhase {
        case .focus: return focusTimer.currentPreset.focusMinutes * 60
        case .shortBreak: return focusTimer.currentPreset.shortBreakMinutes * 60
        case .longBreak: return focusTimer.currentPreset.longBreakMinutes * 60
        }
    }
}

struct MenuBarButton: View {
    let title: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isDisabled ? Color.secondary.opacity(0.3) : color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isDisabled ? .clear : color.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .foregroundStyle(isDisabled ? Color.secondary : color)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(FocusTimer())
}
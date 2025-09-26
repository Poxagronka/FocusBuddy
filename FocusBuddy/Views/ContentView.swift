import SwiftUI
import Combine
import AppKit

// MARK: - Apple Design System
private enum DesignConstants {
    // Apple Semantic Colors
    static let backgroundColor = Color.clear // Respects system appearance
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let secondaryCardBackground = Color(NSColor.tertiarySystemFill)
    static let activeCardBorder = Color.accentColor
    static let timerColor = Color.primary
    static let textSecondary = Color.secondary
    static let surfaceBackground = Color(NSColor.windowBackgroundColor)

    // Phase Colors (Apple's semantic approach)
    static let focusColor = Color.blue
    static let shortBreakColor = Color.green
    static let longBreakColor = Color.purple

    // Apple Typography Scale
    static let timerFont = Font.system(.largeTitle, design: .monospaced, weight: .medium)
        .monospacedDigit()
    static let modeFont = Font.headline.weight(.medium)
    static let cardTitleFont = Font.subheadline.weight(.medium)
    static let cardSubtitleFont = Font.caption.weight(.regular)

    // Apple Standard Spacing (20pt system)
    static let standardSpacing: CGFloat = 20
    static let compactSpacing: CGFloat = 12
    static let expandedSpacing: CGFloat = 32

    // Apple Standard Sizes
    static let cardWidth: CGFloat = 140
    static let cardHeight: CGFloat = 100
    static let cornerRadius: CGFloat = 12
}

struct ContentView: View {
    @EnvironmentObject var focusTimer: FocusTimer
    @State private var showSettings = false
    @AppStorage("reducedMotion") private var reducedMotion = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Native macOS background
                DesignConstants.surfaceBackground
                    .ignoresSafeArea()

                // Main content with proper macOS layout
                VStack(spacing: DesignConstants.standardSpacing) {
                    // Timer section - main focus area
                    TimerDisplayView()
                        .environmentObject(focusTimer)
                        .padding(.top, DesignConstants.standardSpacing)

                    // Phase indicator cards
                    PhaseCardsView()
                        .environmentObject(focusTimer)

                    Spacer()

                    // Control section
                    VStack(spacing: DesignConstants.compactSpacing) {
                        // Primary control button
                        NativeControlButton()
                            .environmentObject(focusTimer)

                        // Progress indicator (replaces liquid animation)
                        if !reducedMotion {
                            NativeProgressView(progress: timerProgress)
                                .frame(height: 8)
                                .padding(.horizontal, DesignConstants.expandedSpacing)
                        }
                    }
                    .padding(.bottom, DesignConstants.standardSpacing)
                }
                .frame(maxWidth: 480) // Apple's preferred compact width
                .padding(.horizontal, DesignConstants.standardSpacing)
            }
        }
        .background(WindowAccessor())
        .onAppear {
            setupNativeAppearance()
            setupKeyboardShortcuts()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    // MARK: - Computed Properties

    private var timerProgress: Double {
        let totalTime = Double(getCurrentPhaseSeconds())
        guard totalTime > 0 else { return 0 }
        let elapsed = totalTime - Double(focusTimer.timeRemaining)
        return min(1.0, elapsed / totalTime)
    }

    private func getCurrentPhaseSeconds() -> Int {
        switch focusTimer.currentPhase {
        case .focus: return focusTimer.currentPreset.focusMinutes * 60
        case .shortBreak: return focusTimer.currentPreset.shortBreakMinutes * 60
        case .longBreak: return focusTimer.currentPreset.longBreakMinutes * 60
        }
    }

    private func setupNativeAppearance() {
        // Configure window appearance for native macOS look
        if let window = NSApp.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor.windowBackgroundColor
        }
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                showSettings.toggle()
                return nil
            }
            return event
        }
    }
}

// MARK: - Native Timer Display
struct TimerDisplayView: View {
    @EnvironmentObject var focusTimer: FocusTimer
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: DesignConstants.compactSpacing) {
            // Main timer display with Apple's monospaced design
            VStack(spacing: 8) {
                Text(timeString)
                    .font(DesignConstants.timerFont)
                    .foregroundColor(DesignConstants.timerColor)
                    .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                    .accessibilityLabel("Timer showing \(accessibleTimeDescription)")

                // Phase indicator with Apple styling
                HStack(spacing: 8) {
                    Image(systemName: focusTimer.currentPhase.systemImage)
                        .font(.body.weight(.medium))
                        .foregroundColor(currentPhaseColor)

                    Text(phaseName)
                        .font(DesignConstants.modeFont)
                        .foregroundColor(DesignConstants.textSecondary)
                }
            }
            .padding(.vertical, DesignConstants.compactSpacing)

            // Cycle progress with native styling
            GroupBox {
                HStack {
                    Text("Session")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(min(focusTimer.completedCycles + 1, 4))/4")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .groupBoxStyle(TransparentGroupBoxStyle())
        }
        .onAppear {
            if focusTimer.timerState == .running {
                pulseAnimation = true
            }
        }
        .onChange(of: focusTimer.timerState) { oldValue, newValue in
            switch newValue {
            case .running:
                pulseAnimation = true
            case .stopped, .paused, .stoppedForToday:
                pulseAnimation = false
            }
        }
    }

    private var timeString: String {
        let minutes = focusTimer.timeRemaining / 60
        let seconds = focusTimer.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var accessibleTimeDescription: String {
        let minutes = focusTimer.timeRemaining / 60
        let seconds = focusTimer.timeRemaining % 60
        return "\(minutes) minutes and \(seconds) seconds remaining"
    }

    private var phaseName: String {
        switch focusTimer.currentPhase {
        case .focus: return "Фокус"
        case .shortBreak: return "Короткий перерыв"
        case .longBreak: return "Длинный перерыв"
        }
    }

    private var currentPhaseColor: Color {
        switch focusTimer.currentPhase {
        case .focus: return DesignConstants.focusColor
        case .shortBreak: return DesignConstants.shortBreakColor
        case .longBreak: return DesignConstants.longBreakColor
        }
    }
}

// MARK: - Native Phase Cards
struct PhaseCardsView: View {
    @EnvironmentObject var focusTimer: FocusTimer

    var body: some View {
        HStack(spacing: DesignConstants.compactSpacing) {
            NativeModeCard(
                phase: .focus,
                icon: "brain.head.profile",
                title: "Фокус",
                duration: "\(focusTimer.currentPreset.focusMinutes) мин",
                isActive: focusTimer.currentPhase == .focus
            )

            NativeModeCard(
                phase: .shortBreak,
                icon: "cup.and.saucer.fill",
                title: "Короткий перерыв",
                duration: "\(focusTimer.currentPreset.shortBreakMinutes) мин",
                isActive: focusTimer.currentPhase == .shortBreak
            )

            NativeModeCard(
                phase: .longBreak,
                icon: "figure.walk",
                title: "Длинный перерыв",
                duration: "\(focusTimer.currentPreset.longBreakMinutes) мин",
                isActive: focusTimer.currentPhase == .longBreak
            )
        }
    }
}

struct NativeModeCard: View {
    let phase: TimerPhase
    let icon: String
    let title: String
    let duration: String
    let isActive: Bool

    var body: some View {
        GroupBox {
            VStack(spacing: DesignConstants.compactSpacing) {
                Image(systemName: icon)
                    .font(.title2.weight(.medium))
                    .foregroundColor(phaseColor)

                VStack(spacing: 4) {
                    Text(title)
                        .font(DesignConstants.cardTitleFont)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(duration)
                        .font(DesignConstants.cardSubtitleFont)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: DesignConstants.cardWidth, height: DesignConstants.cardHeight)
        }
        .groupBoxStyle(TransparentGroupBoxStyle())
        .overlay(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isActive ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .accessibilityLabel("\(title) phase, \(duration)")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private var phaseColor: Color {
        switch phase {
        case .focus: return DesignConstants.focusColor
        case .shortBreak: return DesignConstants.shortBreakColor
        case .longBreak: return DesignConstants.longBreakColor
        }
    }
}

// MARK: - Native Control Button
struct NativeControlButton: View {
    @EnvironmentObject var focusTimer: FocusTimer
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: DesignConstants.compactSpacing) {
            // Main action button
            Button(action: toggleTimer) {
                HStack(spacing: 8) {
                    Image(systemName: buttonIcon)
                        .font(.body.weight(.medium))
                    Text(buttonTitle)
                        .font(.body.weight(.medium))
                }
                .frame(minWidth: 140)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.space)
            .disabled(focusTimer.timerState == .stoppedForToday)
            .accessibilityLabel(buttonTitle)
            .accessibilityHint("Double tap to \(buttonTitle.lowercased())")

            // Reset button (secondary action)
            if focusTimer.timerState != .stopped {
                Button(action: resetTimer) {
                    Image(systemName: "stop.fill")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut("r", modifiers: .command)
                .accessibilityLabel("Reset timer")
            }
        }
    }

    private var buttonIcon: String {
        switch focusTimer.timerState {
        case .stopped, .stoppedForToday: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        }
    }

    private var buttonTitle: String {
        switch focusTimer.timerState {
        case .stopped, .stoppedForToday: return "Начать фокус"
        case .running: return "Пауза"
        case .paused: return "Продолжить"
        }
    }

    private func toggleTimer() {
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

    private func resetTimer() {
        focusTimer.stopTimer()
    }
}

// MARK: - Native Progress View
struct NativeProgressView: View {
    let progress: Double
    @EnvironmentObject var focusTimer: FocusTimer

    var body: some View {
        ProgressView(value: progress, total: 1.0)
            .progressViewStyle(LinearProgressViewStyle(tint: currentPhaseColor))
            .scaleEffect(y: 2.0, anchor: .center)
            .animation(.easeInOut(duration: 0.3), value: progress)
    }

    private var currentPhaseColor: Color {
        switch focusTimer.currentPhase {
        case .focus: return DesignConstants.focusColor
        case .shortBreak: return DesignConstants.shortBreakColor
        case .longBreak: return DesignConstants.longBreakColor
        }
    }
}

// MARK: - Window Accessor for Native Window Management
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                // Configure native window behavior
                window.styleMask.insert([.titled, .closable, .miniaturizable, .resizable])
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.isMovableByWindowBackground = true

                // Set window size constraints
                window.minSize = NSSize(width: 400, height: 500)
                window.maxSize = NSSize(width: 600, height: 800)

                // Center window
                window.center()
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Transparent Group Box Style
struct TransparentGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
            configuration.content
        }
        .padding(DesignConstants.compactSpacing)
        .background(DesignConstants.cardBackground, in: RoundedRectangle(cornerRadius: DesignConstants.cornerRadius))
    }
}

// MARK: - Timer Phase Extension for Native Integration
extension TimerPhase {
    var systemImage: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "figure.walk"
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(FocusTimer())
        .frame(width: 480, height: 600)
}
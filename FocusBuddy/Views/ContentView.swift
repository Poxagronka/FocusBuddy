import SwiftUI
import Combine
import AppKit

// MARK: - Design Constants
private enum DesignConstants {
    // Colors
    static let backgroundColor = Color(hex: "2B2D3A")
    static let cardBackground = Color(hex: "3A3D4A")
    static let activeCardBorder = Color(hex: "0A84FF")
    static let timerColor = Color.white
    static let textSecondary = Color.white.opacity(0.7)

    // Typography
    static let timerFont = Font.system(size: 130, weight: .bold, design: .default)
    static let modeFont = Font.system(size: 16, weight: .semibold)
    static let cardTitleFont = Font.system(size: 14, weight: .semibold)
    static let cardSubtitleFont = Font.system(size: 12, weight: .regular)

    // Spacing
    static let cardSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 32
    static let cardPadding: CGFloat = 20

    // Sizes
    static let cardWidth: CGFloat = 150
    static let cardHeight: CGFloat = 80
    static let liquidHeight: CGFloat = 120
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @EnvironmentObject var focusTimer: FocusTimer
    @State private var showDebugPanel = false
    @State private var debugSettings = DebugSettings()

    var body: some View {
        ZStack {
            // Background
            DesignConstants.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: DesignConstants.sectionSpacing) {
                // Main content
                VStack(spacing: DesignConstants.sectionSpacing) {
                    // Timer section
                    MinimalTimerView()
                        .environmentObject(focusTimer)

                    // Mode cards
                    ModeCardsView()
                        .environmentObject(focusTimer)

                    // Control button
                    MinimalControlButton()
                        .environmentObject(focusTimer)
                }
                .padding(.horizontal, 32)
                .padding(.top, 40)

                Spacer()
            }

            // Liquid animation at bottom
            VStack {
                Spacer()
                LiquidAnimationView(
                    progress: timerProgress,
                    phaseColor: currentPhaseColor,
                    settings: debugSettings
                )
                .frame(height: DesignConstants.liquidHeight)
                .ignoresSafeArea(.all, edges: .bottom)
            }

            // Debug panel overlay
            if showDebugPanel {
                DebugPanel(settings: $debugSettings) {
                    showDebugPanel = false
                }
            }
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }

    // MARK: - Computed Properties

    private var timerProgress: Double {
        let totalTime = Double(getCurrentPhaseSeconds())
        guard totalTime > 0 else { return 0 }
        let elapsed = totalTime - Double(focusTimer.timeRemaining)
        return elapsed / totalTime
    }

    private var currentPhaseColor: Color {
        switch focusTimer.currentPhase {
        case .focus: return Color(hex: "0A84FF") // Blue
        case .shortBreak: return Color(hex: "30D158") // Green
        case .longBreak: return Color(hex: "BF5AF2") // Purple
        }
    }

    private func getCurrentPhaseSeconds() -> Int {
        switch focusTimer.currentPhase {
        case .focus: return focusTimer.currentPreset.focusMinutes * 60
        case .shortBreak: return focusTimer.currentPreset.shortBreakMinutes * 60
        case .longBreak: return focusTimer.currentPreset.longBreakMinutes * 60
        }
    }

    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "d" {
                showDebugPanel.toggle()
                return nil
            }
            return event
        }
    }
}

// MARK: - Minimal Timer View
struct MinimalTimerView: View {
    @EnvironmentObject var focusTimer: FocusTimer

    var body: some View {
        VStack(spacing: 16) {
            // Huge timer
            Text(timeString)
                .font(DesignConstants.timerFont)
                .foregroundColor(DesignConstants.timerColor)
                .fontDesign(.monospaced)

            // Mode and cycle counter
            HStack(spacing: 24) {
                // Current mode
                HStack(spacing: 8) {
                    Text(focusTimer.currentPhase.emoji)
                        .font(.system(size: 16))

                    Text(phaseName.uppercased())
                        .font(DesignConstants.modeFont)
                        .foregroundColor(DesignConstants.textSecondary)
                        .tracking(1)
                }

                // Cycle counter
                Text("\(focusTimer.completedCycles)/4")
                    .font(DesignConstants.modeFont)
                    .foregroundColor(DesignConstants.textSecondary)
                    .fontDesign(.monospaced)
            }
        }
    }

    private var timeString: String {
        let minutes = focusTimer.timeRemaining / 60
        let seconds = focusTimer.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var phaseName: String {
        switch focusTimer.currentPhase {
        case .focus: return "Фокус"
        case .shortBreak: return "Короткий перерыв"
        case .longBreak: return "Длинный перерыв"
        }
    }
}

// MARK: - Mode Cards View
struct ModeCardsView: View {
    @EnvironmentObject var focusTimer: FocusTimer

    var body: some View {
        HStack(spacing: DesignConstants.cardSpacing) {
            ModeCard(
                icon: "timer",
                iconColor: Color(hex: "FF3B30"),
                title: "Фокус",
                duration: "\(focusTimer.currentPreset.focusMinutes) мин",
                isActive: focusTimer.currentPhase == .focus,
                action: { /* Focus mode is default */ }
            )

            ModeCard(
                icon: "cup.and.saucer.fill",
                iconColor: Color(hex: "32D74B"),
                title: "Короткий\nперерыв",
                duration: "\(focusTimer.currentPreset.shortBreakMinutes) мин",
                isActive: focusTimer.currentPhase == .shortBreak,
                action: { /* Will switch automatically */ }
            )

            ModeCard(
                icon: "figure.walk",
                iconColor: Color(hex: "BF5AF2"),
                title: "Длинный\nперерыв",
                duration: "\(focusTimer.currentPreset.longBreakMinutes) мин",
                isActive: focusTimer.currentPhase == .longBreak,
                action: { /* Will switch automatically */ }
            )
        }
    }
}

struct ModeCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let duration: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)

                VStack(spacing: 4) {
                    Text(title)
                        .font(DesignConstants.cardTitleFont)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(duration)
                        .font(DesignConstants.cardSubtitleFont)
                        .foregroundColor(DesignConstants.textSecondary)
                }
            }
            .frame(width: DesignConstants.cardWidth, height: DesignConstants.cardHeight)
            .background(DesignConstants.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? DesignConstants.activeCardBorder : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isActive ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Minimal Control Button
struct MinimalControlButton: View {
    @EnvironmentObject var focusTimer: FocusTimer

    var body: some View {
        Button(action: toggleTimer) {
            HStack(spacing: 12) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 20, weight: .medium))

                Text(buttonTitle)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(currentPhaseColor)
            .cornerRadius(12)
            .shadow(color: currentPhaseColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    @State private var isPressed = false

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

    private var currentPhaseColor: Color {
        switch focusTimer.currentPhase {
        case .focus: return Color(hex: "0A84FF")
        case .shortBreak: return Color(hex: "30D158")
        case .longBreak: return Color(hex: "BF5AF2")
        }
    }

    private func toggleTimer() {
        isPressed = true

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }
    }
}

// MARK: - Debug Settings
struct DebugSettings {
    var animationSpeed: Double = 1.0
    var waveAmplitude: Double = 1.0
    var waveCount: Double = 3.0
    var opacity: Double = 0.4
}

// MARK: - Debug Panel
struct DebugPanel: View {
    @Binding var settings: DebugSettings
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Debug Panel")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button("✕", action: onClose)
                    .foregroundColor(.white)
                    .font(.title2)
            }

            VStack(spacing: 16) {
                DebugSlider(title: "Animation Speed", value: $settings.animationSpeed, range: 0.1...3.0)
                DebugSlider(title: "Wave Amplitude", value: $settings.waveAmplitude, range: 0.1...2.0)
                DebugSlider(title: "Wave Count", value: $settings.waveCount, range: 1...5)
                DebugSlider(title: "Opacity", value: $settings.opacity, range: 0.1...1.0)
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .padding(40)
    }
}

struct DebugSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%.2f", value))
                    .foregroundColor(.white.opacity(0.7))
                    .fontDesign(.monospaced)
            }

            Slider(value: $value, in: range)
                .accentColor(.blue)
        }
    }
}

// MARK: - Liquid Animation View
struct LiquidAnimationView: View {
    let progress: Double
    let phaseColor: Color
    let settings: DebugSettings

    @State private var waveOffset: CGFloat = 0
    @State private var waveOffset2: CGFloat = 0
    @State private var waveOffset3: CGFloat = 0
    @State private var bubbles: [FluidBubble] = []
    @State private var animationTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background for liquid area
                phaseColor.opacity(settings.opacity * 0.2)

                // Main liquid layers
                fluidLayers(geometry: geometry)

                // Bubbles
                bubblesView

                // Surface highlight
                surfaceHighlight(geometry: geometry)
            }
            .clipped()
            .onAppear {
                startFluidSimulation(geometry: geometry)
            }
            .onDisappear {
                stopFluidSimulation()
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                if oldValue != newValue {
                    updateBubbles(for: newValue)
                }
            }
        }
        .drawingGroup()
    }

    private func fluidLayers(geometry: GeometryProxy) -> some View {
        ZStack {
            // Main fluid body
            LiquidShape(
                progress: min(1.0, progress + 0.2),
                waveOffset: waveOffset,
                waveOffset2: waveOffset2,
                waveOffset3: waveOffset3,
                amplitude: CGFloat(settings.waveAmplitude)
            )
            .fill(mainGradient)
            .blur(radius: 0.5)

            // Secondary layer for depth
            LiquidShape(
                progress: min(1.0, progress + 0.15),
                waveOffset: waveOffset * 0.8,
                waveOffset2: waveOffset2 * 1.2,
                waveOffset3: waveOffset3 * 0.9,
                amplitude: CGFloat(settings.waveAmplitude)
            )
            .fill(secondaryGradient)
            .blur(radius: 1)
        }
    }

    private var mainGradient: RadialGradient {
        RadialGradient(
            colors: [
                phaseColor.opacity(settings.opacity * 0.95),
                phaseColor.opacity(settings.opacity * 0.85),
                phaseColor.opacity(settings.opacity * 0.70),
                phaseColor.opacity(settings.opacity * 0.80)
            ],
            center: UnitPoint(x: 0.4, y: 0.2),
            startRadius: 20,
            endRadius: 200
        )
    }

    private var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                phaseColor.opacity(settings.opacity * 0.6),
                phaseColor.opacity(settings.opacity * 0.4),
                phaseColor.opacity(settings.opacity * 0.35)
            ],
            startPoint: UnitPoint(x: 0.2, y: 0.1),
            endPoint: UnitPoint(x: 0.9, y: 0.8)
        )
    }

    @ViewBuilder
    private var bubblesView: some View {
        if progress > 0.05 {
            ForEach(bubbles.indices, id: \.self) { index in
                if bubbles[index].isVisible {
                    bubbleView(for: bubbles[index])
                }
            }
        }
    }

    private func bubbleView(for bubble: FluidBubble) -> some View {
        Circle()
            .fill(bubbleGradient)
            .frame(width: bubble.size, height: bubble.size)
            .position(bubble.position)
            .opacity(bubble.opacity * settings.opacity)
            .scaleEffect(bubble.scale)
            .blur(radius: bubble.size / 25)
    }

    private var bubbleGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color.white.opacity(0.8),
                Color.white.opacity(0.4),
                Color.clear
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: 8
        )
    }

    private func surfaceHighlight(geometry: GeometryProxy) -> some View {
        Group {
            if progress > 0.1 {
                LiquidSurfaceHighlight(
                    progress: min(1.0, progress + 0.2),
                    waveOffset: waveOffset,
                    amplitude: CGFloat(settings.waveAmplitude)
                )
                .fill(highlightGradient)
                .blur(radius: 1)
            }
        }
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.3),
                Color.white.opacity(0.1),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func startFluidSimulation(geometry: GeometryProxy) {
        let baseSpeed = 1.0 / settings.animationSpeed

        withAnimation(.linear(duration: 15 * baseSpeed).repeatForever(autoreverses: false)) {
            waveOffset = geometry.size.width * 2
        }

        withAnimation(.linear(duration: 20 * baseSpeed).repeatForever(autoreverses: false)) {
            waveOffset2 = -geometry.size.width * 1.5
        }

        withAnimation(.linear(duration: 12 * baseSpeed).repeatForever(autoreverses: false)) {
            waveOffset3 = geometry.size.width * 1.8
        }

        if progress > 0.05 {
            updateBubbles(for: geometry.size)
            startBubbleAnimation()
        }
    }

    private func updateBubbles(for size: CGSize) {
        let bubbleCount = Int(settings.waveCount * 3)
        bubbles = (0..<bubbleCount).map { _ in
            FluidBubble(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: size.height + CGFloat.random(in: 0...100)
                ),
                size: CGFloat.random(in: 3...12),
                velocity: CGFloat.random(in: 0.3...1.0) * CGFloat(settings.animationSpeed),
                opacity: Double.random(in: 0.3...0.6),
                scale: CGFloat.random(in: 0.8...1.2),
                isVisible: progress > 0.05,
                bounds: size
            )
        }
    }

    private func startBubbleAnimation() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016 / settings.animationSpeed, repeats: true) { timer in
            guard progress > 0.05 else {
                timer.invalidate()
                animationTimer = nil
                return
            }

            for index in bubbles.indices {
                bubbles[index].update(progress: progress)
            }
        }
    }

    private func stopFluidSimulation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

struct LiquidShape: Shape {
    let progress: Double
    let waveOffset: CGFloat
    let waveOffset2: CGFloat
    let waveOffset3: CGFloat
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let fluidHeight = rect.height * progress
        let surfaceY = rect.height - fluidHeight

        if progress <= 0 {
            return path
        }

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: surfaceY))

        createWaveSurface(path: &path, rect: rect, surfaceY: surfaceY)

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }

    private func createWaveSurface(path: inout Path, rect: CGRect, surfaceY: CGFloat) {
        let segments = 100
        let segmentWidth = rect.width / CGFloat(segments)

        for i in 0...segments {
            let x = CGFloat(i) * segmentWidth

            let wave1 = sin((x + waveOffset) / 80) * amplitude * 6
            let wave2 = sin((x + waveOffset2) / 60) * amplitude * 4
            let wave3 = sin((x + waveOffset3) / 120) * amplitude * 2

            let y = surfaceY + wave1 + wave2 + wave3

            if i == 0 {
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                let prevX = CGFloat(i - 1) * segmentWidth
                let prevWave1 = sin((prevX + waveOffset) / 80) * amplitude * 6
                let prevWave2 = sin((prevX + waveOffset2) / 60) * amplitude * 4
                let prevWave3 = sin((prevX + waveOffset3) / 120) * amplitude * 2
                let prevY = surfaceY + prevWave1 + prevWave2 + prevWave3

                let controlX1 = prevX + segmentWidth * 0.33
                let controlY1 = prevY
                let controlX2 = x - segmentWidth * 0.33
                let controlY2 = y

                path.addCurve(
                    to: CGPoint(x: x, y: y),
                    control1: CGPoint(x: controlX1, y: controlY1),
                    control2: CGPoint(x: controlX2, y: controlY2)
                )
            }
        }
    }
}

struct LiquidSurfaceHighlight: Shape {
    let progress: Double
    let waveOffset: CGFloat
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let fluidHeight = rect.height * progress
        let surfaceY = rect.height - fluidHeight
        let highlightHeight: CGFloat = 4

        if progress <= 0.1 {
            return path
        }

        let segments = 60
        let segmentWidth = rect.width / CGFloat(segments)

        for i in 0...segments {
            let x = CGFloat(i) * segmentWidth
            let wave = sin((x + waveOffset) / 80) * amplitude * 4
            let y = surfaceY + wave

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        for i in (0...segments).reversed() {
            let x = CGFloat(i) * segmentWidth
            let wave = sin((x + waveOffset) / 80) * amplitude * 4
            let y = surfaceY + wave - highlightHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }
}

struct FluidBubble {
    var position: CGPoint
    let size: CGFloat
    let velocity: CGFloat
    var opacity: Double
    var scale: CGFloat
    var isVisible: Bool
    private var lifeTime: Double
    private var bounds: CGSize
    private var horizontalDrift: CGFloat

    init(position: CGPoint, size: CGFloat, velocity: CGFloat, opacity: Double, scale: CGFloat, isVisible: Bool, bounds: CGSize) {
        self.position = position
        self.size = size
        self.velocity = velocity
        self.opacity = opacity
        self.scale = scale
        self.isVisible = isVisible
        self.lifeTime = 0
        self.bounds = bounds
        self.horizontalDrift = CGFloat.random(in: -0.5...0.5)
    }

    mutating func update(progress: Double) {
        guard isVisible && progress > 0.05 else {
            isVisible = false
            return
        }

        position.y -= velocity * (1 + lifeTime * 0.05)
        position.x += sin(lifeTime * 1.5) * 0.3 + horizontalDrift * 0.1

        scale = min(1.5, scale + 0.001)
        lifeTime += 0.016
        opacity = max(0, opacity - 0.0008)

        if position.y < -60 || opacity <= 0 || position.x < -30 || position.x > bounds.width + 30 {
            position.y = bounds.height + CGFloat.random(in: 0...120)
            position.x = CGFloat.random(in: 0...bounds.width)
            opacity = Double.random(in: 0.3...0.6)
            scale = CGFloat.random(in: 0.8...1.2)
            lifeTime = 0
            horizontalDrift = CGFloat.random(in: -0.5...0.5)
        }

        isVisible = progress > 0.05
    }
}

#Preview {
    ContentView()
        .environmentObject(FocusTimer())
        .frame(width: 500, height: 700)
}
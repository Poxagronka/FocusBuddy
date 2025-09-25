import SwiftUI

struct DebugView: View {
    @EnvironmentObject var focusTimer: FocusTimer
    @State private var debugOutput: String = ""
    @State private var showConsole = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🐛")
                            .font(.system(size: 32))

                        Text("Отладка")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Инструменты для тестирования и диагностики")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        // Notification Tests
                        DebugSection(title: "🔔 Тесты уведомлений") {
                            VStack(spacing: 12) {
                                DebugButton(
                                    title: "🔐 Запросить разрешения",
                                    subtitle: "Запросить разрешения на уведомления",
                                    color: .purple,
                                    action: { focusTimer.requestNotificationPermissions() }
                                )

                                DebugButton(
                                    title: "🔔 Проверить разрешения",
                                    subtitle: "Показать текущий статус разрешений",
                                    color: .orange,
                                    action: { focusTimer.debugNotificationPermissions() }
                                )

                                DebugButton(
                                    title: "🧪 Тестовое уведомление",
                                    subtitle: "Отправить пробное уведомление",
                                    color: .blue,
                                    action: { focusTimer.testNotification() }
                                )

                                DebugButton(
                                    title: "🧪 Тест уведомления",
                                    subtitle: "Проверить уведомления",
                                    color: .green,
                                    action: { focusTimer.testNotification() }
                                )
                            }
                        }

                        // Timer Tests
                        DebugSection(title: "⏰ Тесты таймера") {
                            VStack(spacing: 12) {
                                DebugButton(
                                    title: "⚡ Быстрый тест (10 сек)",
                                    subtitle: "Запуск 10-секундного таймера",
                                    color: .red,
                                    action: { focusTimer.startQuickTest() }
                                )

                                DebugButton(
                                    title: "🧪 Симуляция завершения",
                                    subtitle: "Тест уведомления о завершении фазы",
                                    color: .indigo,
                                    action: { focusTimer.testRealNotificationFlow() }
                                )

                                DebugButton(
                                    title: "📊 Статус таймера",
                                    subtitle: "Показать текущее состояние",
                                    color: .teal,
                                    action: { focusTimer.debugCurrentTimerState() }
                                )
                            }
                        }

                        // System Tools
                        DebugSection(title: "🔧 Системные инструменты") {
                            VStack(spacing: 12) {
                                DebugButton(
                                    title: "🔧 Системные настройки",
                                    subtitle: "Открыть настройки уведомлений",
                                    color: .cyan,
                                    action: { focusTimer.openNotificationSettings() }
                                )

                                DebugButton(
                                    title: "🔬 Полный тест",
                                    subtitle: "Протестировать все уведомления",
                                    color: .pink,
                                    action: { focusTimer.testRealNotificationFlow() }
                                )
                            }
                        }

                        // Debug Console
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("📝 Консоль отладки")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Button(showConsole ? "Скрыть" : "Показать") {
                                    showConsole.toggle()
                                }
                                .buttonStyle(.bordered)
                            }

                            if showConsole {
                                ScrollView {
                                    Text(focusTimer.debugOutput.isEmpty ? "Логи будут отображаться здесь..." : focusTimer.debugOutput)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.black.opacity(0.8))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                }
                                .frame(height: 200)
                                .onChange(of: focusTimer.debugOutput) { _, _ in
                                    // Auto-scroll to bottom when new content is added
                                }
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Отладка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 700)
    }
}

struct DebugSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DebugButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(color)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DebugView()
        .environmentObject(FocusTimer())
}
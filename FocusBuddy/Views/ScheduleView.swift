import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var focusTimer: FocusTimer
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("📅")
                        .font(.system(size: 28))
                    
                    Text("Расписание")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Настройка автоматических режимов и расписания")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    // Auto-start Settings
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚡ Автоматический запуск")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Автоматически переходить между фазами")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Автозапуск перерывов")
                                        .font(.subheadline)
                                    Text("Перерыв запустится автоматически после фокус-сессии")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $focusTimer.autoStartBreaks)
                                    .toggleStyle(.switch)
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Автозапуск фокуса")
                                        .font(.subheadline)
                                    Text("Фокус-сессия запустится автоматически после перерыва")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $focusTimer.autoStartFocus)
                                    .toggleStyle(.switch)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Weekly Schedule Preview
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("📊 Еженедельное расписание")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Планируйте продуктивные дни")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        WeeklySchedulePreview()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 20)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct WeeklySchedulePreview: View {
    let days = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 6) {
                        Text(day)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 2) {
                            ForEach(0..<8) { hour in
                                Rectangle()
                                    .fill(scheduleColor(for: day, hour: hour))
                                    .frame(height: 3)
                                    .cornerRadius(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            HStack(spacing: 16) {
                Label {
                    Text("Фокус")
                        .font(.caption2)
                } icon: {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }
                
                Label {
                    Text("Перерыв")
                        .font(.caption2)
                } icon: {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
                
                Label {
                    Text("Свободно")
                        .font(.caption2)
                } icon: {
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func scheduleColor(for day: String, hour: Int) -> Color {
        // Mock data for preview
        if ["Сб", "Вс"].contains(day) {
            return Color.secondary.opacity(0.3)
        }
        
        switch hour {
        case 0, 1, 6, 7: return Color.secondary.opacity(0.3)
        case 2, 4: return .green.opacity(0.6)
        default: return .blue.opacity(0.8)
        }
    }
}

#Preview {
    ScheduleView()
        .environmentObject(FocusTimer())
        .frame(width: 380, height: 600)
}
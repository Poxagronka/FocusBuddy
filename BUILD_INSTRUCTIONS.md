# Focus Buddy - Инструкции по сборке 🍅

## 🚀 Сборка в Xcode (Рекомендуется)

### 1. Открыть проект
```bash
open FocusBuddy.xcodeproj
```

### 2. Настроить подпись
1. Выберите проект **FocusBuddy** в Navigator
2. Выберите Target **FocusBuddy**
3. Во вкладке **Signing & Capabilities**:
   - Code Signing Identity: **Sign to Run Locally**
   - Team: **None** (или ваш Apple ID)
   - Bundle Identifier: **com.focusbuddy.app** (или ваш уникальный)

### 3. Собрать приложение
1. **Scheme**: FocusBuddy
2. **Destination**: My Mac (Designed for Mac)
3. **Product** → **Archive** (для релиза)
   - Или **⌘+B** для обычной сборки
   - Или **⌘+R** для запуска

### 4. Экспортировать .app
После **Archive**:
1. **Distribute App**
2. **Copy App** 
3. Выберите папку для сохранения
4. **Export**

## 📦 Создание DMG

После экспорта .app:
```bash
# Создать DMG installer
hdiutil create -volname "Focus Buddy" -srcfolder "Focus Buddy.app" -ov -format UDZO "Focus Buddy.dmg"
```

## ⚙️ Настройка Xcode Command Line Tools

Если нужно собирать из терминала:
```bash
# Установить правильный путь к Xcode
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Проверить
xcode-select --print-path
# Должно показать: /Applications/Xcode.app/Contents/Developer

# Теперь можно собирать из терминала
xcodebuild -project FocusBuddy.xcodeproj -scheme FocusBuddy -configuration Release build
```

## 🎯 Готовые результаты

После успешной сборки получите:
- **Focus Buddy.app** - готовое приложение
- **Focus Buddy.dmg** - установщик для распространения

## 🏗 Структура проекта

```
FocusBuddy.xcodeproj/
├── FocusBuddy/
│   ├── FocusBuddyApp.swift     # Главная точка входа
│   ├── Models/
│   │   └── PomodoroTimer.swift # Логика таймера
│   ├── Views/
│   │   ├── ContentView.swift   # Главное окно
│   │   ├── TimerView.swift     # Интерфейс таймера
│   │   ├── ScheduleView.swift  # Настройки расписания
│   │   ├── HistoryView.swift   # История и статистика
│   │   ├── SettingsView.swift  # Настройки
│   │   └── MenuBarView.swift   # Menu Bar widget
│   ├── Assets.xcassets/        # Иконки и ресурсы
│   └── FocusBuddy.entitlements # Разрешения
└── README-Swift.md             # Документация
```

## ✨ Особенности сборки

### Оптимизация Release:
- **Swift Optimization**: -O (Speed)
- **Code Generation**: Whole Module Optimization
- **Strip Debug Symbols**: Yes
- **Dead Code Stripping**: Yes

### Поддерживаемые платформы:
- **macOS**: 14.0+
- **Архитектуры**: x86_64, arm64 (Universal)

### Размер приложения:
- **Debug**: ~5MB
- **Release**: ~2-3MB
- **DMG**: ~2.5MB

## 🔧 Устранение проблем

### Проблема с подписью:
```
Code signing "Focus Buddy" failed
```
**Решение**: Выберите "Sign to Run Locally" в настройках проекта

### Проблема с Xcode Command Line Tools:
```
xcodebuild: error: The project does not contain a scheme
```
**Решение**: Используйте GUI Xcode для первой сборки

### Проблема с разрешениями:
```
App Transport Security has blocked a cleartext HTTP connection
```
**Решение**: Проверьте entitlements файл

## 🎉 Результат

После сборки получите профессиональное macOS приложение:
- ✅ Нативный SwiftUI интерфейс
- ✅ Menu Bar интеграция
- ✅ Системные уведомления
- ✅ Современный дизайн
- ✅ Высокая производительность

**Готово к распространению!** 🚀
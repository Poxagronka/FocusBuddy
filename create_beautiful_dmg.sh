#!/bin/bash

# Создание красивого DMG для Focus Buddy
APP_NAME="Focus Buddy"
DMG_NAME="Focus Buddy - Установка"
VOLUME_NAME="Focus Buddy 🐱"
SOURCE_APP="Focus Buddy.app"
SIZE="50m"

# Очистка предыдущих версий
rm -rf "${DMG_NAME}.dmg"
rm -rf dmg_temp

echo "🐱 Создание красивого DMG для Focus Buddy..."

# 1. Создаем временную папку
mkdir -p dmg_temp
cp -R "${SOURCE_APP}" dmg_temp/

# 2. Создаем ссылку на Applications
ln -s /Applications dmg_temp/Applications

# 3. Копируем инструкцию
cp "ИНСТРУКЦИЯ ПО УСТАНОВКЕ.txt" dmg_temp/

# 4. Создаем временный DMG
hdiutil create -srcfolder dmg_temp -volname "${VOLUME_NAME}" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${SIZE} temp.dmg

# 5. Подключаем DMG для настройки
device=$(hdiutil attach -readwrite -noverify -noautoopen "temp.dmg" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')

# 6. Настраиваем отображение (через AppleScript)
cat > setup_dmg.applescript << 'EOF'
tell application "Finder"
    tell disk "Focus Buddy 🐱"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:background.png"
        
        -- Позиционируем элементы
        set position of item "Focus Buddy.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        set position of item "ИНСТРУКЦИЯ ПО УСТАНОВКЕ.txt" of container window to {300, 350}
        
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# 7. Выполняем AppleScript (если возможно)
# osascript setup_dmg.applescript 2>/dev/null || echo "Пропускаем настройку UI (AppleScript недоступен)"

# 8. Отключаем временный DMG
hdiutil detach ${device}

# 9. Конвертируем в финальный DMG
hdiutil convert "temp.dmg" -format UDZO -imagekey zlib-level=9 -o "${DMG_NAME}.dmg"

# 10. Очистка
rm -rf dmg_temp temp.dmg setup_dmg.applescript

echo "✅ Готово! Создан файл: ${DMG_NAME}.dmg"
echo "📏 Размер: $(ls -lh "${DMG_NAME}.dmg" | awk '{print $5}')"
echo "🔍 Проверка целостности..."
hdiutil verify "${DMG_NAME}.dmg" | tail -1
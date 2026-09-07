#!/usr/bin/env bash
set -e

echo "🚀 [Lexio Native Build] Đang đóng gói Native macOS App & DMG Installer..."

APP_NAME="Lexio"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
DMG_NAME="Lexio-Installer-macOS.dmg"

# 1. Đảm bảo frontend đã build
echo "📦 1. Đóng gói giao diện Web (Vite + React)..."
npm run build

# 2. Tạo cấu trúc thư mục .app của macOS
echo "📁 2. Khởi tạo cấu trúc bundle ${BUNDLE_DIR}..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}/dist"

# 3. Copy bản build frontend vào Resources
cp -R dist/* "${RESOURCES_DIR}/dist/"

# 4. Copy Icon vào Resources nếu có
if [ -f "native-macos/AppIcon.icns" ]; then
    echo "🎨 3. Áp dụng App Icon chuẩn macOS continuous corner (native-macos/AppIcon.icns)..."
    cp "native-macos/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
elif [ -f "AppIcon.icns" ]; then
    echo "🎨 3. Áp dụng App Icon chuẩn macOS continuous corner (AppIcon.icns)..."
    cp "AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# 5. Tạo file Info.plist chuẩn macOS
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Lexio</string>
    <key>CFBundleDisplayName</key>
    <string>Lexio PRO</string>
    <key>CFBundleIdentifier</key>
    <string>com.tulietech.lexiopro</string>
    <key>CFBundleVersion</key>
    <string>2026.1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleExecutable</key>
    <string>Lexio</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# 6. Biên dịch mã nguồn Swift thành Native Mach-O Executable
echo "⚡ 4. Biên dịch Native Swift App (Apple Silicon / arm64)..."
swiftc native-macos/main.swift \
    -O \
    -target arm64-apple-macos11.0 \
    -framework Cocoa \
    -framework WebKit \
    -o "${MACOS_DIR}/Lexio"

chmod +x "${MACOS_DIR}/Lexio"

# 7. Đóng gói DMG Installer để cài sang máy khác
echo "💿 5. Đóng gói file cài đặt DMG (${DMG_NAME})..."
DMG_STAGING="dmg_staging"
rm -rf "${DMG_STAGING}" "${DMG_NAME}"
mkdir -p "${DMG_STAGING}"
cp -R "${BUNDLE_DIR}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

hdiutil create \
    -volname "Lexio Installer" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

rm -rf "${DMG_STAGING}"

echo "✅ [Hoàn Tất Thành Công!]"
echo "   • Native App: ${BUNDLE_DIR}"
echo "   • File cài đặt DMG cho máy khác: ${DMG_NAME}"
echo "   • Chạy app ngay: open ${BUNDLE_DIR}"

#!/usr/bin/env bash
set -e

echo "🚀 [Lexio Pure Native macOS Build] Đang biên dịch ứng dụng 100% Thuần Swift & SwiftUI..."

APP_NAME="Lexio"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
DMG_NAME="Lexio-Pure-Native-macOS.dmg"

# 1. Dọn dẹp bản build cũ
rm -rf "${BUNDLE_DIR}" "${DMG_NAME}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 2. Copy App Icon chuẩn macOS
if [ -f "native-macos/AppIcon.icns" ]; then
    echo "🎨 1. Áp dụng App Icon chuẩn macOS..."
    cp "native-macos/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
elif [ -f "AppIcon.icns" ]; then
    echo "🎨 1. Áp dụng App Icon chuẩn macOS..."
    cp "AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# 3. Tạo Info.plist chuẩn macOS
echo "📝 2. Tạo Info.plist..."
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
    <string>com.tulietech.lexionative</string>
    <key>CFBundleVersion</key>
    <string>2.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleExecutable</key>
    <string>Lexio</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Tulie Tech. All rights reserved.</string>
</dict>
</plist>
EOF

# 4. Tìm toàn bộ file Swift nguồn
SWIFT_FILES=$(find pure-macos/Sources -name "*.swift")

# 5. Biên dịch mã nguồn Swift 6 thành Native Mach-O Executable (ARM64 Apple Silicon)
echo "⚡ 3. Biên dịch Native Mach-O Executable bằng Apple Swift 6..."
swiftc ${SWIFT_FILES} \
    -O \
    -target arm64-apple-macos13.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework AVFoundation \
    -framework Combine \
    -framework UniformTypeIdentifiers \
    -parse-as-library \
    -o "${MACOS_DIR}/Lexio"

chmod +x "${MACOS_DIR}/Lexio"

# 6. Ký số ad-hoc để Gatekeeper không chặn
echo "🔏 4. Ký số Ad-hoc (Code Signing)..."
codesign --force --deep --sign - "${BUNDLE_DIR}"

# 7. Đóng gói DMG Installer với giao diện Finder chuyên nghiệp (Icon to 128x128)
echo "💿 5. Đóng gói file cài đặt DMG (${DMG_NAME})..."
VOL_NAME="Lexio PRO Native"
TMP_DMG="temp_dmg_rw.dmg"
rm -f "${TMP_DMG}" "${DMG_NAME}"

# Tháo gỡ các volume cũ nếu còn sót lại
for m in /Volumes/"${VOL_NAME}"*; do
    if [ -d "$m" ]; then
        hdiutil detach "$m" -force 2>/dev/null || true
    fi
done

# Tạo ảnh đĩa RW tạm thời
hdiutil create -size 50m -fs HFS+ -volname "${VOL_NAME}" "${TMP_DMG}" > /dev/null

# Gắn kết ổ đĩa RW
ATTACH_OUT=$(hdiutil attach -readwrite -noverify -noautoopen "${TMP_DMG}")
DEV=$(echo "${ATTACH_OUT}" | grep -E "/Volumes/${VOL_NAME}" | head -n 1 | awk '{print $1}')
MOUNT_DIR=$(echo "${ATTACH_OUT}" | grep -E "/Volumes/${VOL_NAME}" | head -n 1 | sed -E 's/.*(\/Volumes\/.*)/\1/')

# Sao chép ứng dụng và tạo alias /Applications
cp -R "${BUNDLE_DIR}" "${MOUNT_DIR}/"
ln -s /Applications "${MOUNT_DIR}/Applications"

# Cấu hình giao diện Finder: Cỡ icon 128x128, kích thước cửa sổ 600x400, căn giữa Lexio & Applications
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "${VOL_NAME}"
        open
        delay 0.5
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 200, 1000, 600}
        set viewOptions to the icon view options of container window
        set icon size of viewOptions to 128
        set text size of viewOptions to 13
        set arrangement of viewOptions to not arranged
        set position of item "Lexio.app" of container window to {160, 190}
        set position of item "Applications" of container window to {440, 190}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DEV" > /dev/null

# Nén sang định dạng chuẩn UDZO cuối cùng
hdiutil convert "${TMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_NAME}" > /dev/null
rm -f "${TMP_DMG}"

echo "=========================================================="
echo "✅ [HOÀN TẤT THÀNH CÔNG!]"
echo "   • Ứng dụng Thuần Native: ${BUNDLE_DIR}"
echo "   • Bộ cài đặt DMG: ${DMG_NAME}"
echo "   • Kiểm tra kích thước binary: $(du -sh "${MACOS_DIR}/Lexio" | cut -f1)"
echo "   • Chạy ứng dụng ngay: open ${BUNDLE_DIR}"
echo "=========================================================="

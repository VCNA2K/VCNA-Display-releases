#!/bin/bash
# Tải và cài VCNA Display bản mới nhất vào /Applications, rồi mở app.
# Dùng: curl -fsSL https://raw.githubusercontent.com/VCNA2K/VCNA-Display-releases/main/install.sh | bash
# Chạy lại bất cứ lúc nào để cập nhật lên bản mới nhất.

# Mọi thứ nằm trong một hàm, gọi ở dòng cuối: nếu việc tải script bị ngắt
# giữa chừng, phần đã tải không chạy được nửa vời.
main() {
    set -euo pipefail

    local app="VCNA Display"
    local url="https://github.com/VCNA2K/VCNA-Display-releases/releases/latest/download/VCNA-Display.dmg"
    local dest="/Applications/$app.app"
    local work
    work="$(mktemp -d /tmp/vcna-install.XXXXXX)"
    local mount="$work/mnt"

    trap 'hdiutil detach -quiet "'"$mount"'" 2>/dev/null || true; rm -rf "'"$work"'"' EXIT

    if [ ! -w /Applications ]; then
        echo "Tài khoản này không có quyền cài vào /Applications. Hãy chạy bằng tài khoản quản trị." >&2
        exit 1
    fi

    echo "Đang tải VCNA Display…"
    curl -fL --progress-bar -o "$work/VCNA-Display.dmg" "$url"

    hdiutil attach -quiet -nobrowse -readonly -noautoopen -mountpoint "$mount" "$work/VCNA-Display.dmg"
    if [ ! -d "$mount/$app.app" ]; then
        echo "Lỗi: file tải về không có $app.app." >&2
        exit 1
    fi

    # Bản đang chạy phải thoát trước, nếu không app vừa cài sẽ không mở lại.
    if pgrep -x "$app" >/dev/null; then
        pkill -x "$app" || true
        sleep 1
    fi

    echo "Đang cài vào /Applications…"
    rm -rf "$dest"
    ditto "$mount/$app.app" "$dest"

    local version
    version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$dest/Contents/Info.plist" 2>/dev/null || echo "")"
    open "$dest"
    echo "Xong! Đã cài VCNA Display ${version}."
}

main "$@"

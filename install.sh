#!/bin/bash
# Tải và cài VCNA Display bản mới nhất vào /Applications, rồi mở app.
# Dùng: curl -fsSL https://raw.githubusercontent.com/VCNA2K/VCNA-Display-releases/main/install.sh | bash
# Chạy lại bất cứ lúc nào để cập nhật lên bản mới nhất.

# Toàn bộ lệnh đều nằm trong các hàm và chỉ chạy khi gọi main ở dòng cuối:
# nếu việc tải script bị ngắt giữa chừng, phần đã tải không chạy nửa vời.
cleanup() {
    local rc=$?
    trap - EXIT INT TERM

    if [ "${HAD_OLD:-0}" -eq 1 ] && [ -n "${BACKUP:-}" ] && [ -e "$BACKUP" ] && [ -n "${DEST:-}" ]; then
        if [ ! -e "$DEST" ]; then
            mv "$BACKUP" "$DEST" 2>/dev/null || true
        elif [ -d "$DEST" ] && [ -f "$DEST/Contents/Info.plist" ]; then
            rm -rf "$BACKUP" 2>/dev/null || true
        fi
    fi

    if [ -n "${MOUNT:-}" ] && [ -d "$MOUNT" ]; then
        hdiutil detach -quiet "$MOUNT" 2>/dev/null \
            || hdiutil detach -force -quiet "$MOUNT" 2>/dev/null \
            || true
    fi

    if [ -n "${STAGING:-}" ] && [ -e "$STAGING" ]; then
        rm -rf "$STAGING" 2>/dev/null || true
    fi

    if [ -n "${WORK:-}" ] && [ -d "$WORK" ]; then
        if [ "${HAD_OLD:-0}" -eq 1 ] && [ -n "${BACKUP:-}" ] && [ -e "$BACKUP" ]; then
            echo "Cảnh báo: giữ lại bản sao lưu tại $BACKUP." >&2
        else
            rm -rf "$WORK" 2>/dev/null || true
        fi
    fi

    return "$rc"
}

replace_app() {
    local src="$1"
    local dest="$2"
    local work="$3"

    DEST="$dest"
    STAGING="$work/staging"
    BACKUP="$work/backup"
    HAD_OLD=0

    rm -rf "$STAGING" "$BACKUP"
    ditto "$src" "$STAGING" || return 1

    if [ -e "$dest" ]; then
        HAD_OLD=1
        mv "$dest" "$BACKUP" || return 1
    fi

    if ! mv "$STAGING" "$dest"; then
        if [ "$HAD_OLD" -eq 1 ] && [ -e "$BACKUP" ] && [ ! -e "$dest" ]; then
            mv "$BACKUP" "$dest" 2>/dev/null || true
        fi
        echo "Lỗi: không thể thay thế $dest." >&2
        return 1
    fi

    if [ "$HAD_OLD" -eq 1 ] && [ -e "$BACKUP" ]; then
        rm -rf "$BACKUP" 2>/dev/null || echo "Cảnh báo: không xoá được bản sao lưu tạm $BACKUP." >&2
    fi
}

main() {
    set -euo pipefail

    local app="VCNA Display"
    local url="https://github.com/VCNA2K/VCNA-Display-releases/releases/latest/download/VCNA-Display.dmg"
    DEST="/Applications/$app.app"
    WORK=""
    MOUNT=""
    STAGING=""
    BACKUP=""
    HAD_OLD=0

    if [ ! -w /Applications ]; then
        echo "Tài khoản này không có quyền cài vào /Applications. Hãy chạy bằng tài khoản quản trị." >&2
        exit 1
    fi

    if [ -e "$DEST" ] && [ ! -w "$DEST" ]; then
        echo "Tài khoản này không có quyền ghi đè $DEST. Hãy kiểm tra quyền hoặc chạy bằng tài khoản quản trị." >&2
        exit 1
    fi

    WORK="$(mktemp -d /tmp/vcna-install.XXXXXX)"
    MOUNT="$WORK/mnt"

    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    echo "Đang tải VCNA Display…"
    curl --proto '=https' --tlsv1.2 --connect-timeout 15 -fL --progress-bar -o "$WORK/VCNA-Display.dmg" "$url"

    hdiutil attach -quiet -nobrowse -readonly -noautoopen -mountpoint "$MOUNT" "$WORK/VCNA-Display.dmg"
    if [ ! -d "$MOUNT/$app.app" ]; then
        echo "Lỗi: file tải về không có $app.app." >&2
        exit 1
    fi

    if ! codesign --verify --deep --strict "$MOUNT/$app.app" >/dev/null 2>&1; then
        echo "Lỗi: chữ ký của $app.app không hợp lệ hoặc file tải về bị hỏng." >&2
        exit 1
    fi

    # Bản đang chạy phải thoát trước, nếu không app vừa cài sẽ không mở lại.
    if pgrep -x "$app" >/dev/null; then
        local waited=0
        pkill -x "$app" 2>/dev/null || true
        while [ "$waited" -lt 10 ] && pgrep -x "$app" >/dev/null; do
            sleep 0.5
            waited=$((waited + 1))
        done
        if pgrep -x "$app" >/dev/null; then
            pkill -KILL -x "$app" 2>/dev/null || true
            waited=0
            while [ "$waited" -lt 4 ] && pgrep -x "$app" >/dev/null; do
                sleep 0.5
                waited=$((waited + 1))
            done
        fi
        if pgrep -x "$app" >/dev/null; then
            echo "Lỗi: không thể thoát $app đang chạy. Hãy thoát app rồi thử lại." >&2
            exit 1
        fi
    fi

    echo "Đang cài vào /Applications…"
    replace_app "$MOUNT/$app.app" "$DEST" "$WORK"

    local version
    version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$DEST/Contents/Info.plist" 2>/dev/null || echo "")"
    open "$DEST"
    echo "Xong! Đã cài VCNA Display ${version}."
    echo "Lưu ý: nếu nâng cấp từ bản 3.9.4 trở về trước mà phím độ sáng không ăn, hãy tắt rồi bật lại VCNA Display trong Quyền riêng tư & Bảo mật › Trợ năng (chỉ cần một lần)."
}

if [ "${VCNA_INSTALL_NO_MAIN:-0}" != "1" ]; then
    main "$@"
fi

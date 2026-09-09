# VCNA Display — bản cài và cập nhật

Repo này chỉ chứa **bản cài** và **feed cập nhật** của VCNA Display. Mã nguồn nằm ở repo riêng.

## Tải về

Bản mới nhất: [**Releases**](../../releases/latest)

1. Tải `VCNA-Display.dmg`
2. Mở file, kéo **VCNA Display** vào thư mục **Applications**
3. Mở ứng dụng — nó nằm ở thanh menu, hình biểu tượng màn hình
4. Vào **System Settings → Privacy & Security → Accessibility** và cấp quyền cho VCNA Display, để phím độ sáng hoạt động trên màn hình rời

Yêu cầu macOS 14 (Sonoma) trở lên. Bản universal, chạy trên cả Apple Silicon và Intel.

## Tự động cập nhật

Ứng dụng tự kiểm tra bản mới qua `appcast.xml` trong release mới nhất. File đó được ký bằng EdDSA và ứng dụng chỉ nhận bản cập nhật có chữ ký khớp, nên **đừng xoá hay sửa nó** trong release.

## Giấy phép

MIT.

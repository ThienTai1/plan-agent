# Hướng Dẫn Chạy Flutter App

## Yêu Cầu

- ✅ Flutter đã được cài đặt (3.38.1)
- ✅ Dependencies đã được install (`flutter pub get`)

## Các Cách Chạy App

### 1. Chạy trên Web (Chrome) - Khuyên dùng cho development

```bash
cd apps/frontend
flutter run -d chrome
```

Hoặc:

```bash
cd apps/frontend
flutter run -d web-server --web-port=8080
```

### 2. Chạy trên macOS Desktop

```bash
cd apps/frontend
flutter run -d macos
```

### 3. Chạy trên Android/iOS (nếu có emulator/device)

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Lưu Ý Quan Trọng

### API Base URL

App hiện tại được cấu hình để gọi API tại `http://localhost:8000` (Gateway Service).

**Trước khi chạy app, đảm bảo:**
1. Gateway Service đang chạy trên port 8000
2. Các microservices (auth-service, agent-service, etc.) đang chạy

### Nếu chạy trên Web

Khi chạy trên web, `localhost:8000` sẽ hoạt động bình thường.

### Nếu chạy trên Mobile/Desktop

Nếu chạy trên mobile emulator hoặc desktop app, có thể cần thay đổi base URL:
- Android Emulator: `http://10.0.2.2:8000` (thay vì localhost)
- iOS Simulator: `http://localhost:8000` (hoạt động bình thường)
- macOS Desktop: `http://localhost:8000` (hoạt động bình thường)

Để thay đổi, sửa file `lib/core/config/api_config.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8000'; // For Android emulator
```

## Hot Reload

Khi app đang chạy:
- Nhấn `r` trong terminal để hot reload
- Nhấn `R` để hot restart
- Nhấn `q` để quit

## Debug Mode

App sẽ chạy ở debug mode mặc định, cho phép:
- Hot reload
- Debug console
- Performance overlay (nhấn `P` trong terminal)

## Production Build

Để build production:

```bash
# Web
flutter build web

# macOS
flutter build macos

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Troubleshooting

### Lỗi "Unable to connect to API"

1. Kiểm tra Gateway Service có đang chạy không:
   ```bash
   curl http://localhost:8000/health
   ```

2. Kiểm tra CORS settings trong Gateway Service

3. Kiểm tra base URL trong `api_config.dart`

### Lỗi "Dependencies not found"

```bash
cd apps/frontend
flutter clean
flutter pub get
```

### Lỗi "Device not found"

```bash
flutter devices
flutter emulators
```

## Quick Start

```bash
# 1. Navigate to frontend directory
cd apps/frontend

# 2. Install dependencies (nếu chưa)
flutter pub get

# 3. Start Gateway Service (trong terminal khác)
# cd apps/gateway && uvicorn app.main:app --reload --port 8000

# 4. Run Flutter app
flutter run -d chrome
```


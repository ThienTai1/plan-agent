# Planning Agent Monorepo

Chào mừng bạn đến với **Planning Agent Monorepo**! Đây là kho lưu trữ hợp nhất (monorepo) quản lý toàn bộ hệ thống của dự án Planning Agent bao gồm: ứng dụng di động Flutter (Frontend), cổng API Gateway/BFF dựa trên FastAPI, các dịch vụ microservices (agent, calendar, auth), các thư viện Python dùng chung và các tài nguyên hạ tầng (Docker, Kubernetes manifests).

Dự án này được thiết kế và cấu trúc nhằm mang lại trải nghiệm phát triển local đồng bộ, nhanh chóng và an toàn nhất.

---

## 📁 Cấu trúc Thư mục Dự án

```text
.
├── apps/
│   ├── frontend/              # 📱 Ứng dụng di động Flutter (Frontend Client)
│   ├── agent-orchestrator/    # 🤖 AI Agent Orchestrator chính thức (LangGraph)
│   ├── agent-prototype-baml/  # 🧪 AI Agent phiên bản thử nghiệm (BAML)
│   ├── calendar-service/      # 📅 Dịch vụ tích hợp Lịch (Google Calendar, etc.)
│   └── auth-service/          # 🔑 Dịch vụ Xác thực người dùng (Authentication)
├── libs/
│   ├── python-common/         # 📦 Thư viện Python dùng chung (cấu hình, logs, schemas)
│   └── api-contracts/         # 📑 File thiết kế OpenAPI dùng chung giữa các team
├── infra/
│   ├── docker/                # 🐳 Dockerfiles cho từng dịch vụ
│   ├── k8s/                   # ☸️ Kubernetes manifests để deploy lên cụm
│   └── scripts/               # 🛠️ Script hỗ trợ vận hành (dev_up/dev_down)
├── .env.example               # 📄 File mẫu biến môi trường gốc
└── README.md                  # 📘 Tài liệu hướng dẫn này
```

Mỗi dịch vụ Python được chuẩn hóa cấu trúc thư mục `app/` để dễ dàng làm quen và mở rộng:
```text
app/
├── main.py            # FastAPI Entry Point
├── api/               # Router chứa các endpoint phân theo domain/phiên bản
├── core/              # Các cấu hình và module log bổ trợ
├── models/            # Schema dữ liệu Pydantic mô tả API của dịch vụ
├── services/          # Các HTTP/RPC clients giao tiếp với các dịch vụ khác
└── ...                # Thư mục đặc thù (agent/, db/, providers/, ...)
```

---

## 🔒 Hướng dẫn Thiết lập Bảo mật & Biến Môi trường

Dự án đã được cấu hình bảo mật nghiêm ngặt. Để chạy được dự án ở máy cục bộ (local), bạn cần tạo các file cấu hình chứa key thật từ các file mẫu tương ứng (các file chứa key thật này đã bị chặn bởi Git và không bao giờ bị push lên GitHub).

### 1. Thiết lập cho Gốc Dự án
Sao chép file mẫu ở gốc dự án và điền các cấu hình cần thiết:
```bash
cp .env.example .env
```

### 2. Thiết lập cho Backend Microservices
* **Agent Orchestrator:**
  ```bash
  cd apps/agent-orchestrator
  cp .env.example .env
  ```
* **Agent Prototype BAML:**
  ```bash
  cd apps/agent-prototype-baml
  cp .env.example .env
  ```
*(Hãy điền các API Key của OpenAI, Gemini, OpenRouter, Supabase hoặc thông tin kết nối DB của bạn vào các file `.env` vừa tạo).*

### 3. Thiết lập cho Ứng dụng Flutter (Frontend)
Tạo file cấu hình bí mật cho ứng dụng di động:
```bash
cd apps/frontend/lib/core/secrets
cp app_secrets.dart.example app_secrets.dart
```
Mở file `app_secrets.dart` và thay thế các chuỗi giữ chỗ bằng các thông số thực tế của bạn:
```dart
class AppSecrets {
  static const supabaseUrl = 'YOUR_SUPABASE_URL';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const revenueCatApiKey = 'YOUR_REVENUE_CAT_API_KEY';
}
```

---

## 🚀 Hướng dẫn Cài đặt & Vận hành Cục bộ

### Yêu cầu Hệ thống
Đảm bảo máy của bạn đã cài đặt các công cụ sau:
* **Python** (Phiên bản >= 3.10) kèm theo trình quản lý gói [uv](https://github.com/astral-sh/uv).
* **Flutter SDK** (cho môi trường Flutter Mobile).
* **Docker Desktop** (để chạy cụm container cục bộ).

### Các bước khởi động

#### Bước 1: Đồng bộ hóa Thư viện dùng chung (Python Common)
Di chuyển vào thư mục thư viện dùng chung, cài đặt dependencies và thiết lập chế độ chỉnh sửa trực tiếp (editable mode):
```bash
cd libs/python-common
uv sync
```

#### Bước 2: Cài đặt Dependencies cho các dịch vụ Backend
Đối với bất kỳ dịch vụ nào trong thư mục `apps/`, di chuyển vào thư mục đó và chạy lệnh cài đặt:
```bash
cd apps/agent-orchestrator # Ví dụ dịch vụ chính
uv sync
```

#### Bước 3: Khởi động hệ thống Backend bằng Docker Compose
Chúng tôi cung cấp bộ script đóng gói sẵn trong thư mục `infra/scripts/` để chạy nhanh các container (FastAPI, Postgres, Redis, RabbitMQ, v.v.):
```bash
# Khởi động toàn bộ cụm services cục bộ
./infra/scripts/dev_up.sh

# Dừng toàn bộ cụm services
./infra/scripts/dev_down.sh
```
Nếu bạn muốn chạy đơn lẻ một service Python không qua Docker để tiện debug:
```bash
uv run uvicorn app.main:app --reload
```

#### Bước 4: Chạy ứng dụng di động Flutter
Di chuyển vào thư mục frontend, tải các gói thư viện và chạy ứng dụng trên thiết bị mô phỏng hoặc thiết bị thật:
```bash
cd apps/frontend
flutter pub get
flutter run
```

---

## ☁️ Quy trình Deploy an toàn lên Google Cloud Platform (GCP)

Để deploy dịch vụ `agent-orchestrator` lên Google Cloud Run, chúng tôi cung cấp script deploy thông minh tại [deploy.sh](file:///Users/taipham/Projects/planning_agent/planning_agent/apps/agent-orchestrator/scripts/deploy.sh).

Script này sẽ tự động phát hiện GCP Project đang hoạt động trên terminal của bạn thông qua lệnh `gcloud` mà không yêu cầu bạn phải ghi cứng bất kỳ thông tin nhạy cảm nào vào file script:

```bash
# Di chuyển tới thư mục chứa script
cd apps/agent-orchestrator/scripts

# Cấp quyền thực thi và chạy deploy
chmod +x deploy.sh
./deploy.sh
```

---

## 🛠️ Công cụ & Quy chuẩn Code

* **Python:** Sử dụng `ruff` để kiểm tra lỗi cú pháp (linter) và định dạng code (formatter). Các bộ test tự động được viết bằng `pytest`.
* **Flutter:** Tuân thủ chặt chẽ theo các quy chuẩn phân tích cú pháp tĩnh được thiết lập sẵn tại file `analysis_options.yaml` trong thư mục frontend.
* **Quy chuẩn chia sẻ:** Các logic chung liên quan tới Logger, Middleware, Cấu hình hệ thống phải được phát triển trong `libs/python-common/` và import sang các dịch vụ thay vì viết lại.

Chúc bạn có những trải nghiệm lập trình tuyệt vời với Planning Agent! Nếu gặp bất kỳ khó khăn nào, hãy mở ticket hoặc liên hệ trực tiếp với đội ngũ phát triển.

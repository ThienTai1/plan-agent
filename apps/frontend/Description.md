Dưới đây là tài liệu **PRD (Product Requirements Document)** chi tiết dành cho MVP của ứng dụng **"Life OS"** (kết hợp Vision-Goal-Task-Event và AI Agent), được định dạng Markdown để bạn dễ dàng copy và sử dụng.

---

# PRODUCT REQUIREMENTS DOCUMENT (MVP) - LIFE OS

## 1. Value Proposition & Problem Statement

### Problem Statement (Vấn đề)
Người dùng thường có những mục tiêu lớn (Vision) nhưng thất bại trong việc thực hiện vì:
1.  Bị ngợp (Overwhelmed): Không biết chia nhỏ mục tiêu thành các bước cụ thể.
2.  Thiếu kế hoạch thời gian (Scheduling gap): Có danh sách việc cần làm (To-do list) nhưng không bao giờ xếp lịch để làm chúng (Time-blocking).
3.  Quản lý rời rạc: Dùng Notion để quản lý goal nhưng dùng Google Calendar để xem lịch, thiếu sự đồng bộ.

### Value Proposition (Giá trị cốt lõi)
**Life OS** là một "Hệ điều hành cuộc sống" tích hợp AI, giúp người dùng tự động chuyển hóa mục tiêu mơ hồ thành kế hoạch hành động cụ thể (Tasks) và lịch trình chi tiết (Events), đảm bảo mọi Vision đều được thực thi mỗi ngày.

---

## 2. Job-To-Be-Done & User Flows

### Flow 1: Thiết lập Mục tiêu mới (The Setup Flow)
*Đây là flow quan trọng nhất để thể hiện giá trị của AI.*

*   **Job:** Người dùng muốn bắt đầu một mục tiêu mới (VD: "Học IELTS") và cần một lộ trình rõ ràng ngay lập tức.
*   **Flow:**
    1.  User vào màn hình "Goals" -> Bấm nút "+ New Goal".
    2.  User nhập Vision/Goal mơ hồ (VD: "Tôi muốn giỏi tiếng Anh").
    3.  **AI Inquisitor** hỏi lại để làm rõ (Chat UI): "Trình độ hiện tại? Thời gian rảnh? Mục tiêu cụ thể (IELTS/Giao tiếp)?".
    4.  User trả lời -> AI xác nhận đủ thông tin.
    5.  **AI Strategist & Tactician** chạy ngầm -> Sinh ra Plan (Phases, Tasks, Events).
    6.  App hiển thị bản nháp kế hoạch (Draft Plan).
    7.  **Điểm quyết định:** User xem -> Chỉnh sửa nhẹ (nếu cần) -> Bấm "Confirm & Start".
    8.  Hệ thống lưu vào DB -> Chuyển sang màn hình Goal Detail.

### Flow 2: Thực thi hàng ngày (The Execution Flow)
*Flow giữ chân người dùng mỗi ngày.*

*   **Job:** Người dùng mở mắt dậy và muốn biết "Hôm nay tôi phải làm gì?".
*   **Flow:**
    1.  User mở App -> Vào màn hình **Dashboard**.
    2.  User nhìn thấy Widget "Up Next" (Sự kiện sắp tới) và "Today's Tasks".
    3.  **Điểm quyết định:**
        *   Với Task: Bấm Checkbox để hoàn thành.
        *   Với Event: Xem giờ và địa điểm để tham gia.
    4.  Hệ thống cập nhật Progress của Goal tương ứng.

### Flow 3: Điều chỉnh lịch trình (The Maintenance Flow)
*Flow xử lý khi cuộc sống thay đổi.*

*   **Job:** Người dùng có việc đột xuất và muốn dời lịch mà không muốn thao tác thủ công phức tạp.
*   **Flow:**
    1.  User đang ở Dashboard -> Bấm nút **AI Chat (FAB)**.
    2.  User nhập: "Dời lịch học tối nay sang sáng mai."
    3.  **AI Scheduler** tìm Event -> Check lịch sáng mai -> Thực hiện dời.
    4.  **Điểm quyết định:** AI phản hồi "Đã dời sang 9h sáng mai". User xem lại Dashboard thấy cập nhật.

---

## 3. MVP Scope (Phạm vi phiên bản đầu)

Nguyên tắc: **"Functional & Usable"** (Chạy được và Dùng được).

### ✅ Must-have (Bắt buộc có ở V1)
1.  **Auth:** Đăng ký/Đăng nhập (Email/Password hoặc Google) qua Supabase.
2.  **Core Data:** Tạo/Sửa/Xóa (CRUD) Vision, Goal, Task, Event thủ công.
3.  **AI Planning (Basic):** Flow tạo Goal tự động (Input text -> Output Tasks/Events).
4.  **Dashboard UI:** Xem lịch hôm nay và task list hôm nay.
5.  **Goal Detail UI:** Xem Kanban board và Calendar của 1 Goal.
6.  **AI Chat (Maintenance):** Chat để sửa/dời lịch cơ bản.
7.  **Notifications:** Nhắc nhở local khi đến giờ Event.

### ⚠️ Should-have (Cân nhắc đẩy sang V1.1)
1.  **Custom Properties:** Cho phép user tự thêm trường dữ liệu (Cân nặng, Số trang) như Notion. (Để V1 hard-code trước).
2.  **Recurring Events (Phức tạp):** Logic lặp lại (Hàng tuần/tháng). MVP có thể chỉ hỗ trợ lặp hàng ngày đơn giản hoặc tạo tay.
3.  **Sync Calendar:** Đồng bộ với Google Calendar (Rất khó, để V2).

### ❌ Nice-to-have / Not in V1 (Để sau)
1.  **Offline Mode & Sync:** Dùng Local DB và sync sau (Phức tạp, V1 yêu cầu có mạng).
2.  **Voice Input:** Ra lệnh bằng giọng nói.
3.  **Social/Sharing:** Chia sẻ Goal với bạn bè.
4.  **Advanced Analytics:** Biểu đồ thống kê sâu.

---

## 4. Danh sách Màn hình & Specs

### Màn 1: Daily Timeline (Index 0)
*   **Mục tiêu:** Cho user thấy bức tranh tổng quan trong ngày và quản lý lịch trình.
*   **Dữ liệu:**
    *   `Next Event`: Event gần nhất sắp diễn ra.
    *   `Today Tasks`: List task có `due_date = today` hoặc `overdue`.
*   **Primary CTA:** Nút Checkbox (Hoàn thành Task).

### Màn 2: Vision Board (Index 1)
*   **Mục tiêu:** Hiển thị các mục tiêu dài hạn (Vision) dưới dạng Grid Masonry.

### Màn 3: Goals List (Index 2)
*   **Mục tiêu:** Quản lý danh sách các mục tiêu cụ thể (Projects, KPIs, Habits).

### Màn 4: Profile & Settings (Index 3)
*   **Mục tiêu:** Quản lý thông tin cá nhân, xem thống kê (Stats) và tùy chỉnh ứng dụng.
*   **Hành động chính:** Đăng xuất, Đổi theme, xem Gallery thành tựu.


### Màn 4: Master Calendar
*   **Mục tiêu:** Xem lịch tổng hợp để tránh trùng giờ.
*   **UI:** Lịch dạng Tuần (Weekly View) hoặc 3 ngày (3-day View).
*   **Dữ liệu:** Tất cả Events từ bảng `events`.
*   **Quy tắc:** Event khác Goal thì khác màu.

### Màn 5: AI Assistant Sheet (Bottom Sheet)
*   **Mục tiêu:** Sửa đổi nhanh thông qua chat.
*   **UI:** Khung chat đè lên màn hình hiện tại (Modal Bottom Sheet).
*   **Hành động:** Input field + Nút Gửi.

---

## 5. Yêu cầu Chất lượng (Non-functional Requirements)

Dựa trên ISO 25010:

1.  **Hiệu năng (Performance):**
    *   Mở app (Cold start) dưới 2s.
    *   AI phản hồi trong vòng 5-10s (Phải có loading state mượt mà để user không chán).
    *   Cuộn danh sách (List/Kanban) phải mượt (60fps), không giật lag.

2.  **Độ tin cậy (Reliability):**
    *   Xử lý lỗi AI: Nếu API AI chết hoặc trả về JSON lỗi, App không được crash. Phải hiện thông báo "AI đang bận, hãy thử tạo thủ công".
    *   Data Integrity: Không bao giờ được mất Task của user sau khi đã bấm Save.

3.  **Bảo mật (Security):**
    *   Dùng **RLS (Row Level Security)** của Supabase. User A tuyệt đối không query được Task của User B.
    *   Token của OpenAI/LLM phải giấu ở Backend (Python/Edge Function), tuyệt đối không để ở Frontend Flutter code.

4.  **Khả dụng (Usability):**
    *   Thao tác 1 tay: Các nút quan trọng (FAB, Tabbar) nằm ở dưới.
    *   Minimalist: Không nhồi nhét quá nhiều thông tin vào 1 card task.

---

## 6. Platform Guidelines (Flutter Context)

*   **Thiết kế:** Sử dụng **Material 3 (Material You)** của Google nhưng tùy biến theo style Minimalist.
*   **Navigation:** Sử dụng `GoRouter` để hỗ trợ Deep Link (Ví dụ: Bấm vào thông báo nhắc nhở -> Mở đúng màn hình Goal Detail).
*   **Platform adaptation:**
    *   Trên iOS: Dùng `CupertinoModalPopup` cho các menu chọn ngày/giờ.
    *   Trên Android: Dùng `Material DatePicker`.
    *   Hỗ trợ cử chỉ "Swipe to delete" (Vuốt để xóa) trên list task.

---

## 7. Checklist Chốt Hạ (Validation & Deployment)

Trước khi code dòng đầu tiên, hãy đảm bảo bạn đã:

*   [ ] **Thiết kế Database:** Chạy script SQL tạo bảng trên Supabase.
*   [ ] **Thiết lập Backend:** Deploy server Python (FastAPI/LangGraph) lên Cloud (Render/Railway/Fly.io).
*   [ ] **Prototype:** Vẽ tay hoặc Figma sơ sài 3 màn hình chính (Dashboard, Goal Detail, Chat) để hình dung luồng đi.
*   [ ] **Test AI Prompt:** Chạy thử Prompt của Inquisitor và Tactician trên ChatGPT playground để đảm bảo nó trả về đúng JSON mong muốn.

### Ghi chú quan trọng cho Dev (Bạn):
*   Hãy bắt đầu với **"Hard-coded Schema"** trước. Đừng làm tính năng "User tự thêm cột" (Notion-like) ngay ở tuần đầu tiên. Hãy làm cho luồng Task/Event chạy trơn tru trước đã.
*   Tách biệt rõ ràng: **Flutter** chỉ lo hiển thị. **Python** lo tư duy logic AI. **Supabase** lo lưu trữ và bảo mật.
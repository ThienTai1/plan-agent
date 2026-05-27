# 📝 Project Backlog - Agent Orchestrator

Dưới đây là danh sách các tính năng và cải thiện cần thực hiện để đưa hệ thống lên môi trường Production an toàn và chuyên nghiệp.

## ✅ Đã hoàn thành (Completed)
- [x] **JWT & Security**: Thay thế xác thực bằng `x-user-id` sang **Supabase JWT**.
- [x] **Async Persistence**: Triển khai `AsyncPostgresSaver` lưu lịch sử chat bền vững.
- [x] **Rate Limiting**: Tích hợp `SlowAPI` bảo vệ server.
- [x] **Specialist Agents**: Triển khai thành công `GoalTaskAgent` (Lập kế hoạch text) và `AnalyticAgent` (Phân tích dữ liệu).
- [x] **Interleaved UI (Action Cards)**: Hỗ trợ hiển thị xen kẽ Biểu đồ, Phân tích và Văn bản trong luồng stream.

## 🚀 Ưu tiên cao (High Priority)
- [x] **Pro/Free Quota System**: 
    - [x] Backend: Logic `check_and_deduct_quota` implemented (Trial 20 messages).
    - [x] DB: Updated `profiles` table logic.
    - [x] Frontend: Professional Paywall UI and Trial usage indicator.
- [ ] **Input Sanitization**: Chặn Prompt Injection và các câu hỏi ngoài phạm vi quản lý mục tiêu.

## 🛠️ Trải nghiệm & Vận hành (UX & OPS)
- [x] **Dashboard Analytics**: Trang tổng quan biểu đồ (ngoài Chat) để người dùng xem nhanh tiến độ.
- [ ] **Error Handling Refinement**: Thông báo lỗi thân thiện khi gặp sự cố LLM.
- [ ] **JWKS Caching Strategy**: Tối ưu hóa việc cache public key của Supabase.
- [ ] **Deployment Optimization**: Tối ưu hóa file `.dockerignore` để giảm kích thước tarball khi deploy (giảm từ 570MiB xuống mức tối thiểu).

---
*Ghi chú: Luôn cập nhật file này khi hoàn thành một Sprint.*

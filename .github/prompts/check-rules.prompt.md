---
description: "Kiểm tra code tuân thủ rules từ instruction files sau khi thực hiện xong plan. Sau khi check xong thì cập nhật checklist."
agent: "agent"
tools: ["changes"]
---

# Kiểm tra Rules từ Instructions

Sau khi thực hiện xong một plan trong `.github/plan/`, hãy kiểm tra tất cả các file đã thay đổi có tuân thủ rules trong `.github/instructions/` hay không.

## Quy trình

### 1. Xác định loại tính năng
- Nếu feature thao tác **trong game** (cửa sổ game, chuột/phím, pixel, image search, auto plus, switch char...) → áp dụng rules từ [auto_devil.instructions.md](.github/instructions/auto_devil.instructions.md)
- Nếu feature thao tác **trên web** (WebDriver, Selenium, đăng nhập web, captcha, reset web...) → áp dụng rules từ [auto_reset.instructions.md](.github/instructions/auto_reset.instructions.md)

### 2. Kiểm tra các rules

#### Rules cho tính năng IN-GAME (`auto_devil.instructions.md`):
- [ ] Các thao tác game **gọi qua `game_utils.au3`**, KHÔNG gọi trực tiếp trong file feature
- [ ] File feature chỉ chứa logic riêng của feature, không gọi hàm tiện ích chung trực tiếp
- [ ] Hàm mới trong `game_utils.au3` tổ chức theo nhóm chức năng

#### Rules cho tính năng WEB (`auto_reset.instructions.md`):
- [ ] Các thao tác WebDriver **gọi qua `web_mu_utils.au3`**, KHÔNG gọi trực tiếp trong file feature
- [ ] File feature chỉ chứa logic riêng của feature, không gọi hàm tiện ích chung trực tiếp
- [ ] Hàm mới trong `web_mu_utils.au3` tổ chức theo nhóm chức năng

#### Rules chung (từ `copilot-instructions.md`):
- [ ] Tọa độ pixel đọc từ JSON config, KHÔNG hardcode
- [ ] Dùng `writeLog()` / `writeLogFile()` cho mọi ghi log
- [ ] Dùng `secondWait()` thay vì `Sleep()` trực tiếp
- [ ] Biến toàn cục có tiền tố `$`, khai báo đầu file
- [ ] Hàm đặt tên `camelCase` hoặc `snake_case`
- [ ] Hàm UDF có tiền tố gạch dưới (`_`)
- [ ] Hàm không quá ~100 dòng
- [ ] `#include-once` ở đầu file tiện ích/thư viện
- [ ] Comment logic không rõ ràng

### 3. Báo cáo kết quả
Liệt kê:
- **PASS**: Các rules đã tuân thủ
- **FAIL**: Các rules vi phạm → chỉ rõ file, dòng, và cách sửa
- Thực hiện sửa nếu có vi phạm

### 4. Cập nhật checklist
Sau khi kiểm tra xong, cập nhật trạng thái trong [checklist.md](.github/plan/checklist.md):
- Đánh dấu `[x]` cho các mục đã hoàn thành
- Ghi chú nếu có mục cần chỉnh sửa thêm

### 5. Cập nhật thay file [position_config_changes.md](../../config/json/change/position_config_changes.md) nếu có đổi dựa trên [position_config.instructions.md]

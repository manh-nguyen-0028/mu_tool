---
applyTo: "config/json/example/position_config_example.json"
---

# Rules cho position_config_example.json

- Khi thêm, sửa hoặc xóa field trong file `position_config_example.json`, **PHẢI** tạo/cập nhật file change log tại `config/json/change/position_config_changes.md`
- **Cách xác định thay đổi**: So sánh file `position_config_example.json` giữa version hiện tại và version trước đó bằng git diff
  - Xác định branch/tag hiện tại (ví dụ: `update/v1.20`)
  - So sánh với version trước (`update/v1.19`) bằng lệnh:
    ```
    git diff update/v1.19..update/v1.20 -- config/json/change/position_config_example.json
    ```
  - Nếu không có branch/tag, dùng `git diff HEAD~1 -- config/json/change/position_config_example.json`
- File change log ghi rõ:
  - Version so sánh (từ → đến)
  - Field nào được thêm/sửa/xóa
  - Giá trị mới (hoặc giá trị cũ nếu xóa)
  - Lý do thay đổi (tính năng nào yêu cầu)
- Nếu file `position_config_changes.md` đã tồn tại, **append** thêm entry mới vào cuối file, KHÔNG ghi đè
- Format entry:
  - [YYYY/MM/DD] - So sánh update/vX.Y → update/vX.Z
  - Thêm: section.field_name = giá trị — mô tả ngắn
  - Sửa: section.field_name: giá trị cũ → giá trị mới — mô tả ngắn
  - Xóa: section.field_name = giá trị cũ — mô tả ngắn
---
description: "Cập nhật file position_config_changes.md nếu có thay đổi trong position_config_example.json dựa trên position_config.instructions.md"
agent: "agent"
---

# Cập nhật Position Config Changes Log

Cập nhật file [position_config_changes.md](../../config/json/change/position_config_changes.md) nếu có thay đổi dựa trên [position_config.instructions.md](../instructions/position_config.instructions.md).

## Quy trình

### 1. Xác định thay đổi
- Xác định branch/tag hiện tại (ví dụ: `update/v1.21`)
- So sánh với version main trước bằng lệnh:
  ```
  git diff main..<version_hien_tai> -- config/json/example/position_config_example.json
  ```
- Nếu không có branch/tag, dùng:
  ```
  git diff HEAD -- config/json/example/position_config_example.json
  ```

### 2. Phân tích diff
- Xác định các field nào được **thêm**, **sửa**, hoặc **xóa**
- Xác định section chứa field đó (ví dụ: `button.event_devil`)
- Tìm hàm/file sử dụng field đó trong codebase (`grep_search`)

### 3. Append vào change log
Nếu có thay đổi, **append** (KHÔNG ghi đè) entry mới vào cuối [position_config_changes.md](../../config/json/change/position_config_changes.md) theo format:

```
### YYYY/MM/DD — <Tên tính năng>
- **Compare:** update/vX.Y → update/vX.Z
- **Section:** `<section.subsection>`
- Thêm: `<section.field_name>` = <giá trị> — <mô tả ngắn>
- Sửa: `<section.field_name>`: <giá trị cũ> → <giá trị mới> — <mô tả ngắn>
- Xóa: `<section.field_name>` = <giá trị cũ> — <mô tả ngắn>
- **Used by:** `<hàm>()` trong `<file>`
- **Feature:** `<feature_file>`
```

### 4. Không làm gì nếu không có thay đổi
Nếu diff trả về rỗng, không cần cập nhật file change log.

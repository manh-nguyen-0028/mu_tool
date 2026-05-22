# Position Config Changes Log

Ghi lại các thay đổi tọa độ trong `position_config.json` / `m1_position_config.json` / `m2_position_config.json`.

## Changelog

### 2026-04-29 — Auto Reset Online
- **Section:** `button.train_in_game`
- **Keys added:** `checkbox_reset_x`, `checkbox_reset_y`
- **Value:** `0, 0` (placeholder — cần cập nhật tọa độ thực tế từ cửa sổ Auto Plus)
- **Used by:** `startAutoPlusWithReset()`, `startAutoPlusWithoutReset()` trong `utils/game_utils.au3`
- **Feature:** `feature/auto_reset/auto_reset_online.au3`

### 2026-05-04 — Auto Login Launcher Flow
- **Section:** `common.login`
- **Keys added:** `button_start_x`, `button_start_y`, `first_account_x`, `first_account_y`, `wait_load_user_sec`
- **Value:** `1212, 693, 0, 0, 5` trong example config — placeholder hoặc default chờ load user
- **Used by:** `processLogin()` trong `feature/auto_login/auto_login.au3`
- **Feature:** `feature/auto_login/auto_login.au3`

### 2026/05/12 — Auto Devil — Đóng popup khi không thể vào sự kiện
- **Compare:** update/v1.20 → update/v1.21
- **Section:** `button.event_devil`
- Thêm: `button.event_devil.close_popup_event_devil_x` = 239 — Tọa độ X để đóng popup khi không thể tham gia sự kiện Devil
- Thêm: `button.event_devil.close_popup_event_devil_y` = 126 — Tọa độ Y để đóng popup khi không thể tham gia sự kiện Devil
- **Used by:** `actionWhenCantJoinDevil()` trong `utils/game_utils.au3`
- **Feature:** `feature/auto_devil/auto_devil.au3`

### 2026/05/22 — Search Image Full Screen MU
- **Compare:** main → update/v1.21
- **Section:** `common.screen_800_600`
- Thêm: `common.screen_800_600.x` = 0 — Tọa độ X góc trên trái vùng tìm kiếm ảnh toàn màn hình MU
- Thêm: `common.screen_800_600.y` = 0 — Tọa độ Y góc trên trái vùng tìm kiếm ảnh toàn màn hình MU
- Thêm: `common.screen_800_600.x1` = 800 — Tọa độ X góc dưới phải vùng tìm kiếm ảnh toàn màn hình MU
- Thêm: `common.screen_800_600.y1` = 600 — Tọa độ Y góc dưới phải vùng tìm kiếm ảnh toàn màn hình MU
- **Used by:** `searchImageFullScreenMu()` trong `utils/game_utils.au3`
- **Feature:** `feature/auto_devil/auto_devil.au3`, `feature/auto_reset/auto_rs.au3`

### 2026/05/22 — Auto Reset — Cộng điểm trong game
- **Compare:** main → update/v1.21
- **Section:** `button.bang_c`
- Thêm: `button.bang_c.add_point_x` = 429 — Tọa độ X nút cộng điểm trong bảng C
- Thêm: `button.bang_c.add_point_y` = 178 — Tọa độ Y nút cộng điểm trong bảng C
- Thêm: `button.bang_c.add_point_confirm_x` = 356 — Tọa độ X nút xác nhận cộng điểm
- Thêm: `button.bang_c.add_point_confirm_y` = 445 — Tọa độ Y nút xác nhận cộng điểm
- **Used by:** `addPointInGame()` trong `feature/auto_reset/auto_rs.au3`
- **Feature:** `feature/auto_reset/auto_rs.au3`
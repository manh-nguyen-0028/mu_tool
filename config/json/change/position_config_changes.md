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
# Checklist: Auto Reset Online In-Game

## Phase 1: Config
- [x] Tạo `config/json/example/reset_online_config_example.json` — file config mẫu
- [x] Thêm entry `{"active":true, "type":"reset_online", "key":"file_name", "value":"reset_online_config.json"}` vào `config/json/config.json`
- [x] Thêm global `$resetOnlineConfigFileName` trong `utils/common_utils.au3`
- [x] Thêm xử lý `type=="reset_online"` trong hàm `init()` của `utils/common_utils.au3`

## Phase 2: Position Config
- [x] Thêm `checkbox_reset_x`, `checkbox_reset_y` vào section `button.train_in_game` trong `m1_position_config.json`
- [ ] Xác nhận tọa độ checkbox reset thực tế từ cửa sổ Auto Plus (hiện tại placeholder 0,0)

## Phase 3: Game Utils (`utils/game_utils.au3`)
- [x] Thêm hàm `startAutoPlusWithReset()` — mở Auto Plus → tick checkbox reset → click Start
- [x] Thêm hàm `startAutoPlusWithoutReset()` — mở Auto Plus → bỏ tick checkbox reset → click Start

## Phase 4: Feature File (`feature/auto_reset/auto_reset_online.au3`)
- [x] Tạo file `auto_reset_online.au3` với include `common_utils.au3` + `game_utils.au3`
- [x] Hàm `start()` — mở log file, while loop gọi `processResetOnline()`, sleep 30 phút giữa các loop
- [x] Hàm `getArrayActiveResetOnline()` — load config, lọc `active: true`, trả về mảng
- [x] Hàm `processResetOnline()`:
  - [x] Load danh sách nhân vật active
  - [x] Loop từng nhân vật
  - [x] Check thời gian: `last_time_reset + wait_hours` vs now → chưa đủ thì skip
  - [x] `checkActiveWinByChar($charName)` — tìm cửa sổ game
  - [x] Nếu không thấy + `need_switch_char=true` → `checkActiveOtherChar()` → `switchOtherChar()`
  - [x] Nếu vẫn không thấy → ContinueLoop
  - [x] `activeAndMoveWinByChar($charName)` — mở cửa sổ game
  - [x] `stopAutoPlus()` — tắt auto plus hiện tại
  - [x] `startAutoPlusWithReset()` — bật auto plus có tick reset
  - [x] `secondWait(120)` — chờ 2 phút
  - [x] `stopAutoPlus()` — tắt auto plus
  - [x] `startAutoPlusWithoutReset()` — bật auto plus bình thường (bỏ tick reset)
  - [x] `minisizeMain($mainNo)` — ẩn cửa sổ game
  - [x] Cập nhật `last_time_reset` vào config file

## Verification
- [ ] Flow đầy đủ: 1 nhân vật active → check time → mở cửa sổ → stop → start+reset → chờ 2p → stop → start bình thường → ẩn → update config
- [ ] Nhân vật chưa đủ thời gian → bị skip
- [ ] Nhân vật không thấy cửa sổ + có nhân vật cùng account → switch → reset thành công
- [ ] Nhân vật không thấy cửa sổ + không có ai cùng account → skip
- [ ] `last_time_reset` được cập nhật trong config file sau reset

---

# Checklist: Auto Login Game

## Phase 1: Sửa lỗi `processAutoLogin()`
- [ ] Sửa bug `StringSplit($aOtherCharName, "|")[0]` → dùng `[1]` cho phần tử đầu tiên
- [ ] Hoàn thiện hàm `start()` — mở log file, gọi `processAutoLogin()`, đóng log file

## Phase 2: Hoàn thiện `processLogin()` — tích hợp config
- [ ] Đọc tọa độ từ JSON config thay vì hardcode (button login, username field, password field...)
- [ ] Thêm các position vào `position_config.json` cho login flow
- [ ] Đọc đường dẫn game exe từ config (`game_path`)
- [ ] Tích hợp `chonServer()` — đọc tọa độ server select từ config

## Phase 3: Cơ chế lặp (tùy chọn)
- [ ] Thêm while loop + time check trong `start()` để chạy liên tục theo chu kỳ

## Verification
- [ ] charName có window → ContinueLoop (không làm gì)
- [ ] charName không có window → tìm nhân vật cùng account → switch thành công
- [ ] charName không có window → không tìm thấy ai → login mới
- [ ] StringSplit parse đúng charFound và numberChar

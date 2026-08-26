# Plan: Reset Online In-Game Feature

## TL;DR
Tạo tính năng auto reset online trong game bằng cách điều khiển cửa sổ Auto Plus (bật/tắt, tick/bỏ tick checkbox reset). Config đơn giản theo nhân vật với thời gian chờ giữa các lần reset.

## Steps

### Phase 1: Config
1. Tạo `config/json/reset_online_config.json` — mảng JSON chứa các nhân vật cần reset online
2. Thêm entry `type: "reset_online"` vào `config/json/config.json` để init() load config
3. Thêm biến global `$resetOnlineFileName` trong `common_utils.au3` → init() đọc config theo type

### Phase 2: Position Config
4. Thêm tọa độ checkbox reset vào `position_config.json` dưới `button.train_in_game` (key: `checkbox_reset_x`, `checkbox_reset_y`)

### Phase 3: Game Utils
5. Thêm hàm `startAutoPlusWithReset()` vào `game_utils.au3` — mở Auto Plus, tick checkbox reset, click Start
6. Thêm hàm `startAutoPlusWithoutReset()` vào `game_utils.au3` — mở Auto Plus, bỏ tick checkbox reset, click Start

### Phase 4: Feature File
7. Tạo `feature/auto_reset/auto_reset_online.au3` với:
   - `start()` — mở log, gọi processResetOnline(), loop
   - Tôi muốn thực hiện phím tắt Shift + F4 để tạm dừng chương trình
   - `processResetOnline()` — load config, lặp qua từng nhân vật active
   - Logic cho mỗi nhân vật:
     a. Kiểm tra xem thời gian trong file config có khác ngày hiện tại hay không ? Nếu có, mở web để cập nhập thời gian reset
     b. Kiểm tra thời gian: so sánh last_time_reset + wait_hours vs now, nếu chưa đủ → ContinueLoop
     c. Kiểm tra cửa sổ game: `checkActiveWinByChar($charName)`
     d. Nếu không tìm thấy → kiểm tra need_switch_char → tìm nhân vật cùng tài khoản → switchOtherChar
     e. Nếu vẫn không tìm thấy → ContinueLoop
     f. `activeAndMoveWinByChar($charName)`
     g. `stopAutoPlus()` — tắt auto plus hiện tại
     h. `startAutoPlusWithReset()` — bật auto plus có tick reset
     i. `secondWait(120)` — chờ 2 phút
     j. `stopAutoPlus()` — tắt auto plus
     k. `startAutoPlusWithoutReset()` — bật auto plus không tick reset
     l. `sendKeyF8()` — ẩn cửa sổ
     z. Cập nhật last_time_reset vào config file

## Config Format
```json
[
  {
    "active": true,
    "char_name": "TenNhanVat",
    "last_time_reset": "2026/04/29 10:00:00",
    "wait_hours": 4,
    "need_switch_char": true,
    "char_swith_name": "TenNhanVat"
  }
]
```

## Relevant files
- `config/json/config.json` — thêm entry type "reset_online"
- `config/json/reset_online_config_example.json` — **TẠO MỚI**
- `config/json/position_config_example.json` — thêm tọa độ checkbox_reset_x/y vào train_in_game
- `utils/common_utils.au3` — thêm global var `$resetOnlineFileName`, xử lý trong init()
- `utils/game_utils.au3` — thêm `startAutoPlusWithReset()`, `startAutoPlusWithoutReset()`; reuse `stopAutoPlus()`, `activeAndMoveWinByChar()`, `checkActiveWinByChar()`, `switchOtherChar()`, `minisizeMain()`
- `feature/auto_reset/auto_reset_online.au3` — **TẠO MỚI**, file feature chính
- `config/text/char_in_account.txt` — dùng cho tìm nhân vật cùng tài khoản (đã có)

## Verification
1. Chạy với 1 nhân vật active, kiểm tra flow: trường hợp ngày hiện tại khác với ngày trong last_time_reset thì đăng nhập web để thực hiện cập nhật lại trong file config → check thời gian →  mở cửa sổ → Enter 2 lần để tránh popup → cancelShiftF() → stop auto → start with reset → chờ 2p → stop → start without reset → ẩn (F8) → update config
2. Kiểm tra nhân vật chưa đủ thời gian → bị skip
3. Kiểm tra nhân vật không tìm thấy cửa sổ → switch thành công → thực hiện reset
4. Kiểm tra nhân vật không tìm thấy cửa sổ + không có nhân vật cùng account → skip
5. Verify file config được cập nhật last_time_reset sau khi reset xong

## Decisions
- File feature đặt tại `feature/auto_reset/auto_reset_online.au3` (cùng folder auto_reset)
- Config file: `reset_online_config.json`
- Tọa độ checkbox reset cần user cung cấp hoặc placeholder
- Tuân thủ instruction: game logic gọi qua game_utils.au3
- Pattern theo auto_devil.au3: while loop + time check

## Further Considerations
1. **Tọa độ checkbox reset** — Cần user cung cấp tọa độ chính xác của ô checkbox reset trong cửa sổ Auto Plus. Tạm thời sẽ đặt placeholder trong position_config.
2. **While loop hay chạy 1 lần?** — Recommend: while loop giống auto_devil với sleep giữa các iteration (30 phút check 1 lần).
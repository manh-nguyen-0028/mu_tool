# Plan: Auto Devil Auto Plus Event (auto_devil_auto_plus.au3)

## TL;DR
Feature mới dành riêng nhóm account devil có `type = auto_plus`. Luồng xử lý rút gọn: tính giờ event lùi 5 phút (riêng 23h -> 23h55) → active/switch rồi minisize account → xử lý fast join (move + follow, có chờ 2 phút khi cần follow) → xử lý nhóm còn lại tại mốc phút 26/50 (move map + start/stop auto plus) → chuyển về main chính nếu được phép. Chạy while loop liên tục.

---

## Core Architecture

### Main Flow
```
start()
├─ Mở log file
├─ mergeInfoAccountDevil("auto_plus")      [Lọc type = auto_plus sau merge]
└─ processGoDevil()                         [While loop chính]
   └─ checkThenGoDevilEvent()
      ├─ calculateNextDevilEventTime()      [Tính giờ event tiếp theo]
      ├─ Nếu chưa tới giờ (diffTime > 0):
      │  ├─ Check auto_rs.exe → Exit nếu có [Tránh xung đột với auto reset]
      │  ├─ Sleep() đến giờ event
      │  ├─ processGoEventDevil()           [Flow rút gọn active/switch + minisize]
      │  ├─ processFastJoinAccounts()       [Fast join: move + follow, chờ 2 phút nếu cần]
      │  └─ processRemainAccounts()         [Nhóm còn lại: mốc 26/50 -> move + start/stop auto plus]
      └─ Nếu đã qua giờ (diffTime <= 0):
         └─ waitToNextMinutes(58)           [Chờ ~1h đến event tiếp]
```

### Lịch Event Devil
```
calculateNextDevilEventTime($currentHour, $currentMin)
├─ 00h-02h → chờ đến 02h55
├─ 03h-05h → chờ đến 05h55
├─ 06h-10h, 12h-19h → chờ đến xx:55
├─ 11h, 20h-22h → event mỗi 30 phút
│  ├─ Mốc :30 → chạy lúc :25
│  └─ Mốc :00 giờ kế tiếp → chạy lúc :55 của giờ hiện tại
└─ 23h → chờ đến 23h55
```

### processGoEventDevil() — Vào Event
```
processGoEventDevil()
├─ reloadArrayActive()                [Load lại config mới nhất]
├─ validateAmountDevil()              [Kiểm tra có account active không]
└─ For each account active:
   ├─ activeAndMoveWin() / switchOtherChar()  [Active cửa sổ game]
   └─ minisizeMainByChar()                    [Ẩn cửa sổ]
```

### processFastJoinAccounts() — Xử Lý Fast Join
```
processFastJoinAccounts($jsonAccountActiveDevil)
├─ Lọc danh sách is_fast_join = true
└─ For each fast join:
   ├─ activeAndMoveWin() / switchOtherChar()
   ├─ Nếu cần follow leader → chờ 2 phút
   ├─ moveOtherMap()
   ├─ Nếu cần follow leader → _MU_followLeader(1)
   └─ minisizeMainByChar()
└─ switchToMainChar($fastJoinAccounts)       [Loop lại để về main chính nếu cho phép]
```

### processRemainAccounts() — Nhóm Còn Lại
```
processRemainAccounts($jsonAccountActiveDevil)
├─ Lọc danh sách không fast join
├─ Chờ tới phút 26 hoặc 50
└─ For each account còn lại:
   ├─ activeAndMoveWin() / switchOtherChar()
   ├─ moveOtherMap()
   ├─ startAutoPlus()
   ├─ stopAutoPlus()
   └─ minisizeMainByChar()
└─ switchToMainChar($remainAccounts)     [Loop lại để về main chính nếu cho phép]
```

---

## Config Format

### devil_config.json + devil_fixed_config.json
```json
[
  {
    "active": true,
    "have_ruong_k": true,           // Có rương K hay chưa
    "have_quest": false,            // Có quest Devil không
    "char_name": "TenNhanVat",
    "devil_no": 5,                  // Số Devil Square (1-7)
    "is_fast_join": true,           // true = vào Devil rồi ra nhanh sau 6 phút
    "ignore_peak_hour": true,       // Bỏ qua giờ cao điểm
    "switch_other_main": true,      // Có chuyển về main khác sau khi check không
    "main_char_name": "TenMain",    // Tên main char để chuyển về
    "is_check_400lv": true,         // Có cần kiểm tra 400 lvl trước khi vào không
    "is_need_follow_leader": true,  // Có cần follow leader sau event không
    "on_auto_plus": false,          // Có bật auto plus sau event không
    "need_check_auto_z": false,     // Có cần kiểm tra Auto Z không
      "max_hour_go": 25,              // Số giờ tối đa tham gia Devil
      "type": "auto_plus"            // Bắt buộc cho feature mới auto_devil_auto_plus
  }
]
```

---

## Hàm Chi Tiết

### Orchestration (auto_devil_auto_plus.au3)
| Hàm | Mô tả |
|------|--------|
| `start()` | Entry point: mở log → load config → processGoDevil() |
| `processGoDevil()` | While loop: reset log mỗi 10 lần → checkThenGoDevilEvent() |
| `checkThenGoDevilEvent()` | Tính giờ event → sleep → vào event → check kết quả → xử lý sau event |
| `calculateNextDevilEventTime()` | Tính giờ/phút event tiếp theo dựa trên giờ hiện tại |
| `getListFastMove()` | Lọc account có is_fast_join = true |
| `reloadArrayActive()` | Load lại config mới nhất |
| `processGoEventDevil()` | Loop qua account type auto_plus: active/switch + minisize |
| `getFastJoinAccounts()` | Lọc account có is_fast_join = true |
| `getRemainAccounts()` | Lọc account không fast join |
| `processFastJoinAccounts()` | Move + follow (nếu cần), chờ 2 phút khi follow, rồi switch main |
| `waitToMinute26Or50()` | Chờ đến mốc phút 26 hoặc 50 |
| `processRemainAccounts()` | Mốc 26/50: move map + start/stop auto plus, rồi switch main |

### Game Utils (game_utils.au3) — Devil Functions
| Hàm | Mô tả |
|------|--------|
| `getArrayActiveDevil()` | Load devil config → lọc active = true → trả về mảng |
| `clickIconDevil()` | Click icon Devil trên UI game (có/không rương K, có/không quest) |
| `clickIconDevilByCondition()` | Click icon theo điều kiện type + quest |
| `searchNpcDevil()` | Tìm NPC Devil bằng image search → trả về tọa độ (ByRef) |
| `clickToNpcDevil()` | Click chuột vào NPC Devil tại tọa độ tìm được |
| `clickNpcDevil()` | Logic click NPC + chọn Devil No + follow nếu fail |
| `clickPositionByDevilNo()` | Click vị trí Devil Square theo số (1-7) |
| `checkColorPopUpDevil()` | Kiểm tra popup chọn Devil đã mở bằng pixel color |
| `checkOpenPopupDevil()` | Kiểm tra popup Devil mở bằng pixel color (variant khác) |
| `handelWhenFinshDevilEvent()` | Xử lý UI sau khi event kết thúc |
| `actionWhenCantJoinDevil()` | Xử lý khi không vào được Devil (follow leader nếu cần) |
| `switchToMainChar()` | Loop qua account → chuyển về main char |

---

## Dependencies

### Include Chain
```
auto_devil.au3
├─ common_utils.au3         → init(), writeLog*, getProperty(), secondWait(), minuteWait(),
│                              getCurrentTime(), createTimeToTicks(), diffTime(), timeLeft(),
│                              waitToNextMinutes(), getJsonFromFile(), setJsonToFileFormat()
├─ game_utils.au3            → activeAndMoveWin(), switchOtherChar(), getMainNoByChar(),
│                              minisizeMain(), minisizeMainByChar(), check400LvlImage(),
│                              checkActiveAutoHome(), _MU_followLeader(), _MU_Start_AutoZ(),
│                              moveOtherMap(), startAutoPlus(), sendKeyF8(),
│                              followLeadThenStartAutoPlus(), checkAutoZAfterFollowLead(),
│                              switchToMainChar(), switchToMainCharItem(),
│                              checkActiveParentMain(), activeAndMoveWinByChar(),
│                              + tất cả devil functions ở bảng trên
├─ _ImageSearch_UDF.au3      → Image search cho NPC Devil, rương K, 400 lvl
└─ Date.au3                  → _DateAdd(), date functions
```

### Biến Global
- `$sCharNotJoinDevil` — Danh sách char không vào được Devil (string, phân cách @CRLF)
- `$timeStartProcess` — Bộ đếm số lần loop (reset log khi > 10)
- `$sFilePath` — Đường dẫn file log
- `$logFile` — File handle log
- `$jsonAccountActiveDevil` — Mảng account active (được reload mỗi lần vào event)

---

## Relevant Files

### Implementation
- [feature/auto_devil/auto_devil_auto_plus.au3](feature/auto_devil/auto_devil_auto_plus.au3) — File feature mới cho type auto_plus
- [feature/auto_devil/auto_devil.au3](feature/auto_devil/auto_devil.au3) — Flow cũ, giữ nguyên để không ảnh hưởng
- [utils/common_utils.au3](utils/common_utils.au3) — Bổ sung lọc dữ liệu theo type
- [utils/game_utils.au3](utils/game_utils.au3) — Các hàm game dùng lại

### Config
- [config/json/example/devil_config_example.json](config/json/example/devil_config_example.json) — Mẫu config Devil
- [config/json/position_config.json](config/json/position_config.json) — Tọa độ UI game (icon, NPC, popup)

### Media (Image Search)
- [media/image/devil/](media/image/devil/) — Ảnh NPC Devil, popup, rương K
- [media/image/common/](media/image/common/) — Ảnh 400 lvl, auto home

### Utils
- [utils/common_utils.au3](utils/common_utils.au3) — Hàm chung (log, time, config)
- [utils/game_utils.au3](utils/game_utils.au3) — Hàm game (cửa sổ, chuột, auto, devil)

---

## Lưu Ý Quan Trọng

1. **Xung đột với auto_rs**: Kiểm tra `ProcessExists("auto_rs.exe")` → Exit nếu có.
2. **Lọc type bắt buộc**: Chỉ lấy record `type = auto_plus` (record thiếu `type` bị loại).
3. **Mốc giờ**: Lùi 5 phút trong `calculateNextDevilEventTime()`, riêng 23h luôn chờ 23h55.
4. **Fast join**: Nếu có follow leader thì chờ 2 phút trước khi move/follow.
5. **Nhóm còn lại**: Chỉ xử lý ở phút 26 hoặc 50 với move map + start/stop auto plus.
6. **Switch main**: Sau từng nhóm xử lý xong thì loop lại để chuyển về main chính nếu `switch_other_main = true`.

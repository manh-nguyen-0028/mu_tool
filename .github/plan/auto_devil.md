# Plan: Auto Devil Event (auto_devil.au3)

## TL;DR
Tự động tham gia sự kiện Quỷ Vương (Devil Square) trong game MU Online. Tính giờ chờ → active cửa sổ game → kiểm tra 400 lvl → click icon Devil → tìm NPC → chọn Devil Square → chờ hết event → xử lý sau event (follow leader, chuyển map, switch main). Chạy while loop liên tục, tự tính thời gian event tiếp theo.

---

## Core Architecture

### Main Flow
```
start()
├─ Mở log file
├─ getArrayActiveDevil()                    [Load config, lọc active: true]
└─ processGoDevil()                         [While loop chính]
   └─ checkThenGoDevilEvent()
      ├─ calculateNextDevilEventTime()      [Tính giờ event tiếp theo]
      ├─ Nếu chưa tới giờ (diffTime > 0):
      │  ├─ Check auto_rs.exe → Exit nếu có [Tránh xung đột với auto reset]
      │  ├─ Sleep() đến giờ event
      │  ├─ processGoEventDevil()           [Vào event cho tất cả account]
      │  ├─ checkAccountsInDevil()          [Kiểm tra ai đã vào thành công]
      │  ├─ processFastJoinAccounts()       [Xử lý account fast join: move + follow]
      │  ├─ switchToMainChar()              [Chuyển về main char]
      │  └─ sleep26Min()                    [Chờ hết event → xử lý sau event]
      └─ Nếu đã qua giờ (diffTime <= 0):
         └─ waitToNextMinutes(58)           [Chờ ~1h đến event tiếp]
```

### Lịch Event Devil
```
calculateNextDevilEventTime($currentHour, $currentMin)
├─ 00h-02h → chờ đến 03h00
├─ 03h-05h → chờ đến 06h00
├─ 06h-10h, 12h-19h → chờ đến giờ kế tiếp (mỗi giờ 1 event)
├─ 11h, 20h-22h → event mỗi 30 phút
│  ├─ Phút < 30 → chờ đến xx:30
│  └─ Phút >= 30 → chờ đến (xx+1):00
└─ 23h → chờ đến 00h00 ngày kế tiếp
```

### processGoEventDevil() — Vào Event
```
processGoEventDevil()
├─ reloadArrayActive()                [Load lại config mới nhất]
├─ validateAmountDevil()              [Kiểm tra có account active không]
├─ getListFastMove()                  [Lọc account có is_fast_join = true]
└─ For each account active:
   ├─ Kiểm tra thời gian hợp lệ (phút 0-5 hoặc 30-35)
   ├─ activeAndMoveWin() / switchOtherChar()  [Active cửa sổ game]
   ├─ check400LvlImage()                      [Kiểm tra đủ 400 lvl]
   ├─ clickIconDevil()                        [Click icon Devil trên UI]
   ├─ searchNpcDevil()                        [Tìm NPC Devil bằng image search]
   ├─ Nếu tìm thấy NPC:
   │  ├─ clickToNpcDevil()                    [Click vào NPC]
   │  ├─ checkColorPopUpDevil()               [Kiểm tra popup chọn Devil]
   │  ├─ actionGoDevilSuccess()               [Chọn Devil No + bật Auto Z]
   │  └─ actionGoDevilFail()                  [Follow leader nếu cần]
   └─ minisizeMainByChar()                    [Ẩn cửa sổ]
```

### Xử Lý Sau Event
```
sleep26Min($aCharJoinDevil)
├─ Tính thời gian chờ đến phút 21 hoặc 51 (sau event ~26 phút)
├─ Sleep() chờ hết event
├─ Nếu giờ 20/21/22/11 (giờ cao điểm):
│  └─ For each char: handelWhenFinshDevilEvent() → minisize
└─ Nếu giờ khác:
   ├─ handleAfterDevilEvent()
   │  └─ For each char:
   │     ├─ isFastMove → skip (đã xử lý ở processFastJoinAccounts)
   │     ├─ charNotJoinDevil → skip
   │     ├─ Không cần follow leader → skip
   │     └─ Cần follow leader:
   │        ├─ activeAndMoveWin() / switchOtherChar()
   │        ├─ handelWhenFinshDevilEvent()   [Xử lý UI sau event]
   │        ├─ moveOtherMap()                [Chuyển map]
   │        ├─ _MU_followLeader(1)           [Follow leader]
   │        ├─ checkRuongK()                 [Kiểm tra rương K]
   │        └─ checkAutoZAfterFollowLead()   [Kiểm tra Auto Z]
   └─ switchToMainChar()                     [Chuyển về main char]
```

### checkAccountsInDevil() — Kiểm Tra Kết Quả
```
checkAccountsInDevil($jsonAccountActiveDevil)
└─ For each account:
   ├─ activeAndMoveWin() / switchOtherChar()
   ├─ checkActiveAutoHome()
   │  ├─ True → đã vào Devil thành công → thêm vào $aCharJoinDevil
   │  └─ False → không vào được → actionWhenCantJoinDevil()
   └─ switchToMainCharItem() nếu switch_other_main = true
```

### processFastJoinAccounts() — Xử Lý Fast Join
```
processFastJoinAccounts($aCharJoinDevil)
├─ Chờ đến phút 6 hoặc 36 (sau khi event bắt đầu ~6 phút)
└─ For each char có is_fast_join = true:
   ├─ activeAndMoveWin() / switchOtherChar()
   ├─ moveOtherMap()                    [Chuyển map khỏi Devil]
   ├─ followLeadThenStartAutoPlus()     [Follow leader + bật auto plus]
   └─ sendKeyF8()                       [Ẩn cửa sổ]
```

---

## Config Format

### devil_config.json
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
    "max_hour_go": 25               // Số giờ tối đa tham gia Devil
  }
]
```

---

## Hàm Chi Tiết

### Orchestration (auto_devil.au3)
| Hàm | Mô tả |
|------|--------|
| `start()` | Entry point: mở log → load config → processGoDevil() |
| `processGoDevil()` | While loop: reset log mỗi 10 lần → checkThenGoDevilEvent() |
| `checkThenGoDevilEvent()` | Tính giờ event → sleep → vào event → check kết quả → xử lý sau event |
| `calculateNextDevilEventTime()` | Tính giờ/phút event tiếp theo dựa trên giờ hiện tại |
| `validateAmountDevil()` | Kiểm tra có account active không |
| `getListFastMove()` | Lọc account có is_fast_join = true |
| `reloadArrayActive()` | Load lại config mới nhất |
| `processGoEventDevil()` | Loop qua các account → vào event Devil |
| `actionGoDevilSuccess()` | Chọn Devil No + bật Auto Z |
| `actionGoDevilFail()` | Follow leader khi không tìm thấy popup |
| `checkAccountsInDevil()` | Kiểm tra account nào đã vào Devil thành công |
| `processFastJoinAccounts()` | Xử lý account fast join: chờ 6 phút → move + follow |
| `sleep26Min()` | Chờ hết event (~26 phút) → xử lý sau event |
| `handleAfterDevilEvent()` | Xử lý sau event: follow leader, move map, check rương K |

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
- [feature/auto_devil/auto_devil.au3](feature/auto_devil/auto_devil.au3) — File chính (~510 dòng)
- [utils/game_utils.au3](utils/game_utils.au3) — Các hàm Devil trong game_utils

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

1. **Xung đột với auto_rs**: Kiểm tra `ProcessExists("auto_rs.exe")` → Exit nếu có, tránh 2 tool cùng điều khiển game
2. **Thời gian hợp lệ**: Chỉ vào Devil trong phút 0-5 hoặc 30-35, ngoài khoảng này → ExitLoop
3. **Fast join**: Account `is_fast_join = true` vào Devil chỉ 6 phút rồi ra, move map + follow leader → bỏ qua xử lý sau event
4. **Giờ cao điểm (20/21/22/11)**: Không follow leader, chỉ `handelWhenFinshDevilEvent()` + minisize
5. **Log rotation**: Reset file log mỗi 10 lần loop để tránh file quá lớn
6. **Image search**: Dùng `_ImageSearch` để tìm NPC Devil, kiểm tra 400 lvl, kiểm tra popup — phụ thuộc vào resolution game
7. **Switch main**: Sau event, chuyển về `main_char_name` nếu `switch_other_main = true`

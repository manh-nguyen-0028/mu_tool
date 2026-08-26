# Plan: Auto Devil + BC dựa vào Auto Plus (auto_devil_auto_plus.au3)

## TL;DR
Feature chạy event **Devil** và **Blood Castle (BC)** trong game, tận dụng cơ chế **Auto Plus** để đưa nhân vật vào event và train tự động. Nhóm account được lọc theo `type = auto_plus`. Luồng chính: tính giờ event → active/switch + minisize → xử lý fast join (move + follow) → tại mốc phút định sẵn thì move map + start/stop auto plus → switch về main chính. Chạy while loop liên tục.

> **Trạng thái hiện tại:** Phần **Devil** đã cài đặt (xem [auto_devil_auto_plus.au3](feature/auto_devil/auto_devil_auto_plus.au3)). Phần **BC (Blood Castle)** **CHƯA cài đặt** — cần bổ sung ở lần sau (xem mục [Việc cần làm lần sau](#việc-cần-làm-lần-sau)).

---

## Core Architecture (hiện tại — Devil)

### Main Flow
```
start()
├─ Mở log file (File_Log_AutoDevil_AutoPlus_.txt)
├─ mergeInfoAccountDevil("auto_plus")   [Lọc type = auto_plus sau merge]
└─ processGoDevil()                     [While loop chính]
   └─ checkThenGoDevilEvent()
      ├─ getTimeWaitNextEvent()         [Tính mốc event kế, lùi 5 phút]
      ├─ Nếu chưa tới giờ (diffTime >= 0):
      │  ├─ Check auto_rs.exe → Exit nếu có   [Tránh xung đột auto reset]
      │  ├─ Sleep() đến giờ event
      │  ├─ processGoEventDevil()        [active/switch + minisize]
      │  ├─ processFastJoinAccounts()    [Fast join: move + follow, chờ 2 phút nếu cần]
      │  └─ processRemainAccounts()      [Nhóm còn lại: mốc 26/50 → move + start/stop auto plus]
      └─ Nếu đã qua giờ:
         └─ minuteWait(5)               [Chờ 5 phút rồi loop lại tính mốc kế]
```

### Lịch Event (getTimeWaitNextEvent + isValidPreEventSlot)
```
Mốc :55  → hour == 2, 5, hoặc 6..23   (đã lùi 5 phút; gồm cả 23h → 23:55)
Mốc :25  → hour == 11, hoặc 19..22    (khung event 30 phút)
```

---

## Hàm Chi Tiết (auto_devil_auto_plus.au3)
| Hàm | Mô tả |
|------|--------|
| `start()` | Entry point: mở log → load config type=auto_plus → processGoDevil() |
| `processGoDevil()` | While loop: reset log mỗi 10 lần → checkThenGoDevilEvent() |
| `checkThenGoDevilEvent()` | Tính giờ → sleep → vào event → fast join → nhóm còn lại |
| `getTimeWaitNextEvent()` | Quét 1440 phút tìm mốc hợp lệ kế tiếp (đã lùi 5 phút) |
| `isValidPreEventSlot()` | Xác định phút :55 / :25 có phải mốc event không |
| `testgetTimeWaitNextEvent()` | Bộ test nhanh 10 case cho logic tính giờ |
| `reloadArrayActive()` | Reload config type=auto_plus mới nhất |
| `processGoEventDevil()` | Loop account: active/switch + minisize |
| `getFastJoinAccounts()` / `getRemainAccounts()` | Tách nhóm theo `is_fast_join` |
| `processFastJoinAccounts()` | Move + follow (chờ 2 phút nếu cần) → switch main |
| `waitToMinute26Or50()` | Chờ đến phút 26 hoặc 50 |
| `processRemainAccounts()` | Mốc 26/50: move map + start/stop auto plus → switch main |

---

## Config Format (record type = auto_plus)
```json
{
  "active": true,
  "char_name": "TenNhanVat",
  "is_fast_join": true,             // true = vào nhanh (move + follow)
  "is_need_follow_leader": true,    // cần follow leader → chờ 2 phút trước khi move
  "switch_other_main": true,        // switch về main chính sau khi xong
  "main_char_name": "TenMain",      // main char để switch về
  "type": "auto_plus"               // BẮT BUỘC — record thiếu type sẽ bị loại
}
```

---

## Việc cần làm lần sau

### 1. Bổ sung event BC (Blood Castle) dựa vào Auto Plus  🔴 CHƯA LÀM
Hiện chưa có hàm BC nào trong `game_utils.au3`. Cần thêm:
- [ ] Xác định **lịch giờ BC** và bổ sung mốc vào `isValidPreEventSlot()` (hoặc tách hàm riêng `isValidBcSlot()`).
- [ ] Thêm field config phân biệt loại event, ví dụ `"event": "devil" | "bc"` trong record `type = auto_plus`.
- [ ] Viết hàm `moveToBcMap($charName)` (tương tự `moveOtherMap()` nhưng tọa độ NPC/map BC).
- [ ] Viết hàm vào BC + start auto plus: tái sử dụng `startAutoPlus()` / `stopAutoPlus()`.
- [ ] Thêm ảnh image-search cho NPC/UI BC vào `media/image/` (thư mục mới `media/image/bc/`).
- [ ] Bổ sung tọa độ UI BC vào [config/json/position_config.json](config/json/position_config.json).
- [ ] Thêm nhánh xử lý BC trong `checkThenGoDevilEvent()` (hoặc tách `checkThenGoBcEvent()`).

### 2. Kích hoạt entry point  🔴 CHƯA LÀM
- [ ] File đang gọi `testgetTimeWaitNextEvent()` thay vì `start()` (dòng đầu). Đổi lại `start()` khi chạy thật.

### 3. Cải thiện / kiểm tra
- [ ] Rà lại mốc phút 26/50 của `processRemainAccounts()` có khớp thời điểm auto plus vào BC không.
- [ ] Kiểm tra xung đột khi vừa Devil vừa BC chạy cùng khung giờ.

---

## Dependencies

### Include Chain
```
auto_devil_auto_plus.au3
├─ common_utils.au3   → writeLog*, secondWait(), getCurrentTime(), createTimeToTicks(),
│                        diffTime(), timeLeft(), waitToNextMinutes(), getProperty()
├─ game_utils.au3     → mergeInfoAccountDevil(), activeAndMoveWin(), switchOtherChar(),
│                        getMainNoByChar(), minisizeMainByChar(), moveOtherMap(),
│                        _MU_followLeader(), startAutoPlus(), stopAutoPlus(),
│                        switchToMainChar(), switchToMainCharItem()
└─ Date.au3           → date functions
```

### Biến Global
- `$timeStartProcess` — Bộ đếm loop (reset log khi > 10)
- `$sFilePath` — Đường dẫn file log
- `$logFile` — File handle log
- `$jsonAccountActiveDevil` — Mảng account active (reload mỗi lần vào event)

---

## Relevant Files

### Implementation
- [feature/auto_devil/auto_devil_auto_plus.au3](feature/auto_devil/auto_devil_auto_plus.au3) — Feature Devil + (BC sắp thêm) dựa auto plus
- [feature/auto_devil/auto_devil.au3](feature/auto_devil/auto_devil.au3) — Flow Devil cũ, giữ nguyên
- [utils/game_utils.au3](utils/game_utils.au3) — Hàm game dùng chung (auto plus, move map, switch char)
- [utils/common_utils.au3](utils/common_utils.au3) — Hàm chung (log, time, config)

### Config
- [config/json/example/devil_config_example.json](config/json/example/devil_config_example.json) — Mẫu config Devil
- [config/json/position_config.json](config/json/position_config.json) — Tọa độ UI game (cần thêm mục BC)

### Media (Image Search)
- [media/image/devil/](media/image/devil/) — Ảnh NPC Devil, popup, rương K
- media/image/bc/ — 🔴 CHƯA CÓ — cần tạo cho BC

---

## Lưu Ý Quan Trọng
1. **Xung đột với auto_rs**: Kiểm tra `ProcessExists("auto_rs.exe")` → Exit nếu có.
2. **Lọc type bắt buộc**: Chỉ lấy record `type = auto_plus`.
3. **Mốc giờ Devil**: Lùi 5 phút; phút :55 (2,5,6..23) và :25 (11,19..22).
4. **Fast join**: Có follow leader thì chờ 2 phút trước khi move/follow.
5. **Nhóm còn lại**: Xử lý ở phút 26 hoặc 50 với move map + start/stop auto plus.
6. **Switch main**: Sau mỗi nhóm loop lại switch về main chính nếu `switch_other_main = true`.
7. **BC chưa cài đặt**: Toàn bộ mục [Việc cần làm lần sau](#việc-cần-làm-lần-sau) là phần còn thiếu.

# Plan: Auto Reset Web (auto_rs.au3)

## TL;DR
Tính năng auto reset nhân vật qua web. Hỗ trợ 4 loại type: **reset** (reset web + train lại level), **withdraw** (rút reset từ ngân hàng), **web_auto_plus** (reset web + stop/start auto plus), **auto_plus** (placeholder). Merge config từ nhiều nguồn → validate → login web → thực hiện reset/withdraw → quay lại game train level → cập nhật config.

---

## Core Architecture

### Main Flow
```
startAutoRs()
├─ mergeInfoAccountRs()                    [Gộp config tài khoản từ nhiều nguồn]
├─ Lọc account active → phân loại type (withdraw / reset)
├─ validAccountRs($aAccountActive)         [Validate: time, max_rs, type_rs, daily limit]
├─ checkThenCloseChrome() + SetupChrome()  [Khởi tạo WebDriver]
├─ sortArrayByProperty("user_name")        [Sắp xếp theo username để tối ưu login/logout]
└─ For each $aAccValidate
   ├─ type == "withdraw"       → withDrawRs()
   ├─ type == "reset"          → reset() → processReset()
   ├─ type == "web_auto_plus"  → resetWebAutoPlus() → processResetWebAutoPlus()
   ├─ type == "auto_plus"      → placeholder (chưa implement)
   └─ So sánh username hiện tại vs tiếp theo → logout nếu khác user
```

### Reset Flow (type = "reset")
```
reset($jAccountInfo)
├─ Nếu reset_online = false:
│  ├─ activeAndMoveWin()           [Active cửa sổ game]
│  ├─ switchOtherChar() nếu fail   [Chuyển nhân vật khác cùng account]
│  ├─ Chờ phút an toàn (>8, <52)   [Tránh reset lúc đổi giờ server]
│  └─ processReset()
└─ Nếu reset_online = true:
   └─ processReset()
```

### processReset() — Logic chính
```
processReset($jAccountInfo)
├─ extractAccountInfo()                          [JSON → Dictionary object]
├─ checkTimeInNight()                            [Kiểm tra thời gian đêm]
├─ login($sSession, username, password)          [Đăng nhập web]
├─ getLogReset() → getTimeReset/getRsCount/getCurrentlvl  [Lấy thông tin reset từ web]
├─ _ProcessRs_CheckTimeToReset()                 [Kiểm tra thời gian có thể reset]
├─ calculateRequiredLevelForReset()              [Tính level cần: 200 + rs*5, max 400]
├─ Nếu đủ level:
│  ├─ _ProcessRs_PrepareGameBeforeReset()        [Active game, handleBeforeReset, changeChar]
│  ├─ resetInWeb()                               [Thực hiện reset trên web]
│  ├─ _ProcessRs_UpdateAccountInfo()             [Cập nhật rs, time_rs, last_time_reset vào JSON]
│  └─ _ProcessRs_ReturnGameAfterReset()          [Quay lại game: returnChar, addPoint, train]
└─ Nếu không đủ level:
   └─ _ProcessRs_HandleNotEnoughLevel()          [Train thêm hoặc skip]
```

### Web Auto Plus Flow (type = "web_auto_plus")
```
resetWebAutoPlus($jAccountInfo)
├─ activeAndMoveWin()              [Active cửa sổ game]
├─ switchOtherChar() nếu fail      [Chuyển nhân vật khác cùng account]
├─ Chờ phút an toàn (>8, <52)      [Tránh reset lúc đổi giờ server]
└─ processResetWebAutoPlus()
   ├─ extractAccountInfo()                          [JSON → Dictionary object]
   ├─ checkTimeInNight()                            [Kiểm tra thời gian đêm]
   ├─ login($sSession, username, password)          [Đăng nhập web]
   ├─ getLogReset() → getTimeReset/getRsCount/getCurrentlvl  [Lấy thông tin reset từ web]
   ├─ _ProcessRs_CheckTimeToReset()                 [Kiểm tra thời gian có thể reset]
   ├─ calculateRequiredLevelForReset()              [Tính level cần: 200 + rs*5, max 400]
   ├─ Nếu đủ level:
   │  ├─ _ProcessRs_PrepareGameBeforeReset(False)   [Active game, handleBeforeReset, changeChar]
   │  ├─ resetInWeb()                               [Thực hiện reset trên web]
   │  ├─ _ProcessRs_UpdateAccountInfo()             [Cập nhật rs, time_rs, last_time_reset vào JSON]
   │  ├─ returnChar()                               [Quay lại game: chọn nhân vật]
   │  ├─ addPointInGame()                           [Cộng điểm stat]
   │  ├─ stopAutoPlus()                             [Tắt auto plus hiện tại]
   │  ├─ startAutoPlus()                            [Bật lại auto plus]
   │  └─ minisizeMain()                             [Ẩn cửa sổ game → hoàn thành]
   └─ Nếu không đủ level:
      └─ _ProcessRs_HandleNotEnoughLevel(False)     [Xử lý chưa đủ level]
```

### Withdraw Flow (type = "withdraw")
```
withDrawRs($jAccountInfo)
├─ login()                    [Đăng nhập web]
├─ checkIP()                  [Kiểm tra IP hợp lệ]
│  └─ Không hợp lệ → cập nhật time +24h → Return
├─ getLogReset() → kiểm tra thời gian reset
├─ navigateUrl("withdraw_confirm")  [Truy cập URL rút reset]
├─ Nếu timeout (IP sai chủ):
│  └─ Click confirm → ghi log lỗi
├─ Nếu thành công:
│  ├─ submitButton() + confirm     [Submit rút reset]
│  ├─ Nếu reset_online = false:
│  │  ├─ changeThenReturnChar()    [Đổi nhân vật trong game]
│  │  └─ switchToMainCharItem()    [Quay về main char nếu cần]
│  └─ Cập nhật JSON config (time_rs, last_time_reset, buff nếu sang ngày mới)
```

---

## Validation Pipeline (validAccountRs)

Mỗi account qua 6 bước kiểm tra, fail bất kỳ → ContinueLoop:

| # | Hàm | Mô tả |
|---|------|--------|
| 1 | `_ValidRs_IsInvalidLastTime` | last_time_reset == 0 hoặc length == 1 → invalid |
| 2 | `_ValidRs_IsNotTimeToReset` | currentTime < lastTimeRs + hourPerRs → chưa đến giờ |
| 3 | `_ValidRs_IsMaxResetReached` | rs >= 2000 hoặc rs >= max_rs → đã max |
| 4 | `_ValidRs_IsTypeRsTimeNotReached` | Kiểm tra theo type_rs: Zen(0)/VIP(1)/PO(2) với thời gian chờ khác nhau |
| 5 | `_ValidRs_IsDailyLimitExceeded` | time_rs >= limit trong cùng ngày → vượt giới hạn ngày |
| 6 | `_ValidRs_AdjustTypeRsIfOverDailyLimit` | Nếu vượt max VIP/PO trong ngày → chuyển về Zen(0) |

---

## Hàm Hỗ Trợ

### Level Check
| Hàm | Mô tả |
|------|--------|
| `checkLvlInWeb()` | Kiểm tra level qua web (navigateUrl → read span.t-level), loop tối đa 68 lần |
| `checkLvl400WhenRs()` | Kiểm tra level 400 bằng image search trong game (check400LvlImage) |
| `checkLvlInWebByChangeChar()` | Kiểm tra level qua web bằng cách đổi nhân vật tạm để cập nhật |
| `calculateRequiredLevelForReset()` | rs < 50: lvl = 200 + rs*5 (max 400); rs >= 50: lvl = 400 |

### Game Actions
| Hàm | Mô tả |
|------|--------|
| `addPointInGame()` | Mở bảng C → click cộng điểm → xác nhận → đóng bảng C |
| `clickButtonAddPoint()` | Click button cộng điểm + xác nhận (tọa độ từ position_config) |
| `goToSportLvl1()` | Click vào vị trí sport 1 trên bản đồ Lorencia |
| `firstActionAfterRs()` | Sau reset: sendKeyHome → sendKeyTab (mở map) → goToSportLvl1 → sendKeyTab (đóng map) |
| `processResetNomal()` | Flow train sau reset: firstAction → chờ 1p → goMapLvl/goMapArena → checkLvl → followLeader → autoPlus |
| `activeTrainInGame()` | Stop auto plus → start auto plus → switch server |
| `resetWebAutoPlus()` | Entry point cho type web_auto_plus: pre-reset game logic giống reset() Not $resetOnline |
| `processResetWebAutoPlus()` | Reset web → quay game → addPoint → stop/start autoPlus → minisize → done |
| `actionNextResetNotEnoughLevel()` | Khi chưa đủ level: active game → goMapArena → checkLvl → moveOtherMap → followLeader |
| `isMovableUnderLevel20()` | Nếu lvl < 20: di chuyển bằng web đến Lorencia (220, 144) |

### Account Info
| Hàm | Mô tả |
|------|--------|
| `extractAccountInfo()` | Chuyển JSON object → Scripting.Dictionary (22 fields) |
| `updateResetTimeIfNotReached()` | Ghi log + cập nhật last_time_reset khi chưa đến giờ |

---

## Config Format

### account_reset.json (input)
```json
[
  {
    "active": true,
    "type": "reset",           // "reset" | "withdraw" | "web_auto_plus" | "auto_plus"
    "char_name": "TenNhanVat",
    "type_rs": 1,              // 0=Zen, 1=VIP, 2=PO
    "lvl_move": 400,
    "reset_online": true,      // true=chỉ reset web, false=reset web + điều khiển game
    "hour_per_reset": 1,
    "is_buff": true,
    "server_number": 8,
    "train_in_game": true,
    "position_leader": 1,
    "on_auto_plus": false,
    "swith_server": false
  }
]
```

### auto_rs_update_info.json (tracking state)
```json
[
  {
    "char_name": "TenNhanVat",
    "rs": 500,
    "max_rs": 2000,
    "time_rs": 1,
    "limit": 5,
    "time_in_night": 3,
    "is_main_character": true,
    "main_char_name": "TenNhanVat",
    "last_time_reset": "2024/08/06 06:40:00",
    "password": "***",
    "postion_move_x": 100,
    "postion_move_y": 100
  }
]
```

---

## Dependencies

### Include Chain
```
auto_rs.au3
├─ common_utils.au3      → init(), writeLog*, getProperty(), secondWait(), minuteWait(), mergeInfoAccountRs()
├─ web_mu_utils.au3       → login(), logout(), resetInWeb(), getLogReset(), checkIP(), navigateUrl(), findAndClick(), submitButton(), goPageBuffChar(), moveToPostionInWeb(), combineUrl()
├─ game_utils.au3         → activeAndMoveWin(), switchOtherChar(), changeChar(), returnChar(), returnServer(), sendKey*, goMapArena(), goMapLvl(), _MU_followLeader(), startAutoPlus(), stopAutoPlus(), checkActiveAutoHome(), check400LvlImage(), handleBeforeReset(), switchSvInGame(), handleIsNotMainChar(), minisizeMain(), changeThenReturnChar(), switchToMainCharItem()
├─ au3WebDriver            → _WD_DeleteSession(), _WD_Shutdown(), SetupChrome()
└─ json_utils.au3          → _JSONGet(), _JSONSet(), getPropertyJson(), getJsonFromFile(), setJsonToFileFormat()
```

### Position Config Keys (button.*)
- `button.bang_c.add_point_x/y` — Tọa độ nút cộng điểm
- `button.bang_c.add_point_confirm_x/y` — Tọa độ nút xác nhận cộng điểm
- `button.loren_sport1.x/y` — Tọa độ sport 1 trên bản đồ
- `common.auto.time_wait_rs_vip` — Thời gian chờ RS VIP (mặc định 20 phút)
- `common.auto.time_wait_rs_zen_rs_50` — Thời gian chờ RS Zen khi rs < 50 (mặc định 30 phút)
- `common.auto.max_rs_vip` — Số lần RS VIP tối đa/ngày (mặc định 10)
- `common.auto.max_rs_po` — Số lần RS PO tối đa/ngày (mặc định 10)

---

## Relevant Files

### Implementation
- [feature/auto_reset/auto_rs.au3](feature/auto_reset/auto_rs.au3) — File chính (~910 dòng, ~35 hàm)
- [feature/auto_reset/withdraw_rs.au3](feature/auto_reset/withdraw_rs.au3) — File withdraw riêng (legacy, chức năng đã gộp vào auto_rs)

### Config
- [config/json/account_reset.json](config/json/account_reset.json) — Config tài khoản reset
- [config/json/example/account_reset_example.json](config/json/example/account_reset_example.json) — Mẫu config
- [config/json/example/auto_rs_update_info_exam.json](config/json/example/auto_rs_update_info_exam.json) — Mẫu tracking state
- [config/json/position_config.json](config/json/position_config.json) — Tọa độ UI game

### Utils
- [utils/common_utils.au3](utils/common_utils.au3) — Hàm dùng chung (init, log, config, merge)
- [utils/web_mu_utils.au3](utils/web_mu_utils.au3) — Thao tác web (login, reset, captcha, navigate)
- [utils/game_utils.au3](utils/game_utils.au3) — Thao tác game (cửa sổ, chuột, phím, map, auto plus)

---

## Lưu Ý Quan Trọng

1. **Biến global dùng xuyên suốt**: `$sSession`, `$logFile`, `$baseMuUrl`, `$jsonPathRoot`, `$autoRsUpdateInfoFileName` — được khởi tạo trong `startAutoRs()` hoặc `init()`
2. **Tối ưu login/logout**: Sắp xếp account theo `user_name` → chỉ logout khi user tiếp theo khác user hiện tại
3. **Thời gian an toàn**: Reset tránh phút 52-8 (đổi giờ server) — chỉ áp dụng cho `reset_online = false`
4. **Level tính theo reset count**: rs < 50 → lvl = 200 + rs*5; rs >= 50 → lvl = 400
5. **Buff ngày mới**: Tự động buff khi phát hiện ngày reset cuối khác ngày hiện tại (cho cả withdraw và reset)
6. **web_auto_plus**: Reset qua web, quay game chỉ stop/start auto plus rồi ẩn — không train level, không follow leader, không chuyển map
7. **Type chưa implement**: `auto_plus` hiện chỉ ghi log, chưa có logic xử lý

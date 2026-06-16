# Plan: Game Utilities (game_utils.au3)

## TL;DR
Module utility trung tâm cho tất cả thao tác trong cửa sổ game MU Online. Cung cấp ~80 hàm chia thành 10 nhóm: quản lý cửa sổ, switch nhân vật, event Devil, Auto Home/Z, Auto Plus, di chuyển map/server, kiểm tra level/buff, xử lý sau event/reset, gửi phím, và tiện ích. Được include bởi hầu hết các feature file trong project.

---

## Core Architecture

### Nhóm Hàm

#### 1. Quản Lý Cửa Sổ Game
```
activeAndMoveWin($mainName)
├─ WinList() tìm title chính xác
├─ WinSetState() → WinActivate() → WinMove(0,0)
├─ resizeGame()                    [Resize về 800x600]
└─ Return True/False

activeAndMoveWinByChar($charName)
└─ getMainNoByChar($charName) → activeAndMoveWin()

checkActiveWin($mainName)
└─ WinList() so sánh title tuyệt đối → Return True/False

resizeGame($GAME_TITLE)
├─ WinWait($GAME_TITLE, "", 3)     [timeout 3s]
├─ WinGetHandle()
└─ WinMove() resize về 800x600

closeWinByExactTitle($gameTitle, $timeoutSec = 10)
├─ WinExists() check
├─ WinClose()
└─ Retry loop tối đa $timeoutSec giây
```

#### 2. Switch Nhân Vật
```
switchOtherChar($currentChar)
├─ checkActiveOtherChar()          [Tìm nhân vật cùng tài khoản đang active]
│  └─ getOtherChar() → StringSplit("|") → checkActiveWinByChar() từng char
├─ activeAndMoveWinByChar($charFound)
├─ sendEnterThenClickCenter()
├─ clickOtherChar()                [Click icon switch + chọn nhân vật]
│  └─ clickOtherCharCommon()
│     ├─ Click icon switch char
│     ├─ searchNvpNotActiveAutoZ() → click vị trí tương ứng
│     └─ Fallback: click first char → close popup
└─ While loop check active tối đa 5 lần

switchToMainChar($jsonArray)
└─ For each account có switch_other_main = true:
   └─ switchToMainCharItem($charName, $mainCharName)
      ├─ Nếu main cha đã active → minisize → Return
      └─ activeAndMoveWin($mainNo) → switchOtherChar($mainCharName)

checkActiveParentMain($charName)
├─ getOtherChar($charName)         [⚠️ BUG: trả về "char1|char2|char3", dùng như tên char]
└─ activeAndMoveWinByChar($parentCharName)
```

#### 3. Event Devil
```
getArrayActiveDevil()
├─ Load config devil từ file
└─ Lọc: active = true AND max_hour_go >= @HOUR AND không phải peak hour

clickIconDevil($charName, $checkRuongK, $isHaveQuest)
├─ Xác định typeCheck (1/2/3) theo haveIp, haveAddPoint
└─ clickIconDevilByCondition() → click tọa độ từ config

searchNpcDevil($charName, $checkRuongK, $devilNo, $isHaveQuest, ByRef $npcX, ByRef $npcY)
├─ While loop tối đa 5 lần:
│  ├─ npcSearchColorResult()       [PixelSearch màu 0xB9AA95 trong vùng config]
│  └─ Nếu không thấy → clickIconDevil() lại
└─ Return True/False, cập nhật $npcX/$npcY

checkColorPopUpDevil()             [Hàm canonical]
└─ PixelSearch(0,0,250,460, 0x9A3C00, 4)

checkOpenPopupDevil()              [Wrapper]
└─ Return checkColorPopUpDevil()

clickToNpcDevil($npcX, $npcY)
└─ + deviation từ config → mouseClickDelayAlt()

clickPositionByDevilNo($devilNo)
└─ Đọc tọa độ "button.event_devil_icon.devil_{no}_x/y" → click
```

#### 4. Auto Home / Auto Z
```
checkActiveAutoHome()
└─ checkActiveAutoHomeCommon(active_auto_home.bmp, vùng từ config)

checkActiveAutoHomePlus()
└─ checkActiveAutoHomeCommon(active_auto_home_plus.bmp, vùng plus từ config)

checkActiveAutoHomeCommon($pathImage, $imageTolerance, $x, $y, $x1, $y1)
├─ secondWait(5)
├─ _ImageSearch_Area()
└─ Return True/False

searchNvpNotActiveAutoZ()
├─ secondWait(5)
├─ Đọc vùng từ "common.screen_800_600.*"   [đã sửa từ hardcode]
└─ _ImageSearch_Area(nvp_not_active_auto_z.bmp)

checkAutoZAfterFollowLead($needCheck = False)
├─ Đọc "time_wait_after_follow" từ devil config (default 10s nếu không có/0)
└─ Nếu $needCheck = True:
   ├─ secondWait($timeWaitAfterFollow)
   └─ While loop check checkActiveAutoHome() tối đa 2 lần, mỗi lần wait $timeWaitAfterFollow
```

#### 5. Auto Plus
```
startAutoPlus()
├─ Click button train_in_game
└─ Click button start

startAutoPlusWithReset()
├─ Click button train_in_game
├─ Click checkbox_reset    [tick on]
└─ Click button start

startAutoPlusWithoutReset()
├─ Click button train_in_game
├─ Click checkbox_reset    [toggle off]
└─ Click button start

stopAutoPlus()
└─ Click button_stop

followLeadThenStartAutoPlus($charName, $onAutoPlus)
├─ clickCenterChar()
├─ _MU_followLeader(1)
└─ Nếu $onAutoPlus: startAutoPlus()
```

#### 6. Di Chuyển Map / Server
```
moveOtherMap($charName)
├─ clickCenterChar()
├─ activeAndMoveWin() / switchOtherChar()
├─ sendKeyM() → click tọa độ other_map từ config
└─ secondWait(5)

goMapArena($rsCount)
├─ Chờ nếu phút 0-5 hoặc 30-35
├─ clickEventIcon() → clickEventStadium()
└─ goSportStadium(1/2/3) theo rsCount

goMapLvl()
└─ clickEventIcon() → clickEventLvl() → goCenterMapLvl() → sendKeyHome()

returnServer($serverNumber)
├─ writeLogMethodStart()
├─ activeAndMoveWin($titleGameMain)
├─ Click button mở danh sách server
├─ _clickServerChoice($serverNumber) → fallback server 1
└─ writeLogMethodEnd()

_clickServerChoice($serverNumber)
└─ Đọc tọa độ "button.change_server.choise_sv_{n}_x/y" → click
```

#### 7. Kiểm Tra Level / Buff / Image
```
checkLvl400($mainNo)
├─ Đọc pixel x/y/color từ config
├─ checkPixelColor() lần đầu
└─ Retry tối đa 5 lần nếu chưa thấy

check400LvlImage()
└─ searchImageFullScreenMu(400lv.bmp)

searchImageFullScreenMu($pathImage)
├─ Đọc vùng từ "common.screen_800_600.*"
└─ _ImageSearch_Area() tolerance 100

checkAutoOnBuff() / checkAutoOffBuff()
└─ searchImageFullScreenMu(check_on/off_buff.bmp)
```

#### 8. Reset / Đổi Nhân Vật
```
changeThenReturnChar($charName)
├─ checkActiveWinByChar() / switchOtherChar()
├─ changeChar()            [ESC + click chọn nhân vật khác, tối đa 3 lần]
└─ returnChar()            [Chờ title game main → Enter → chờ title nhân vật]

changeChar($mainNo)
└─ For 1→3: sendKeyEsc() → click button_change_char → check Not activeAndMoveWin()

returnChar($mainNo)
└─ While Not active AND timeCheck <= 5:
   └─ activeAndMoveWin($titleGameMain) → sendKeyEnter() → check active
```

---

## Bugs Đã Xác Định

| # | Hàm | Mô Tả | Mức Độ |
|---|-----|-------|--------|
| 1 | `checkActiveParentMain` | `getOtherChar()` trả về `"char1\|char2"` nhưng dùng nguyên chuỗi như tên nhân vật → `activeAndMoveWinByChar` không tìm được cửa sổ | **Critical** |
| 2 | `checkOpenDevil` | Luôn `Return True` bất kể kết quả pixel check — không dùng được | **High** |
| 3 | `handelWhenFinshDevilEvent` | Typo tên hàm (`handel`/`Finsh`) | Low |

---

## Fixes Đã Thực Hiện

| Hàm | Thay đổi | Ngày |
|-----|---------|------|
| `resizeGame` | `WinWait` thêm timeout 3s: `WinWait($GAME_TITLE, "", 3)` | 2026-06-22 |
| `checkOpenPopupDevil` | Đổi thành wrapper: `Return checkColorPopUpDevil()` (xóa duplicate) | 2026-06-22 |
| `searchNvpNotActiveAutoZ` | Đọc vùng search từ `common.screen_800_600.*` thay vì hardcode (0,0,800,600) | 2026-06-22 |
| `checkAutoZAfterFollowLead` | Đọc wait time từ `time_wait_after_follow` trong devil config thay vì hardcode 10s | 2026-06-22 |

---

## Dependencies

### Được include bởi
```
feature/auto_devil/auto_devil.au3
feature/auto_reset/auto_reset_online.au3
feature/auto_reset/auto_rs.au3
feature/on_off_buff_exp/on_off_buff_exp.au3
feature/auto_buff/auto_buff.au3
(và các feature khác)
```

### game_utils.au3 include
```
game_utils.au3
├─ common_utils.au3          → writeLog*, secondWait(), getMainNoByChar(), getOtherChar(),
│                               minisizeMain(), minisizeMainByChar(), getProperty(),
│                               sendKeyDelay(), _MU_MouseClick_Delay(), mouseClickDelayShift(),
│                               mouseClickDelayAlt(), _MU_ControlClick_Delay(), getJsonFromFile()
├─ _ImageSearch_UDF.au3      → _ImageSearch_Area()
├─ json_utils.au3            → _JSONGet(), _JSONSet()
└─ AutoIt built-ins: Date.au3, Array.au3, GUIConstantsEx.au3, WinAPI.au3
```

### Config Keys (position_config.json)
| Key Prefix | Dùng cho |
|------------|---------|
| `button.follow_leader.*` | Tọa độ follow leader |
| `button.check_lvl_400.*` | Pixel màu kiểm tra 400 lvl |
| `button.event_devil.*` | Tọa độ NPC, popup devil |
| `button.event_devil_icon.*` | Tọa độ icon Devil và nút chọn số |
| `button.switch_char.*` | Tọa độ switch nhân vật |
| `button.npc_search.*` | Vùng tìm NPC, deviation |
| `button.move.*` | Tọa độ chuyển map |
| `button.change_server.*` | Tọa độ chọn server |
| `button.train_in_game.*` | Tọa độ Auto Plus |
| `button.check_active_auto_home.*` | Vùng image search auto home |
| `common.screen_800_600.*` | Vùng full screen MU |
| `common.image_search.*` | Tolerance image search |

---

## Relevant Files

### Implementation
- [utils/game_utils.au3](utils/game_utils.au3) — File chính (~870 dòng)
- [utils/common_utils.au3](utils/common_utils.au3) — Hàm chung được game_utils gọi

### Config
- [config/json/position_config.json](config/json/position_config.json) — Tất cả tọa độ UI
- [config/text/char_in_account.txt](config/text/char_in_account.txt) — Mapping nhân vật cùng tài khoản

### Media
- [media/image/common/](media/image/common/) — active_auto_home.bmp, 400lv.bmp, nvp_not_active_auto_z.bmp, check_on/off_buff.bmp
- [media/image/devil/](media/image/devil/) — ruong_k.bmp

---

## Backlog Cần Xử Lý

- [ ] **Fix `checkActiveParentMain`** — parse `getOtherChar()` đúng: tách chuỗi `|` lấy phần tử đầu tiên, hoặc dùng `checkActiveOtherChar()` thay thế
- [ ] **Fix `checkOpenDevil`** — implement logic pixel check thực sự, bỏ `Return True` cứng
- [ ] **Rename `handelWhenFinshDevilEvent`** → `handleWhenFinishDevilEvent` (kiểm tra call sites trước)

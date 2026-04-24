---
name: game-feature
description: 'Tạo hoặc sửa tính năng tự động hóa IN-GAME (auto plus, reset online, devil, switch char, buff, train...). USE FOR: thao tác cửa sổ game, chuột/phím trong game, kiểm tra trạng thái pixel/image, điều khiển Auto Plus, chuyển nhân vật. DO NOT USE FOR: thao tác web (reset web, đăng nhập web, captcha).'
---

# Game Feature Development

## When to Use
- Tạo tính năng mới thao tác trực tiếp trong cửa sổ game MU Online
- Sửa/cải tiến logic tự động hóa in-game (auto plus, devil, buff, train, switch char...)
- Thêm hàm tiện ích liên quan đến game vào `game_utils.au3`

## Rules
- Các thao tác game (chuột, phím, kiểm tra pixel, image search, switch char, auto plus...) **PHẢI** gọi qua `utils/game_utils.au3`, KHÔNG gọi trực tiếp trong file feature
- File feature chỉ chứa logic riêng của feature đó (load config, loop, điều kiện, gọi hàm game_utils)
- Các hàm tiện ích chung (logging, file I/O, JSON, thời gian) gọi qua `utils/common_utils.au3`
- Tọa độ pixel đọc từ JSON config (`position_config.json`), KHÔNG hardcode
- Hàm mới trong `game_utils.au3` tổ chức theo nhóm chức năng:
  - Nhóm kiểm tra trạng thái game (checkActiveWin, checkLvl400, checkPixelColor...)
  - Nhóm thao tác chuột/phím (_MU_MouseClick_Delay, _MU_ControlClick_Delay...)
  - Nhóm Auto Plus (startAutoPlus, stopAutoPlus, startAutoPlusWithReset...)
  - Nhóm chuyển nhân vật (switchOtherChar, checkActiveOtherChar, switchSvInGame...)
  - Nhóm cửa sổ (activeAndMoveWin, minisizeMain, resizeGame...)

## Feature File Pattern
```autoit
; feature/ten_tinh_nang/ten_tinh_nang.au3
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"

; Entry point
Func start()
    $sFilePath = $outputPathRoot & "File_Log_TenTinhNang.txt"
    $logFile = FileOpen($sFilePath, $iLogOverwrite)
    
    ; Load config
    ; While loop + processFunction()
    
    FileClose($logFile)
    Return True
EndFunc

; Main processing
Func processFunction()
    ; Load active items from config
    ; For each item:
    ;   1. Check conditions (time, window, etc.)
    ;   2. activeAndMoveWinByChar($charName)
    ;   3. Execute game actions via game_utils functions
    ;   4. minisizeMain($mainNo)
    ;   5. Update config if needed
EndFunc
```

## Available Game Utils Functions
- `checkActiveWin($mainName)` — kiểm tra cửa sổ game tồn tại
- `checkActiveWinByChar($charName)` — kiểm tra cửa sổ theo tên nhân vật
- `activeAndMoveWin($mainName)` — activate + move window về (0,0)
- `activeAndMoveWinByChar($charName)` — wrapper theo tên nhân vật
- `minisizeMain($mainNo)` — ẩn cửa sổ game
- `getMainNoByChar($charName)` — tạo title window từ tên nhân vật
- `checkActiveOtherChar($currentChar)` — tìm nhân vật khác cùng tài khoản
- `switchOtherChar($currentChar)` — chuyển sang nhân vật khác cùng account
- `startAutoPlus()` — bật Auto Plus training
- `stopAutoPlus()` — tắt Auto Plus training
- `checkLvl400()` / `check400LvlImage()` — kiểm tra level 400
- `checkPixelColor($x, $y, $color)` — kiểm tra màu pixel
- `_MU_MouseClick_Delay($x, $y)` — click chuột có delay
- `sendKeyF8()` — gửi phím F8

## Common Utils Functions (thường dùng)
- `init()` — khởi tạo, load config
- `getJsonFromFile($filePath)` — đọc JSON config
- `setJsonToFileFormat($filePath, $jsonData)` — ghi JSON config
- `_JSONGet($json, "dot.notation.key")` — đọc giá trị JSON
- `_JSONSet($value, $json, "dot.notation.key")` — ghi giá trị JSON
- `writeLog($text)` / `writeLogFile($logFile, $text)` — ghi log
- `writeLogMethodStart($name)` / `writeLogMethodEnd($name)` — log vào/ra hàm
- `secondWait($seconds)` — delay có log
- `getOtherChar($currentChar)` — tìm nhân vật cùng tài khoản từ file text
- `addHour($time, $amount)` — cộng giờ vào thời gian

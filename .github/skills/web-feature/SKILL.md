---
name: web-feature
description: 'Tạo hoặc sửa tính năng tự động hóa WEB MU Online (reset web, đăng nhập web, captcha, di chuyển web, buff web...). USE FOR: thao tác qua WebDriver/Selenium, đăng nhập web game, giải captcha, reset nhân vật trên web, di chuyển nhân vật trên bản đồ web. DO NOT USE FOR: thao tác trực tiếp trong cửa sổ game (dùng game-feature skill).'
---

# Web Feature Development

## When to Use
- Tạo tính năng mới thao tác qua web MU Online (WebDriver/Selenium)
- Sửa/cải tiến logic tự động hóa web (reset web, move web, buff web, đăng nhập web...)
- Thêm hàm tiện ích liên quan đến web vào `web_mu_utils.au3`

## Rules
- Các thao tác WebDriver/Selenium **PHẢI** gọi qua `utils/web_mu_utils.au3`, KHÔNG gọi trực tiếp trong file feature
- File feature chỉ chứa logic riêng của feature đó (load config, loop, điều kiện, gọi hàm web_mu_utils)
- Các hàm tiện ích chung (logging, file I/O, JSON, thời gian) gọi qua `utils/common_utils.au3`
- WebDriver config (driver path, profile path, browser options) đọc từ `position_config.json`
- Hàm mới trong `web_mu_utils.au3` tổ chức theo nhóm chức năng:
  - Nhóm WebDriver (khởi tạo session, đóng session, navigate...)
  - Nhóm đăng nhập web (login, captcha, cookie...)
  - Nhóm reset web (reset nhân vật, chọn server, chọn nhân vật...)
  - Nhóm di chuyển web (move char, chọn map, chọn tọa độ...)
  - Nhóm buff web (bật/tắt buff EXP...)

## Feature File Pattern
```autoit
; feature/ten_tinh_nang/ten_tinh_nang.au3
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"

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
    ;   1. Check conditions (time, account, etc.)
    ;   2. Open WebDriver session via web_mu_utils
    ;   3. Login web if needed
    ;   4. Execute web actions via web_mu_utils functions
    ;   5. Close session
    ;   6. Update config if needed
EndFunc
```

## Available Web Utils Functions
- WebDriver session: khởi tạo/đóng browser session (Chrome, Firefox, Edge)
- Đăng nhập web: login web game, xử lý captcha (Azcaptcha)
- Reset web: reset nhân vật trên trang web MU
- Di chuyển web: move nhân vật đến map/tọa độ chỉ định
- Buff web: bật/tắt auto buff EXP trên web

## External Services
- **Azcaptcha** — giải captcha tự động (API key trong config)
- **MU Online Web** — `https://hn.gamethuvn.net/` (reset, move, buff...)
- **WebDriver** — Chrome/Firefox/Edge driver trong `driver/`

## Common Utils Functions (thường dùng)
- `init()` — khởi tạo, load config
- `getJsonFromFile($filePath)` — đọc JSON config
- `setJsonToFileFormat($filePath, $jsonData)` — ghi JSON config
- `_JSONGet($json, "dot.notation.key")` — đọc giá trị JSON
- `_JSONSet($value, $json, "dot.notation.key")` — ghi giá trị JSON
- `writeLog($text)` / `writeLogFile($logFile, $text)` — ghi log
- `writeLogMethodStart($name)` / `writeLogMethodEnd($name)` — log vào/ra hàm
- `secondWait($seconds)` — delay có log
- `mergeInfoAccountRs()` — gộp thông tin tài khoản reset từ nhiều nguồn

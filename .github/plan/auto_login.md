# Plan: Xây Dựng Tính Năng Login Game (Từ Đầu)

## TL;DR
Xây dựng auto login game từ đầu theo 12 bước cụ thể. Mở game → login → chọn server → chọn character → kiểm tra character đúng không (qua `char_in_account.txt`) → F8 nếu sai → ghi report. Tái sử dụng hàm từ `game_utils.au3` và `common_utils.au3`.

---

## Core Architecture

### Login Flow
`
processAutoLogin()
└─ For each account (active: true)
   └─ processLogin(username, password, charName, serverNo)
      ├─ runGameExe()                  [Step 1: Mở game]
      ├─ clickButtonStart()             [Step 2: Click button start]
      ├─ activeAndMoveWin()      [Step 3: Active + move window - game_utils]
      ├─ clickAddAccount()              [Step 4: Click add account]
      ├─ inputCredentials()             [Step 5: Nhập user/pass]
      ├─ confirmLogin()                 [Step 6: Click confirm/first account]
      ├─ waitLoadUser()                 [Step 7: Chờ load user]
      ├─ selectServer()                 [Step 8: returnServer() - game_utils]
      ├─ selectCharacter()              [Step 9: returnChar() - game_utils]
      ├─ verifyCharacterLoaded()        [Step 10: Check char đúng (qua char_in_account.txt)]
      ├─ handleWrongCharacter()         [Step 11: F8 + retry nếu char sai]
      └─ writeLoginReport()             [Step 12: Ghi report]
`

### Helper Functions
- `init()` — Load config, position_config, account login config  - common_utils
- `getLoginProperty()` — Lấy tọa độ từ config (button.login.*)
- `getServerNumber()` — Lấy server number từ account config (default: 1)
- `getCharInAccount()` — Parse char_in_account.txt → danh sách char cùng account

---

## Steps

### Phase 1: Helper Functions (4 hàm)
1. `init()` — Load config từ JSON files
2. `getLoginProperty()` — Get tọa độ button từ button.login section
3. `getServerNumber()` — Extract server_no from account config
4. `getCharInAccount()` — Parse char_in_account.txt để tìm danh sách char cùng account

### Phase 2: Main Loop & Login Orchestration (2 hàm)
5. `processAutoLogin()` — Loop qua active accounts, gọi processLogin() cho mỗi
6. `processLogin(, , , )` — Orchestrate 12 bước:
   - Gọi từng step function (runGameExe → clickButtonStart → ... → writeLoginReport)
   - Handle retry logic nếu character sai

### Phase 3: Login Steps (6 hàm)
7. `runGameExe()` — Step 1: Mở game exe từ common.game.exe_path
8. `clickButtonStart()` — Step 2: Click vị trí button_start_x/y
9. `activeAndMoveGameWindow()` — Step 3: Active + move launcher window (dùng activeAndMoveWin())
10. `clickAddAccount()` — Step 4: Click button_add_account_x/y
11. `inputCredentials(, )` — Step 5: Click username → input → click password → input
12. `confirmLogin()` — Step 6: Click button confirm hoặc first_account_x/y

### Phase 4: Server/Character Selection & Verification (5 hàm)
13. `waitLoadUser()` — Step 7: Chờ X giây (wait_load_user_sec, default 5s)
14. `selectServer()` — Step 8: Gọi returnServer() từ game_utils
15. `selectCharacter()` — Step 9: Gọi returnChar() để chọn character
16. `verifyCharacterLoaded()` — Step 10:
    - Lấy danh sách char cùng account qua getCharInAccount()
    - So sánh với character active (window title)
    - Return: True/False
17. `handleWrongCharacter(, , , )` — Step 11:
    - Nếu character SAI → sendKeyF8() → chờ 2-3s → retry processLogin() (1 lần)
    - Nếu lần 2 vẫn SAI → return False, ghi log error

### Phase 5: Report & Entry Point (3 hàm)
18. `writeLoginReport(, , , , )` — Step 12:
    - Ghi file output/report_user_login.txt
    - Format: YYYY-MM-DD HH:MM:SS | username | char_name | status | server | channel
    - Status: success | retry_success | failed | timeout | wrong_password
19. `start()` — Entry point: init() → open log → processAutoLogin() → close log
20. `main()` — Gọi start() khi file run

---

## Relevant Files

### Implementation
- [feature/auto_login/auto_login.au3](feature/auto_login/auto_login.au3) — **Rewrite hoàn toàn** (20 hàm)

### Reuse from Utils
- [utils/game_utils.au3](utils/game_utils.au3) — Reuse:
  - `returnServer()` — chọn server
  - `returnChar()` — chọn character
  - `sendKeyF8()` — gửi F8 (close game)
  - `activeAndMoveWin()` — active + move window
  - `getMainNoByChar()` — lấy window title format

- [utils/common_utils.au3](utils/common_utils.au3) — Reuse:
  - `init()` — load config
  - `getProperty()` — get tọa độ từ position_config
  - `_MU_MouseClick_Delay(, )` — click chuột
  - `sendKeyDelay()` — gửi key (cho input username/password)
  - `secondWait()` — chờ X giây với log
  - `writeLog()` / `writeLogFile(, )` — ghi log
  - `getArrayInFileTxt()` — đọc file txt
  - `getOtherChar()` — tìm character khác cùng account

### Config Files
- [config/json/position_config.json](config/json/position_config.json) — **Verify/add** section `button.login`:
  - `button_start_x`, `button_start_y`
  - `button_add_account_x`, `button_add_account_y`
  - `input_username_x`, `input_username_y`
  - `input_password_x`, `input_password_y`
  - `button_confirm_x`, `button_confirm_y`
  - `first_account_x`, `first_account_y`
  - `wait_load_user_sec` (default: 5)

- [config/json/config.json](config/json/config.json) — Verify routing `type: "auto_login"` → account login config file

- [config/json/example/account_login_exam.json](config/json/example/account_login_exam.json) — **Verify structure**:
  `json
  [
    {
      "active": true,
      "username": "xxx11",
      "password": "xxx11",
      "char_name": "xxx11",
      "server_no": 1,
      "channel_no": 1
    }
  ]
  `

- [config/text/char_in_account.txt](config/text/char_in_account.txt) — **Verify format**:
  `
  char1|char2|char3
  char4|char5
  `
  Mỗi dòng = 1 tài khoản, char cách nhau bằng `|`

### Output
- [output/report_user_login.txt](output/report_user_login.txt) — Report file (tạo mới nếu chưa có)
  - Format: `YYYY-MM-DD HH:MM:SS | username | char_name | status | server | channel`

---

## Verification

### Unit Tests (Manual)
1. ✅ `getLoginProperty("button.login.button_start_x")` → trả về số x đúng
2. ✅ `getCharInAccount("char1")` → trả về danh sách `["char1", "char2", "char3"]` đúng
3. ✅ `verifyCharacterLoaded("char1")` → kiểm tra character active đúng hay sai

### Integration Tests
4. ✅ **Success case**: Mở game → login → chọn server → chọn char ĐÚNG → report "success"
5. ✅ **Wrong character case**: Mở game → login → chọn char SAI → verify FAIL → F8 → retry → lần 2 PASS → report "retry_success"
6. ✅ **Timeout case**: Game không mở → ghi log "game_exe_not_found" → skip account
7. ✅ **Wrong password case**: Invalid user/pass → ghi log error → skip account
8. ✅ **Multiple accounts**: Loop 3+ account, mỗi account login thành công → report có 3+ dòng

---

## Key Decisions

✅ **Xây dựng từ đầu** — Không tái sử dụng logic cũ, thiết kế clean theo 12 bước
✅ **Character verification qua char_in_account.txt** — So sánh danh sách, không cần image detection
✅ **F8 logic: CHỈ khi character SAI** — Character ĐÚNG từ lần 1 → finish (không F8)
✅ **Error handling: Skip account** — Ghi log, tiếp tục account kế tiếp (không retry vô hạn)
✅ **Reuse utility functions** — game_utils và common_utils functions

---

## Further Considerations

1. **Config Positions**: Cần verify/thêm đầy đủ tọa độ login trong `button.login` section
2. **Server/Channel Selection**: Cần xem logic returnServer() và returnChar() trong game_utils.au3
3. **Game Window Title**: Verify getMainNoByChar() tạo title đúng format
4. **Retry Logic**: Limit retry = 1 lần để không vào infinite loop

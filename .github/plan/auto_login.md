# Plan: Xây Dựng Tính Năng Login Game (Từ Đầu)

## TL;DR
Xây dựng auto login game từ đầu theo 12 bước chính (có tách xử lý nhỏ theo sub-step). Trước mỗi account sẽ kiểm tra cửa sổ `MU GamethuVN - Season 21`, nếu đang tồn tại thì tắt bỏ. Khi vào `processLogin`, sẽ pre-check xem trong cùng tài khoản đã có main nào active chưa; nếu có thì coi như đã login và bỏ qua account đó. Sau đó mới mở game → login → chọn server → chọn character → kiểm tra character đúng không (qua `char_in_account.txt`) → nếu đúng thì F8 để đóng game và ghi report success, nếu sai thì F8 + retry → ghi report. Tái sử dụng hàm từ `game_utils.au3` và `common_utils.au3`.

---

## Core Architecture

### Login Flow
`
processAutoLogin()
└─ For each account (active: true)
   └─ processLogin(`username, password, charName, serverNo)
  ├─ preCheckActiveMainInSameAccount() [Pre-check: nếu đã có main active thì skip]
  ├─ closeExistingGameWindow()          [Step 1: Check title MU GamethuVN - Season 21, nếu có thì tắt]
  ├─ runGameExe()                       [Step 2: Mở game]
  ├─ clickButtonStart()                 [Step 3: Click button start → Đợi 5s]
  ├─ activeAndMoveGameWindow()          [Step 4: Active + move window + click button thêm tài khoản phía ngoài]
  ├─ checkPopupLogin()                  [Step 5: Check popup login theo pixel config]
  ├─ processLoginAccount()              [Step 6: Process login]
  │   ├─ clickAddAccount()              [Step 6.1: Click add account trong form login]
  │   ├─ inputCredentials()             [Step 6.2: Nhập user/pass]
  │   └─ confirmLogin()                 [Step 6.3: Click first account]
  ├─ waitLoadUser()                     [Step 7: Chờ load user]
  ├─ selectServer()                     [Step 8: returnServer() - game_utils]
  ├─ selectCharacter()                  [Step 9: returnChar() - game_utils]
  ├─ verifyCharacterLoaded()            [Step 10: Check char đúng (qua char_in_account.txt)]
  ├─ handleWrongCharacter()             [Step 11: F8 + retry nếu char sai]
  └─ writeLoginReport()                 [Step 12: Ghi report]
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
  - Pre-check: ưu tiên check trực tiếp theo char hiện tại, sau đó gọi `checkActiveOtherChar(currentChar)` từ `game_utils.au3` để tìm main khác cùng account đang active
  - Parse kết quả từ `checkActiveOtherChar`: `charFound|numberChar` (ví dụ: `JoyBoy|2`) để quyết định skip login flow
  - Nếu có ít nhất 1 main active trong cùng account: coi như đã login, ghi log/report status `already_logged_in`, rồi skip account
   - Gọi từng step function (runGameExe → clickButtonStart → ... → writeLoginReport)
   - Handle retry logic nếu character sai

### Phase 3: Login Steps (9 hàm)
7. `closeExistingGameWindow()` — Step 1: Kiểm tra có window title `MU GamethuVN - Season 21` không; nếu có thì `WinClose()` và chờ đóng hoàn tất trước khi mở phiên mới
8. `runGameExe()` — Step 2: Mở game exe từ common.game.exe_path → chờ 5s → click OK popup báo lỗi (tọa độ cấu hình trong file config)
9. `clickButtonStart()` — Step 3: Sử dụng ControlClick("[TITLE:MU GamethuVN - Season 21; CLASS:#32770]", "", "[CLASS:Button; INSTANCE:2]") → Đợi 5s
10. `activeAndMoveGameWindow()` — Step 4: Active + move launcher window (dùng activeAndMoveWin()) → nếu False thì chờ 1s và thử lại, tối đa 10s → Click button thêm tài khoản phía ngoài (button_outer_add_account_x/y)
11. `checkPopupLogin()` — Step 5: Check pixel theo config (`button_outer_add_account_check_x/y`, `button_outer_add_account_check_color`, `button_outer_add_account_check_max_retry`); nếu màu khớp thì coi như thành công
12. `processLoginAccount(, )` — Step 6: Xử lý form đăng nhập:
  - Gọi `clickAddAccount()` (Step 6.1)
  - Gọi `inputCredentials()` (Step 6.2)
  - Gọi `confirmLogin()` (Step 6.3)
13. `clickAddAccount()` — Step 6.1: Click vào button xóa account tại vị trí số 2 (4 lần) → Click button_add_account_x/y
14. `inputCredentials(, )` — Step 6.2: Click username → input → click password → input → chờ 2s rồi send enter
15. `confirmLogin()` — Step 6.3: Click button first_account_x/y

### Phase 4: Server/Character Selection & Verification (5 hàm)
16. `waitLoadUser()` — Step 7: Chờ X giây (wait_load_user_sec, default 5s)
17. `selectServer()` — Step 8: Gọi returnServer() từ game_utils
18. `selectCharacter()` — Step 9: Gọi returnChar() để chọn character
19. `verifyCharacterLoaded()` — Step 10:
    - Lấy danh sách char cùng account qua getCharInAccount()
    - So sánh với character active (window title)
    - Return: True/False
20. `handleWrongCharacter(, , , )` — Step 11:
    - Nếu character SAI → sendKeyF8() → chờ 2-3s → retry processLogin() (1 lần)
    - Nếu lần 2 vẫn SAI → return False, ghi log error

### Phase 5: Report & Entry Point (3 hàm)
21. `writeLoginReport(, , , , )` — Step 12:
    - Ghi file output/report_user_login.txt
    - Format: YYYY-MM-DD HH:MM:SS | username | char_name | status | server | channel
  - Status: success | retry_success | failed | timeout | wrong_password | already_logged_in
22. `start()` — Entry point: init() → open log → processAutoLogin() → close log
23. `main()` — Gọi start() khi file run

---

## Relevant Files

### Implementation
- [feature/auto_login/auto_login.au3](feature/auto_login/auto_login.au3) — **Rewrite hoàn toàn** (23 hàm)

### Reuse from Utils
- [utils/game_utils.au3](utils/game_utils.au3) — Reuse:
  - `returnServer()` — chọn server
  - `returnChar()` — chọn character
  - `sendKeyF8()` — gửi F8 (close game)
  - `activeAndMoveWin()` — active + move window
  - `getMainNoByChar()` — lấy window title format
  - `checkActiveOtherChar()` — tìm nhân vật khác cùng account đang active, trả về format `charFound|numberChar`

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
3. ✅ `checkActiveOtherChar("char1")` → trả về đúng format `charFound|numberChar` (ví dụ: `JoyBoy|2`)
4. ✅ Parse `StringSplit(checkActiveOtherChar("char1"), "|")[1/2]` → lấy đúng `charFound` và `numberChar`
5. ✅ `verifyCharacterLoaded("char1")` → kiểm tra character active đúng hay sai
6. ✅ Trong `processLogin()`: khi `verifyCharacterLoaded(...) = True` thì phải gọi `sendKeyF8()` trước khi ghi report `success`

### Integration Tests
7. ✅ **Success case**: Mở game → login → chọn server → chọn char ĐÚNG → verify PASS → send F8 → report "success"
8. ✅ **Wrong character case**: Mở game → login → chọn char SAI → verify FAIL → F8 → retry → lần 2 PASS → report "retry_success"
9. ✅ **Timeout case**: Game không mở → ghi log "game_exe_not_found" → skip account
10. ✅ **Wrong password case**: Invalid user/pass → ghi log error → skip account
11. ✅ **Already logged case**: `checkActiveWinByChar(char hiện tại)` hoặc `checkActiveOtherChar(currentChar)` tìm thấy main active → skip login flow → report "already_logged_in"
12. ✅ **Multiple accounts**: Loop 3+ account, mỗi account login thành công → report có 3+ dòng

---

## Key Decisions

✅ **Xây dựng từ đầu** — Không tái sử dụng logic cũ, thiết kế clean theo 12 bước chính
✅ **Character verification qua char_in_account.txt** — So sánh danh sách, không cần image detection
✅ **F8 logic sau verify** — Character ĐÚNG: F8 để đóng game rồi ghi success; Character SAI: F8 + retry
✅ **Error handling: Skip account** — Ghi log, tiếp tục account kế tiếp (không retry vô hạn)
✅ **Reuse utility functions** — game_utils và common_utils functions

---

## Further Considerations

1. **Config Positions**: Cần verify/thêm đầy đủ tọa độ login trong `button.login` section
2. **Server/Channel Selection**: Cần xem logic returnServer() và returnChar() trong game_utils.au3
3. **Game Window Title**: Verify getMainNoByChar() tạo title đúng format
4. **Retry Logic**: Limit retry = 1 lần để không vào infinite loop

# Hướng Dẫn Dự Án - MU Tool

## Ngôn Ngữ & Framework
- Ngôn ngữ lập trình AutoIt3 (.au3) cho tự động hóa Windows
- Thư viện bên ngoài: au3WebDriver (Selenium), các UDF tùy chỉnh (JSON, ImageSearch, HttpRequest)
- Comment và chuỗi giao diện chủ yếu bằng **Tiếng Việt**

## Kiến Trúc Tổng Quan

### Cấu trúc thư mục
```
mu_tool/
├── feature/              # Các module tính năng (điểm vào cho từng tác vụ tự động)
│   ├── auto_reset/       # Tự động reset nhân vật trên web
│   ├── auto_devil/       # Tự động tham gia sự kiện Quỷ Vương (Devil)
│   ├── auto_login/       # Đăng nhập tự động vào tài khoản game
│   ├── auto_move/        # Di chuyển/kéo team nhân vật trên bản web
│   ├── auction/          # Quản lý đấu giá & bình luận Facebook
│   ├── buy_sv_gold/      # Mua vàng server (Chủ nhật thứ 3, 5 trong tháng)
│   ├── on_off_buff_exp/  # Bật/tắt auto buff EXP cho nhân vật
│   ├── auto_control/     # Điều khiển service
│   ├── post_zalo/        # Đăng bài Zalo tự động (placeholder)
│   ├── hsan_fb_post/     # Quản lý bình luận Facebook
│   └── test/             # Các file test/debug
├── utils/                # Các tiện ích dùng chung
│   ├── common_utils.au3  # ~61 hàm: init, logging, thời gian, mouse/keyboard, file I/O, JSON config
│   ├── game_utils.au3    # ~40+ hàm: theo leader, kiểm tra level, devil event, chuyển nhân vật, điều hướng map
│   ├── web_mu_utils.au3  # ~26+ hàm: WebDriver, đăng nhập web, captcha, reset, di chuyển web
│   └── seeding_utils.au3 # Tiện ích seeding (placeholder)
├── include/              # Thư viện UDF tùy chỉnh
│   ├── json_utils.au3    # Truy xuất JSON theo dot-notation (_JSONGet, _JSONSet)
│   ├── JSON.au3          # Mã hóa/giải mã JSON theo chuẩn RFC4627
│   ├── JSON_Translate.au3# Chuyển đổi JSON ↔ kiểu dữ liệu AutoIt
│   ├── _ImageSearch_UDF.au3  # Nhận diện hình ảnh trên màn hình (GDI+)
│   └── _HttpRequest.au3  # HTTP/HTTPS request (WinHttp/WinInet)
├── lib/                  # Thư viện bên ngoài
│   └── au3WebDriver-0.12.0/  # Selenium WebDriver wrapper (wd_core, wd_helper, webdriver_utils)
├── config/               # Cấu hình
│   ├── json/             # File JSON cấu hình cho từng tính năng
│   └── text/             # Dữ liệu text (danh sách nhân vật/tài khoản)
├── driver/               # Driver trình duyệt
│   ├── chromedriver/     # Chrome WebDriver (Win64)
│   ├── firefox/          # GeckoDriver v0.33.0
│   └── msedgedriver/     # Edge WebDriver v134
├── input/                # Dữ liệu đầu vào (tài khoản, admin ID, đấu giá, comments)
├── media/                # Hình ảnh dùng cho nhận diện trạng thái game
│   └── image/
│       ├── common/       # Ảnh UI chung (400lv, auto_home, buff, switch_char...)
│       └── devil/        # Ảnh sự kiện Devil (popup, ruong_k...)
└── output/               # File log từ các tính năng
```

### Luồng khởi tạo & cấu hình
1. `common_utils.au3 → init()` — Đọc `config.json`, load tất cả config theo trường `type`
2. `mergeInfoAccountRs()` — Gộp thông tin tài khoản từ nhiều nguồn config
3. Feature entry point — Gọi `init()`, load config riêng, lọc theo `active: true`, thực thi logic

### Hệ thống cấu hình (`config/json/`)
- **`config.json`** — File config chính, định tuyến sang các config con theo `type` (position, reset, devil, buy_gold, auto_move...)
- **`position_config.json`** — Tọa độ pixel các thành phần UI game, đường dẫn driver, profile trình duyệt
- **`config_time.json`** — Theo dõi thời gian thực thi (zalo, devil, facebook_post...)
- **`m1/m2_devil_config.json`** — Cấu hình Devil theo server (active, char_name, devil_no, max_hour_go...)
- **`m1/m2_account_reset.json`** — Cấu hình reset tài khoản theo server

### Chuỗi phụ thuộc (include chain)
```
Feature → common_utils
        → [game_utils | web_mu_utils | seeding_utils]
        → [json_utils → JSON.au3 → JSON_Translate.au3]
        → _ImageSearch_UDF.au3
        → webdriver_utils (au3WebDriver-0.12.0)
```

### Dịch vụ bên ngoài
- **Azcaptcha** — Giải captcha tự động (dùng trong đăng nhập web)
- **MU Online Web Server** — `https://hn.gamethuvn.net/` (reset, di chuyển, buff...)
- **Facebook** — Quản lý nhóm qua trình duyệt (WebDriver)

### Đặc điểm kiến trúc
- **Cấu hình hóa** — Hành vi logic điều khiển bởi JSON config, không hardcode
- **Module hóa** — Mỗi tính năng độc lập với pattern init/run rõ ràng
- **Nhật ký chi tiết** — Tất cả thao tác được ghi log với timestamp và context
- **Nhận diện hình ảnh** — Trạng thái game xác nhận qua pixel color và image matching
- **Lên lịch theo thời gian** — Các tính năng kiểm tra ràng buộc thời gian trước khi thực thi

## Quy Cách Code
- Lập trình thủ tục — không dùng OOP
- Đặt `#include-once` ở đầu mọi file tiện ích/thư viện
- Đặt tên hàm: `camelCase` hoặc `snake_case` (ví dụ: `checkLvl400()`, `_MU_followLeader()`)
- Hàm dạng UDF có tiền tố gạch dưới (ví dụ: `_JSONGet()`, `_MU_ControlClick_Delay()`)
- Biến toàn cục có tiền tố `$`, khai báo đầu file (ví dụ: `Global $jsonConfig`)
- Hằng số: `Global Const` với PascalCase hoặc ALL_CAPS

## Mẫu Include
```autoit
#include-once
#include <Date.au3>                                    ; Thư viện AutoIt có sẵn
#include "../include/json_utils.au3"                   ; Include tùy chỉnh (đường dẫn tương đối)
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"  ; Thư viện bên ngoài
```

## Sử Dụng JSON Config
- Load config bằng `getJsonFromFile()` trong hàm `init()`
- Truy xuất giá trị lồng nhau qua dot-notation: `_JSONGet($jsonConfig, "common.web.mu_url")`
- Config dùng cờ `active` và trường `type` để định tuyến tính năng

## Ghi Log & Tài Liệu
- Dùng `writeLog()` / `writeLogFile()` cho mọi ghi log
- Dùng `writeLogMethodStart()` / `writeLogMethodEnd()` để theo dõi vào/ra hàm
- Ghi chú hàm theo mẫu:
```autoit
; Method: functionName
; Description: Mô tả chức năng
```

## Quy Ước
- Kiểm tra trạng thái trước khi thực thi (ví dụ: `checkPixelColor()`, `checkLvl400()`)
- Dùng `secondWait()` để delay có ghi log thay vì `Sleep()` trực tiếp
- Tự động hóa chuột/bàn phím qua hàm helper (`mouseClickDelayShift()`, `_MU_ControlClick_Delay()`)
- Xử lý lỗi qua ghi log — validate đầu vào tại ranh giới hệ thống

## Build
- Task Tidy AutoIt dùng để format code: `Tidy.exe`

## Quy Tắc
- Tránh biến toàn cục khi có thể — ưu tiên truyền tham số
- Giữ hàm tập trung vào một nhiệm vụ duy nhất
- Đặt tên mô tả rõ ràng cho hàm và biến
- Comment logic không rõ ràng, đặc biệt cơ chế liên quan game
- Độ dài tối đa cho hàm: ~100 dòng — chia logic phức tạp thành các hàm nhỏ hơn
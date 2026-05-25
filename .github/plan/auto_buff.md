# Plan: Tạo tính năng Auto Buff

## TL;DR
Tạo tính năng auto buff nhân vật trên web MU Online. Gồm 1 file JSON config chứa thông tin tài khoản và 1 file feature thực hiện: đọc config → kiểm tra ngày buff → login → buff → cập nhật config → logout. Tái sử dụng `login()`, `logout()`, `goPageBuffChar()` từ `web_mu_utils.au3`. Phong cách viết giống `withDrawRs()` trong `auto_rs.au3`.

## Steps

### Phase 1: Config

1. Tạo `config/json/example/auto_buff_example.json` — file config mẫu
2. Tạo `config/json/auto_buff_config.json` — file config thực tế
3. Thêm entry vào `config/json/config.json`
4. Thêm global `$autoBuffFileName` trong `utils/common_utils.au3`
5. Thêm xử lý `type=="auto_buff"` trong hàm `init()`

### Phase 2: Feature File

6. Tạo `feature/auto_buff/auto_buff.au3` gồm:
   - `startAutoBuff()` — Entry point: init → load config → filter active → setup chrome → loop accounts → buff → logout → cleanup
   - `processBuffAccount()` — Xử lý buff 1 account: login → goPageBuffChar → cập nhật last_time_buff

## Relevant Files

### Tạo mới
- `config/json/example/auto_buff_example.json`
- `config/json/auto_buff_config.json`
- `feature/auto_buff/auto_buff.au3`

### Chỉnh sửa
- `config/json/config.json` — Thêm 1 entry routing type "auto_buff"
- `utils/common_utils.au3` — Thêm `Global $autoBuffFileName` + handler trong `init()`
- `feature/auto_control/service_control.au3` — Thêm `#include "../auto_buff/auto_buff.au3"` và gọi `startAutoBuff()` ngay sau `startAutoRs()` trong hàm `start()`

### Tham khảo / Reuse
- `feature/auto_reset/auto_rs.au3` — Pattern: `startAutoRs()`, `withDrawRs()`
- `utils/web_mu_utils.au3` — Reuse: `login()`, `logout()`, `goPageBuffChar()`, `checkThenCloseChrome()`
- `utils/common_utils.au3` — Reuse: `init()`, `getJsonFromFile()`, `setJsonToFileFormat()`, `writeLogFile()`, `sortArrayByProperty()`, `redimArray()`, `secondWait()`

## Verification

1. Chạy `startAutoBuff()` với account test (`active=true`, `last_time_buff` = ngày hôm qua) → verify buff thành công, `last_time_buff` cập nhật
2. Chạy lại lần 2 → verify skip vì đã buff hôm nay
3. Test với `active=false` → verify bị bỏ qua
4. Test với 2 account cùng `user_name` → verify chỉ logout sau account cuối

## Key Decisions

- Format `last_time_buff`: `YYYY/MM/DD` — consistent với AutoIt `@YEAR/@MON/@MDAY`
- Config file riêng (không dùng chung file khác)
- Pattern logout: so sánh `user_name` hiện tại vs kế tiếp (giống `startAutoRs`)
- Sort mảng theo `user_name` trước khi loop

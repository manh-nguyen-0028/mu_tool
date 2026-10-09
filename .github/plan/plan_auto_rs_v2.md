# Plan: Rebuild Auto Reset V2

Rebuild tính năng auto reset theo hướng đơn giản, giữ nguyên nền util hiện có (common/web/game), tách sang file V2 để chuyển đổi an toàn. Flow chỉ còn 2 type reset và withdraw, giữ đầy đủ validation quan trọng như bản cũ.

## Current Status
- Hoàn thành tạo và vận hành flow V2 trong [feature/auto_reset/auto_rs_v2.au3](feature/auto_reset/auto_rs_v2.au3).
- Hoàn thành tách entry service riêng cho V2 trong [feature/auto_control/service_control_v2.au3](feature/auto_control/service_control_v2.au3).
- Hoàn thành cập nhật mẫu config V2 trong [config/json/example/account_reset_v2_example.json](config/json/example/account_reset_v2_example.json) và [config/json/example/auto_rs_update_info_v2_example.json](config/json/example/auto_rs_update_info_v2_example.json).
- Chưa thực hiện cutover mặc định từ V1 sang V2 (đang cho chạy song song để an toàn rollback).

## Implemented Changes
1. Orchestrator V2 (startAutoRsV2)
- Entry point mới: startAutoRsV2, ghi log ra File_Log_AutoRS_V2_.txt.
- Merge account từ mergeInfoAccountRs, chuẩn hóa từng account qua _NormalizeAccountV2.
- Lọc account active và phân loại theo type: reset hoặc withdraw; type khác bị bỏ qua và ghi log.
- Chỉ account reset đi qua validAccountRsV2; account withdraw đưa thẳng vào hàng xử lý.
- Khởi tạo một Chrome session dùng chung (startChromeSession), thoát sớm nếu không tạo được.
- Sort theo username để chỉ logout khi chuyển sang username khác (tối ưu login/logout).

2. Chuẩn hóa account (_NormalizeAccountV2)
- Đồng bộ username và user_name cho nhau để tương thích dữ liệu cũ.
- Chuẩn hóa type_rs: "1" => vip, "0" => free, giá trị khác => free.
- Gán default cho các field thiếu: go_arena=false, is_hide=false, lvl_move=400, switch_other_main=false, char_main_name="", hour_per_reset=1, max_hour_reset=24, time_rs=0, limit=5, arena_loop_count=5, last_time_reset=now, rs=0, max_rs=2000.
- Trích xuất thêm lvlMove, switchOtherMain, charMainName trong extractAccountInfoV2.

3. Validation V2 (validAccountRsV2 + helper _ValidRs_*)
- Tách rule thành các helper riêng theo thứ tự check: last_time không hợp lệ, quá max_hour_reset, chưa tới giờ reset, đạt max_rs (hoặc >= 2000), gate chờ theo type_rs, vượt daily limit.
- type_rs free: chờ 30 phút khi rs>=50, chờ time_wait_rs_zen_rs_50 khi rs<50; type_rs vip chờ time_wait_rs_vip.
- Hạ cấp vip xuống free khi time_rs vượt max_rs_vip và hour_per_reset=0 (_ValidRs_AdjustTypeRsIfOverDailyLimitV2).
- Đọc tham số time_wait_rs_vip, time_wait_rs_zen_rs_50, max_rs_vip từ position config, có default (20/30/10).

4. Reset Flow V2 (resetV2 / processResetV2)
- reset_online=false: active/switch char, changeChar trước khi reset; nếu reset fail thì returnChar, stop auto plus, ShiftF và ẩn main nếu cần.
- processResetV2: login, lấy log reset, gate thời gian (_CheckTimeToResetV2), gate level theo RS (calculateRequiredLevelForResetV2: 400, hoặc 200 + rs*5 khi rs<50).
- Sau reset web thành công: cập nhật thông tin account (_ProcessRs_UpdateAccountInfoV2: rs, time_rs, last_time_reset).
- go_arena=true: processGoArenaV2 với arena_loop_count, sau đó moveOtherMap và add point auto plus.
- Sau arena (reset_online=false): re-fetch getLogReset + getCurrentlvl; nếu currentLvl >= lvl_move và switch_other_main=true thì active main, check active auto home, nếu true thì switchToMainCharItem(charName, char_main_name).
- Ẩn main theo is_hide qua _HideMainIfNeededV2 (gửi F8 khi is_hide, ngược lại minisizeMain).

5. Arena Flow V2 (processGoArenaV2)
- Chờ 1 phút, vào map arena theo rsCount, lặp arena_loop_count lần.
- Mỗi vòng check checkActiveAutoHome, nếu chưa active thì vào lại arena.

6. Withdraw Flow V2 (withDrawRsV2)
- login, checkIP, gate thời gian theo hour_per_reset, submit withdraw và đóng dialog xác nhận.
- Lấy withdrawTimeRs, fallback getRsInDay nếu <0; cập nhật state qua _UpdateWithdrawInfoV2 (time_rs, last_time_reset).
- reset_online=false: chỉ chạy flow đổi/vào lại char khi main active hoặc switchOtherChar thành công, ngược lại skip và ghi log.

7. Service Control V2
- File service riêng gọi startAutoRsV2, không ảnh hưởng service V1; có startPath chạy auto_rs_v2.exe.

8. Config Examples V2
- Mẫu JSON đúng field theo V2, định dạng mỗi object một dòng theo yêu cầu vận hành.
- Bổ sung 3 trường config mới cho cả account_reset_v2.json và example:
- lvl_move: level mốc để chuyển map khác sau reset (default 400).
- switch_other_main: có chuyển về main chính sau khi xong hay không (default false).
- char_main_name: tên nhân vật main chính để switch về (default rỗng).

## Active V2 Files
- [feature/auto_reset/auto_rs_v2.au3](feature/auto_reset/auto_rs_v2.au3)
- [feature/auto_control/service_control_v2.au3](feature/auto_control/service_control_v2.au3)
- [utils/web_mu_utils.au3](utils/web_mu_utils.au3)
- [config/json/account_reset_v2.json](config/json/account_reset_v2.json)
- [config/json/auto_rs_update_info_v2.json](config/json/auto_rs_update_info_v2.json)
- [config/json/example/account_reset_v2_example.json](config/json/example/account_reset_v2_example.json)
- [config/json/example/auto_rs_update_info_v2_example.json](config/json/example/auto_rs_update_info_v2_example.json)

## Verification Summary
- Các lần cập nhật gần nhất đã được kiểm tra lỗi cú pháp trên file chính và không có lỗi.
- Flow withdraw có guard điều kiện trước khi đổi/vào lại char để tránh thao tác sai trạng thái cửa sổ game.

## Remaining Work
1. Nếu muốn cutover mặc định:
- Đổi điểm chạy từ service V1 sang service V2 trong quy trình deploy/run thực tế.

2. Nếu muốn ổn định thêm:
- Chạy test vận hành theo các case reset_online true/false, go_arena true/false, checkIP true/false.

3. Wiring 3 trường config mới vào flow:
- lvl_move + switch_other_main + char_main_name: đã wiring trong processResetV2 (reset_online=false) — sau arena, re-fetch level, nếu đạt mốc + auto home active thì switchToMainCharItem(charName, char_main_name) để chuyển về main chính.

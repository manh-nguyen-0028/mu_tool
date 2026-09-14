# Plan: Rebuild Auto Reset V2

Rebuild tính năng auto reset theo hướng đơn giản, giữ nguyên nền util hiện có (common/web/game), tách sang file V2 để chuyển đổi an toàn. Flow chỉ còn 2 type reset và withdraw, giữ đầy đủ validation quan trọng như bản cũ.

## Current Status
- Hoàn thành tạo và vận hành flow V2 trong [feature/auto_reset/auto_rs_v2.au3](feature/auto_reset/auto_rs_v2.au3).
- Hoàn thành tách entry service riêng cho V2 trong [feature/auto_control/service_control_v2.au3](feature/auto_control/service_control_v2.au3).
- Hoàn thành cập nhật mẫu config V2 trong [config/json/example/account_reset_v2_example.json](config/json/example/account_reset_v2_example.json) và [config/json/example/auto_rs_update_info_v2_example.json](config/json/example/auto_rs_update_info_v2_example.json).
- Chưa thực hiện cutover mặc định từ V1 sang V2 (đang cho chạy song song để an toàn rollback).

## Implemented Changes
1. Orchestrator V2
- Entry point mới: startAutoRsV2.
- Lọc account active theo 2 type reset hoặc withdraw.
- Sort theo username để tối ưu login/logout session.

2. Validation V2
- Giữ các rule chính: time gate, daily limit, max_rs, type_rs wait gate.
- Có fallback username từ user_name để tương thích dữ liệu cũ.

3. Reset Flow V2
- reset_online=false: sau khi return char thực hiện stop auto plus, add point, start auto plus.
- go_arena dùng arena_loop_count từ config update info V2.
- Sau processGoArenaV2 có moveOtherMap và cộng điểm thêm một lần.

4. Withdraw Flow V2
- Giữ flow login, checkIP, submit withdraw, lấy withdrawTimeRs và update state.
- Với reset_online=false:
- Chỉ chạy flow đổi/vào lại char khi main active được hoặc sau khi switchOtherChar thành công.
- Nếu không thỏa điều kiện trên thì skip flow và ghi log rõ lý do.

5. Service Control V2
- Tạo file service riêng để gọi startAutoRsV2, không ảnh hưởng service V1.
- Có startPath chạy auto_rs_v2.exe.

6. Config Examples V2
- Mẫu JSON đã đúng field theo V2.
- Định dạng mẫu đã đổi về mỗi object một dòng theo yêu cầu vận hành.

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

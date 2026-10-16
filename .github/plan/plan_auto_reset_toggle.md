## Plan: Auto Plus Reset Scheduler

Tao feature moi de bat/tat checkbox reset trong Auto Plus theo lich 00:06 (bat) va 06:30 (tat), dieu khien theo danh sach nhan vat active trong config. Logic thao tac game se dat o game_utils, feature chi lo load config, loc record, active window/switch char va goi helper. Tich hop goi tu service_control_v2, giu nguyen cau truc entry-point hien tai theo quyet dinh cua ban.

**Steps**
1. Phase 1 - Wiring config type va file config (*chan cac phase sau*):
   1.1. Them bien global cau hinh moi trong utils/common_utils.au3 (dat theo convention hien co), vi du autoResetToggleConfigFileName.
   1.2. Mo rong init() trong utils/common_utils.au3 de map type moi tu config/json/config.json sang bien file name.
   1.3. Them entry type moi vao config/json/config.json tro toi auto_reset_toggle_config.json.
   1.4. Tao config/json/auto_reset_toggle_config.json theo schema da chot: active, char_name, is_swith_other_char, other_char_name.
   1.5. Tao config vi du o config/json/example/auto_reset_toggle_example.json de chuan hoa onboarding.
2. Phase 2 - Bo sung helper Auto Plus trong game_utils (*phu thuoc Step 1.1/1.2; co the lam song song voi 1.4/1.5*):
   2.1. Them helper kiem tra trang thai checkbox reset bang image search (is_checked_reset.bmp) theo pattern checkAutoOnBuff/checkAutoOffBuff/searchImageFullScreenMu.
   2.2. Them helper thao tac checkbox reset theo trang thai mong muon (Enable/Disable): mo panel Auto Plus, kiem tra anh hien tai, chi click checkbox khi lech trang thai, verify lai bang anh, roi bam Start.
   2.3. Chuan hoa return bool + log chi tiet cho tung nhanh (da dung trang thai, doi trang thai thanh cong, verify that bai).
   2.4. Giu nguyen toa do click checkbox lay tu button.train_in_game.checkbox_reset_x/y trong position config dang active.
3. Phase 3 - Tao feature scheduler bat/tat theo moc gio (*phu thuoc Phase 1 + Phase 2*):
   3.1. Tao file feature/auto_reset/auto_reset_toggle.au3, include common_utils.au3 + game_utils.au3, khong nhung logic click truc tiep ngoai helper game_utils.
   3.2. Implement flow chung: load config moi, loc record active, loop tung record.
   3.3. Voi tung record: thu active main theo char_name; neu fail va is_swith_other_char=true thi thu switchOtherChar(char_name) thong qua char cung tai khoan; neu van fail thi skip record.
   3.4. Luong Bat (00:06 +- 5 phut): stopAutoPlus -> mo Auto Plus -> kiem tra is_checked_reset.bmp.
   3.5. Neu anh da checked: bam Start luon. Neu chua checked: click checkbox_reset_x/y -> verify lai anh = checked -> bam Start.
   3.6. Luong Tat (06:30 +- 5 phut): stopAutoPlus -> mo Auto Plus -> kiem tra is_checked_reset.bmp.
   3.7. Neu anh da unchecked: bam Start luon. Neu van checked: click checkbox_reset_x/y -> verify lai anh = unchecked -> bam Start.
   3.8. Debounce theo ngay cho tung moc bat/tat de moi moc chay toi da 1 lan/ngay trong cung tien trinh (marker runtime cho ON va OFF).
4. Phase 4 - Tich hop vao service dieu phoi (*phu thuoc Phase 3*):
   4.1. Include feature/auto_reset/auto_reset_toggle.au3 trong feature/auto_control/service_control_v2.au3.
   4.2. Goi ham scheduler moi trong vong lap start() cua service_control_v2, cung chu ky voi reset/buff hien tai.
   4.3. Bo sung log tach biet de phan biet action reset scheduler voi luong auto_rs_v2.
5. Phase 5 - Asset va tuong thich config vi tri (*song song voi Phase 2/3*):
   5.1. Bo sung media/image/common/is_checked_reset.bmp (theo quyet dinh dung BMP).
   5.2. Verify file position config dang active co du button.train_in_game.button_x/button_start_x/button_stop_x/checkbox_reset_x/checkbox_reset_y; neu thieu thi cap nhat file position thuc te dang dung (vi du m1/m2), khong hardcode trong code.

**Relevant files**
- d:/Project/AutoIT/mu_tool/utils/common_utils.au3 - them mapping type config moi trong init(), khai bao global file name.
- d:/Project/AutoIT/mu_tool/config/json/config.json - dang ky type moi tro toi auto_reset_toggle_config.json.
- d:/Project/AutoIT/mu_tool/config/json/auto_reset_toggle_config.json - config runtime cua tinh nang bat/tat reset.
- d:/Project/AutoIT/mu_tool/config/json/example/auto_reset_toggle_example.json - config mau.
- d:/Project/AutoIT/mu_tool/utils/game_utils.au3 - helper check anh checkbox reset + apply trang thai reset trong Auto Plus.
- d:/Project/AutoIT/mu_tool/feature/auto_reset/auto_reset_toggle.au3 - feature scheduler moi.
- d:/Project/AutoIT/mu_tool/feature/auto_control/service_control_v2.au3 - diem tich hop goi scheduler.
- d:/Project/AutoIT/mu_tool/media/image/common/is_checked_reset.bmp - asset xac nhan trang thai checked.
- d:/Project/AutoIT/mu_tool/config/json/m2/m2_position_config.json - tham chieu key train_in_game/checkbox_reset hien co de dong bo voi config active thuc te.

**Verification**
1. Kiem tra parse config: log hien thi so ban ghi active va du lieu tung char dung schema.
2. Case ON: ep thoi diem test vao cua so 00:06 +-5, xac nhan sequence dung: stop -> open -> check anh -> (toggle neu can) -> verify checked -> start.
3. Case OFF: ep thoi diem test vao cua so 06:30 +-5, xac nhan sequence dung: stop -> open -> check anh -> (toggle neu can) -> verify unchecked -> start.
4. Case fail active window: khong active duoc main + switchOtherChar fail thi skip record, khong crash vong lap.
5. Case debounce: goi lap trong cung cua so gio va cung ngay chi chay action 1 lan cho ON, 1 lan cho OFF.
6. Case integration: service_control_v2 loop goi scheduler moi khong lam hong luong startAutoRsV2/startAutoBuff hien tai.

**Decisions**
- Diem tich hop: tao file feature rieng va goi tu service_control_v2.
- Debounce: moi moc gio chay toi da 1 lan/ngay.
- Asset: dung BMP voi ten is_checked_reset.bmp.
- Ten config moi: auto_reset_toggle_config.json.
- Trigger: dung cua so thoi gian +-5 phut quanh 00:06 va 06:30.
- Chap nhan rui ro: giu loop hien tai cua service_control_v2, co the bo lo moc khi loop thua.
- Giu nguyen cau truc entry-point hien tai, khong refactor auto_rs_v2.start() theo yeu cau.

**Further Considerations**
1. Truong is_swith_other_char dang co typo "swith" theo yeu cau; nen giu nguyen de tuong thich config, chi them comment tai lieu tranh nham voi switch.
2. Neu sau nay can do chinh xac gio cao hon, co the tach scheduler nay thanh tien trinh rieng check moi phut.
3. Nen can nhac them vung search nho cho anh checkbox reset trong position config de tang on dinh va toc do so voi full-screen search.

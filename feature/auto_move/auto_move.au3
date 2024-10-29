#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"
#include "../../utils/game_utils.au3"
#RequireAdmin

Local $aAccountActiveRs[0]
Local $sSession,$logFile
Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
Local $sDate = @YEAR & @MON & @MDAY
Local $className = @ScriptName


Local $sFilePath = $outputPathRoot & "File_Log_Auto_Move.txt"

Func start()
    writeLogFile($logFile, "Begin start auto move !")
    ; 1. Thuc hien lay danh sach account can auto move, chi lay nhung account co active = true
    ; 2. Thuc hien lay danh sach password account
    ; 3. Duyet danh sach account can auto move, kiem tra xem co duoc active
    ; 3.1. Neu khong thay active thi kiem tra xem char_in_account de switch account
    ; 3.2. Neu co thi kiem tra xem autoZ co hoat dong hay khong
    ; 3.2.1. Neu autoZ hoat dong thi thuc hien minizie cua so game
    ; 3.2.2. Neu autoZ khong hoat dong thi thuc hien login va move tren web
    ; 3.2.1.1. Thuc hien lay thong tin ve username, password, map va toa do can move
    ; 3.2.1.2. Thuc hien move tren web
    ; 3.2.1.3. Thuc hien close dialog
    ; 3.2.1.4. Thuc hien logout
    
    Return True
EndFunc
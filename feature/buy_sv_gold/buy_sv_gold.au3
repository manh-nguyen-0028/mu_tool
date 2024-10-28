#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"
;~ #RequireAdmin

Local $sFilePath = $outputPathRoot & "File_Log_Buy_Sv_Gold.txt"
$logFile = FileOpen($sFilePath, $FO_APPEND)
Local $aAccountActive[0]

start()

Func start()
    ; Kiểm tra và hiển thị kết quả
    $resultCheck = IsThirdOrFifthSunday()

    If $resultCheck Then
        writeLogFile($logFile, "Hôm nay là Chủ Nhật thứ 3 hoặc thứ 5 trong tháng.")
        ; Thực hiện mua sv gold
        processBuySvGold()
    Else
        writeLogFile($logFile, "Hôm nay không phải là Chủ Nhật thứ 3 hoặc thứ 5 trong tháng.")
        writeLogFile($logFile, "Ngay thang nam hien tai: " & @MDAY & "/" & @MON & "/" & @YEAR)
    EndIf
    Return True
EndFunc

Func processBuySvGold()
    
	$jAccountActive = getJsonFromFile($jsonPathRoot & $buySvGoldFileName)

    ; Neu khong co account nao thi thoat
    If UBound($jAccountActive) = 0 Then
        writeLogFile($logFile, "Khong co account nao de mua sv gold.")
        Return False
    Else
        writeLogFile($logFile, "Co " & UBound($jAccountActive) & " account de mua sv gold.")
        ; Thuc hien close chrome va mo lai
        checkThenCloseChrome()
        $sSession = SetupChrome()
        secondWait(5)
         ; Logout account cho chac, nhieu luc se bi cache account cu
        _WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
        secondWait(2)

        ; Duyet qua tung account de mua sv gold
        For $i = 0 To UBound($jAccountActive) - 1
            $active = getPropertyJson($jAccountActive[$i], "active")
            If $active == True Then
                $username = getPropertyJson($jAccountActive[$i], "username")
                $password = getPropertyJson($jAccountActive[$i], "password")
                ; Login
                $isLoginSuccess = login($sSession, $username, $password)
    
                If $isLoginSuccess Then
                    writeLogFile($logFile, "Login success with account: " & $username)
                    ; Thuc hien mua sv gold
                    $isBuySvGoldSuccess = buySvGold($sSession)
                    If $isBuySvGoldSuccess Then
                        writeLogFile($logFile, "Buy sv gold success with account: " & $username)
                    Else
                        writeLogFile($logFile, "Buy sv gold fail with account: " & $username)
                    EndIf
                Else
                    writeLogFile($logFile, "Login fail with account: " & $username)
                EndIf

                ; logout
                _WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")

            EndIf
        Next
    EndIf

    Return True
EndFunc

Func buySvGold($sSession)
    ; Chuyen sang trang mua sv gold
    ;~ https://hn.mugamethuvn.info/web/tool/gold_server.shtml
    _WD_Navigate($sSession, $baseMuUrl & "tool/gold_server.shtml")

    ; Kiem tra xem da load duoc element hay chua, neu chua thi doi them 3s va tim lai
    $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='total_day']", 1)
    $count = 0
    While $sElement <> $_WD_ERROR_Success And $count < 3
        secondWait(3)
        $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='total_day']", 1)
        $count += 1
    WEnd

    If $sElement = $_WD_ERROR_Success Then
        writeLogFile($logFile, "Load page buy sv gold success.")
        _WD_ElementAction($sSession, $sElement, 'value','xxx')
        _WD_ElementAction($sSession, $sElement, 'CLEAR')
        secondWait(2)

        _WD_ElementAction($sSession, $sElement, 'value','1')
        writeLog("$sValue: " & _WD_ElementAction($sSession, $sElement, 'value'))
        secondWait(2)

        ; Submit to buy sv gold
        $sElement = findElement($sSession, "//button[@type='submit']")
        clickElement($sSession, $sElement)
        secondWait(5)

        ; Check xem co diaglog confirm hay khong
        closeDiaglogConfim($sSession)

        Return True
    Else
        writeLogFile($logFile, "Load page buy sv gold fail.")
        Return False
    EndIf
EndFunc

; Hàm kiểm tra xem ngày hiện tại có phải là Chủ Nhật thứ 3 hoặc thứ 5 trong tháng
Func IsThirdOrFifthSunday()
    ; Lấy ngày hiện tại
    Local $currentDate = @MDAY
    Local $currentMonth = @MON
    Local $currentYear = @YEAR
    Local $dayOfWeek = @WDAY ; 1 = Chủ Nhật, 2 = Thứ Hai, ..., 7 = Thứ Bảy

    ; Kiểm tra nếu ngày hiện tại không phải Chủ Nhật
    If $dayOfWeek <> 1 Then
        Return False
    EndIf

    ; Đếm số Chủ Nhật trong tháng
    Local $countSundays = 0
    For $day = 1 To $currentDate
        If @WDAY = 1 Then
            $countSundays += 1
        EndIf
        ; Tăng ngày
        $currentDate += 1
    Next

    ; Kiểm tra xem số Chủ Nhật hiện tại có phải là thứ 3 hoặc thứ 5 không
    If $countSundays = 3 Or $countSundays = 5 Then
        Return True
    Else
        Return False
    EndIf
EndFunc

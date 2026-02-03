#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"

;~ testControlClick() 
;~ start()

;~ getOtherChar("AliceX")
;~ switchOtherChar("XXXX002")
test99()

Func test99()
    ;~ $timeNow = getTimeNow()
    ;~ $hourPerRs = 24
    ;~ $nextTimeRs = _DateAdd('h', $hourPerRs, $timeNow)
    ;~ writeLog("Time now: " & $timeNow)

    ;~ $charInfoText = getTextElement($sSession, $sElement)
	;~ writeLogFile($logFile, "$charInfoText: " & $charInfoText)
	$charInfoText = "Reset 1160 lần, point dư: 20,000" & "Level Master: 538, skill_3: 0, skill_4: 0, level thuộc tính: 8, điểm quả: 0" & "xxx11 level 400 (Hôm nay reset 3 lượt. Tháng này reset 101 lượt)"

	; $currentReset so o giua tri Reset va lần. trong ví dụ trên là 1160
	Local $tempSplit = StringSplit($charInfoText, "Reset ", 1)
	Local $resetPart = $tempSplit[2] ; Lấy phần sau "Reset "
	Local $currentReset = Number(StringSplit($resetPart, " lần", 1)[1]) ; Lấy số trước " lần"
	
	ConsoleWrite("Extracted reset value: " & $currentReset & @CRLF)
    Return True
EndFunc

Func start()
    $idCaptcha = ""
    If Not checkIsNumber($idCaptcha) Then
        ConsoleWrite("Captcha value is not number: " & $idCaptcha & @CRLF)
        ;~ writeLogFile($logFile, "Captcha value is not number: " & $idCaptcha)
        ;~ writeLogFile($logFile, "Chuyen lai tab ve " & $baseMuUrl)
        ;~ _WD_Attach($sSession, $baseMuUrl, "URL")
        ;~ _WD_Window($sSession,"MINIMIZE")
        $isSuccess = False
        ;~ ExitLoop
    Else
        ConsoleWrite("Captcha value is number: " & $idCaptcha & @CRLF)
    EndIf
    Return True
EndFunc

Func testControlClick()
	; Lấy handle của cửa sổ Q-Dir
    Local $hWnd = WinGetHandle("xstraetl – SvgUtil.java [export-pdf]")

    ; Kiểm tra nếu cửa sổ có tồn tại
    If Not @error Then
        ; Thực hiện click tại tọa độ (186, 11) của control SysTabControl32, Instance 4
        ControlClick($hWnd, "", "", "Left", 1, 1786, 100)
    Else
        ConsoleWrite("Không tìm thấy cửa sổ Q-Dir!" & @CRLF)
    EndIf

	Return True
EndFunc

; Hàm tạo chuỗi ngẫu nhiên 10 ký tự
Func GenerateRandomString($length = 10)
    Local $characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    Local $randomString = ""
    For $i = 1 To $length
        $randomString &= StringMid($characters, Random(1, StringLen($characters), 1), 1)
    Next
    Return $randomString
EndFunc

#include <date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../../utils/web_mu_utils.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#RequireAdmin

Global $sFilePath, $timeStartProcess = 0
Global $isPaused = False
HotKeySet("+{F4}", "togglePause")

start()

; Method: togglePause
; Description: Tam dung/tiep tuc chuong trinh bang phim tat Shift+F4
Func togglePause()
    $isPaused = Not $isPaused
    If $isPaused Then
        writeLogFile($logFile, "=== CHUONG TRINH DA TAM DUNG (Shift+F4) ===")
        While $isPaused
            Sleep(200)
        WEnd
        writeLogFile($logFile, "=== CHUONG TRINH TIEP TUC (Shift+F4) ===")
    EndIf
EndFunc   ;==>togglePause

; Method: start
; Description: Khoi tao log, chay loop xu ly reset online cho cac nhan vat active
Func start()
	$sFilePath = $outputPathRoot & "File_Log_AutoResetOnline_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)

	Local $jsonActiveList = getArrayActiveResetOnline()
	writeLogFile($logFile, "Account active reset online: " & UBound($jsonActiveList))

	If UBound($jsonActiveList) > 0 Then
		processResetOnlineLoop()
	Else
		writeLogFile($logFile, "Khong co nhan vat nao active de reset online")
	EndIf

	FileClose($logFile)
	Return True
EndFunc   ;==>start

; Method: processResetOnlineLoop
; Description: While loop lien tuc kiem tra va thuc hien reset online, sleep 30 phut giua cac lan check
Func processResetOnlineLoop()
	While True
		; Reset log file moi 10 lan de tranh file qua lon
		If $timeStartProcess > 10 Then
			$logFile = FileOpen($sFilePath, 1)
			writeLogFile($logFile, "Reset log file after process more than 10 times")
			$timeStartProcess = 0
		Else
			$timeStartProcess += 1
			writeLogFile($logFile, "log $timeStartProcess: " & $timeStartProcess)
		EndIf

		processResetOnline()

		; Sleep 30 phut truoc khi check lai
		writeLogFile($logFile, "Cho 30 phut truoc khi kiem tra lai...")
		secondWait(1800)
	WEnd
EndFunc   ;==>processResetOnlineLoop

; Method: getArrayActiveResetOnline
; Description: Load config reset online, loc cac nhan vat co active = true
Func getArrayActiveResetOnline()
	Local $jsonResetOnlineConfig = getJsonFromFile($jsonPathRoot & $resetOnlineConfigFileName)
	Local $jsonActiveList[0]

	For $i = 0 To UBound($jsonResetOnlineConfig) - 1
		Local $active = _JSONGet($jsonResetOnlineConfig[$i], "active")
		If $active Then
			ReDim $jsonActiveList[UBound($jsonActiveList) + 1]
			$jsonActiveList[UBound($jsonActiveList) - 1] = $jsonResetOnlineConfig[$i]
		EndIf
	Next

	Return $jsonActiveList
EndFunc   ;==>getArrayActiveResetOnline

; Method: processResetOnline
; Description: Lap qua tung nhan vat active, kiem tra thoi gian va thuc hien reset online
Func processResetOnline()
	writeLogMethodStart("processResetOnline")

	; Load lai config moi lan de cap nhat last_time_reset
	Local $jsonActiveList = getArrayActiveResetOnline()

	If UBound($jsonActiveList) = 0 Then
		writeLogFile($logFile, "Khong co nhan vat nao active de reset online")
		writeLogMethodEnd("processResetOnline")
		Return
	EndIf

	For $i = 0 To UBound($jsonActiveList) - 1
		Local $charName = _JSONGet($jsonActiveList[$i], "char_name")
		Local $lastTimeReset = _JSONGet($jsonActiveList[$i], "last_time_reset")
		Local $waitHours = _JSONGet($jsonActiveList[$i], "wait_hours")
		Local $needSwitchChar = _JSONGet($jsonActiveList[$i], "need_switch_char")
		Local $charSwithName = _JSONGet($jsonActiveList[$i], "char_swith_name")

		writeLogFile($logFile, "Xu ly nhan vat: " & $charName & " | last_time_reset: " & $lastTimeReset & " | wait_hours: " & $waitHours)

		; Step 7a: Kiem tra ngay trong config khac ngay hien tai -> mo web cap nhat
		Local $lastDay = StringLeft($lastTimeReset, 10)  ; "2026/04/29"
		Local $today = StringLeft(_NowCalc(), 10)         ; "2026/05/04"
		If $lastDay <> $today And $lastTimeReset <> "" And $lastTimeReset <> Default Then
			writeLogFile($logFile, "Ngay khac! lastDay=" & $lastDay & " today=" & $today & " -> Mo web cap nhat thoi gian reset")
			Local $username = _JSONGet($jsonActiveList[$i], "username")
			Local $password = _JSONGet($jsonActiveList[$i], "password")
			updateResetTimeFromWeb($charName, $username, $password, $waitHours)
			; Reload config sau khi cap nhat
			$lastTimeReset = getUpdatedLastTimeReset($charName)
		EndIf

		; Kiem tra thoi gian: last_time_reset + wait_hours vs now
		If Not isTimeToReset($lastTimeReset, $waitHours) Then
			writeLogFile($logFile, "Nhan vat " & $charName & " chua du thoi gian de reset. Bo qua.")
			ContinueLoop
		EndIf

		; Kiem tra cua so game
		Local $mainNo = getMainNoByChar($charName)
		Local $isWindowFound = checkActiveWinByChar($charName)

		; Neu khong tim thay cua so -> thu switch nhan vat
		If Not $isWindowFound Then
			writeLogFile($logFile, "Khong tim thay cua so game cho " & $charName)

			If $needSwitchChar And $charSwithName <> "" And $charSwithName <> Default Then
				writeLogFile($logFile, "Thu tim cua so cua nhan vat " & $charSwithName & " de switch sang " & $charName)

				If checkActiveWinByChar($charSwithName) Then
					writeLogFile($logFile, "Tim thay cua so " & $charSwithName & ", thuc hien switch sang " & $charName)
					activeAndMoveWinByChar($charSwithName)
					switchOtherChar($charName)
					secondWait(5)

					; Kiem tra lai sau khi switch
					$isWindowFound = checkActiveWinByChar($charName)
				Else
					writeLogFile($logFile, "Khong tim thay cua so cua " & $charSwithName & ". Bo qua " & $charName)
				EndIf
			Else
				writeLogFile($logFile, "need_switch_char = false hoac char_swith_name trong. Bo qua " & $charName)
			EndIf
		EndIf

		; Neu van khong tim thay -> bo qua
		If Not $isWindowFound Then
			writeLogFile($logFile, "Khong the mo cua so game cho " & $charName & ". Bo qua.")
			ContinueLoop
		EndIf

		; Thuc hien reset online
		executeResetOnline($charName)
	Next

	writeLogMethodEnd("processResetOnline")
EndFunc   ;==>processResetOnline

; Method: isTimeToReset
; Description: Kiem tra xem da du thoi gian de reset chua (last_time_reset + wait_hours <= now)
Func isTimeToReset($lastTimeReset, $waitHours)
	If $lastTimeReset = "" Or $lastTimeReset = Default Then Return True

	Local $nextResetTime = addHour($lastTimeReset, $waitHours)
	Local $now = _NowCalc()

	writeLogFile($logFile, "Next reset time: " & $nextResetTime & " | Now: " & $now)

	; So sanh: neu now >= nextResetTime thi du dieu kien
	Local $diff = _DateDiff('s', $nextResetTime, $now)
	Return ($diff >= 0)
EndFunc   ;==>isTimeToReset

; Method: executeResetOnline
; Description: Thuc hien chuoi thao tac reset online cho nhan vat
Func executeResetOnline($charName)
	writeLogMethodStart("executeResetOnline", @ScriptLineNumber, $charName)

	; 1. Activate va move cua so game
	activeAndMoveWinByChar($charName)
	; Thuc hien cancel buff shift F neu can thiet
	cancelShiftF()
	sendKeyEnter()
	sendKeyEnter()

	; 2. Tat auto plus hien tai
	writeLogFile($logFile, "Tat auto plus hien tai cho " & $charName)
	stopAutoPlus()
	secondWait(2)

	; 3. Bat auto plus voi tick checkbox reset
	writeLogFile($logFile, "Bat auto plus voi tick reset cho " & $charName)
	startAutoPlusWithReset()
	secondWait(2)

	; 4. Cho 2 phut de thuc hien reset
	writeLogFile($logFile, "Cho 2 phut de reset...")
	minuteWait(2)

	; 5. Tat auto plus
	writeLogFile($logFile, "Tat auto plus sau khi reset cho " & $charName)
	stopAutoPlus()
	secondWait(2)

	; 6. Bat lai auto plus binh thuong (bo tick reset)
	writeLogFile($logFile, "Bat lai auto plus binh thuong cho " & $charName)
	startAutoPlusWithoutReset()
	secondWait(2)

	; 7. An cua so Auto Plus bang F8
    writeLogFile($logFile, "An cua so Auto Plus (F8) cho " & $charName)
    sendKeyF8()

	; 8. Cap nhat last_time_reset vao config file
	updateLastTimeReset($charName)

	writeLogFile($logFile, "Hoan thanh reset online cho " & $charName)
	writeLogMethodEnd("executeResetOnline", @ScriptLineNumber, $charName)
EndFunc   ;==>executeResetOnline

; Method: updateLastTimeReset
; Description: Cap nhat last_time_reset cho nhan vat vao config file
Func updateLastTimeReset($charName)
	writeLogMethodStart("updateLastTimeReset", @ScriptLineNumber, $charName)

	Local $jsonResetOnlineConfig = getJsonFromFile($jsonPathRoot & $resetOnlineConfigFileName)
	Local $now = _NowCalc()

	For $i = 0 To UBound($jsonResetOnlineConfig) - 1
		Local $cfgCharName = _JSONGet($jsonResetOnlineConfig[$i], "char_name")
		If $cfgCharName = $charName Then
			_JSONSet($now, $jsonResetOnlineConfig[$i], "last_time_reset")
			writeLogFile($logFile, "Cap nhat last_time_reset cho " & $charName & " = " & $now)
			ExitLoop
		EndIf
	Next

	setJsonToFileFormat($jsonPathRoot & $resetOnlineConfigFileName, $jsonResetOnlineConfig)

	writeLogMethodEnd("updateLastTimeReset", @ScriptLineNumber, $charName)
EndFunc   ;==>updateLastTimeReset

; Method: updateResetTimeFromWeb
; Description: Mo web, login, lay thoi gian reset tu nhat ky, cap nhat vao config
Func updateResetTimeFromWeb($charName, $username, $password, $waitHours)
    writeLogMethodStart("updateResetTimeFromWeb", @ScriptLineNumber, $charName)

    checkThenCloseChrome()
    Local $sWebSession = SetupChrome()

    Local $isLogin = login($sWebSession, $username, $password)
    If Not $isLogin Then
        writeLogFile($logFile, "Dang nhap web that bai cho " & $charName)
        logoutAndCloseChromeDriver($sWebSession)
        writeLogMethodEnd("updateResetTimeFromWeb", @ScriptLineNumber)
        Return False
    EndIf

    ; Lay log reset tu web
    Local $sLogReset = getLogReset($sWebSession, $charName)
    Local $sTimeReset = getTimeReset($sLogReset, 0)

    writeLogFile($logFile, "Thoi gian reset tu web: " & $sTimeReset & " cho " & $charName)

    ; Cap nhat vao config file
    Local $jsonResetOnlineConfig = getJsonFromFile($jsonPathRoot & $resetOnlineConfigFileName)
    For $j = 0 To UBound($jsonResetOnlineConfig) - 1
        If _JSONGet($jsonResetOnlineConfig[$j], "char_name") = $charName Then
            _JSONSet($sTimeReset, $jsonResetOnlineConfig[$j], "last_time_reset")
            ExitLoop
        EndIf
    Next
    setJsonToFileFormat($jsonPathRoot & $resetOnlineConfigFileName, $jsonResetOnlineConfig)

    logout($sWebSession)
    logoutAndCloseChromeDriver($sWebSession)

    writeLogMethodEnd("updateResetTimeFromWeb", @ScriptLineNumber)
    Return True
EndFunc

; Method: getUpdatedLastTimeReset
; Description: Doc lai last_time_reset tu config file sau khi cap nhat
Func getUpdatedLastTimeReset($charName)
    Local $jsonConfig = getJsonFromFile($jsonPathRoot & $resetOnlineConfigFileName)
    For $j = 0 To UBound($jsonConfig) - 1
        If _JSONGet($jsonConfig[$j], "char_name") = $charName Then
            Return _JSONGet($jsonConfig[$j], "last_time_reset")
        EndIf
    Next
    Return ""
EndFunc
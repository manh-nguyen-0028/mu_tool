#include <date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
;~ #RequireAdmin

Global $timeStartProcess = 0, $sFilePath

;~ start()
testgetTimeWaitNextEvent()

; Method: start
; Description: Entry point cho flow auto devil type=auto_plus.
Func start()
	$sFilePath = $outputPathRoot & "File_Log_AutoDevil_AutoPlus_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	$jsonAccountActiveDevil = mergeInfoAccountDevil("auto_plus")

	writeLogFile($logFile, "Account active devil auto_plus: " & UBound($jsonAccountActiveDevil))
	If UBound($jsonAccountActiveDevil) > 0 Then processGoDevil()

	FileClose($logFile)
	Return True
EndFunc   ;==>start

; Method: processGoDevil
; Description: Loop chính của feature auto plus.
Func processGoDevil()
	While True
		If $timeStartProcess > 10 Then
			$logFile = FileOpen($sFilePath, 1)
			writeLogFile($logFile, "Reset log file after process more than 10 times")
			$timeStartProcess = 0
		Else
			$timeStartProcess += 1
			writeLogFile($logFile, "log $timeStartProcess: " & $timeStartProcess)
		EndIf

		checkThenGoDevilEvent()
	WEnd
EndFunc   ;==>processGoDevil

; Method: checkThenGoDevilEvent
; Description: Chờ đến mốc event, xử lý quick enter, fast join, rồi non-fast.
Func checkThenGoDevilEvent()
	Local $nextTime = getTimeWaitNextEvent(@HOUR, @MIN)
	Local $nextHour = $nextTime[0], $nextMin = $nextTime[1], $nextSec = 20

	$nextTime = createTimeToTicks($nextHour, $nextMin, $nextSec)
	$diffTime = diffTime(getCurrentTime(), $nextTime)

	writeLogFile($logFile, "nextHour: " & $nextHour & " - nextMin: " & $nextMin & " - nextSec: " & $nextSec)
	writeLogFile($logFile, "Current time: " & getCurrentTime() & " - Next time: " & $nextTime & " - Diff time: " & $diffTime)

	If $diffTime >= 0 Then
		If ProcessExists("auto_rs.exe") Then Exit

		writeLogFile($logFile, "Chua toi thoi gian vao devil. Time left: " & timeLeft(getCurrentTime(), $nextTime) & @CRLF)
		Sleep($diffTime)

		Local $jsonAccountActive = processGoEventDevil()
		If UBound($jsonAccountActive) == 0 Then Return
		; Chờ 7 phut sau do thuc hien chuyen sang main chinh
		waitToMinuteMinOrMax(2,32)
		writeLogFile($logFile, "Waited 7 minutes before proceeding to main flow")
		; Chi thuc hien voi nhung nhan vat ko phải fastJoin
		$charRemainNotFastJoin = getRemainAccounts($jsonAccountActive)
		switchToMainChar($charRemainNotFastJoin)
		; Thuc hien cho them 6 phut de thuc hien fast join
		waitToMinuteMinOrMax(7,37)
		writeLogFile($logFile, "Waited until minute 7 or 37 before processing fast join accounts")
		processFastJoinAccounts($jsonAccountActive);
		; Thuc hien hanh dong con lai cho nhung nhan vat khong phai fast join ( cho toi phut 26 hoac den khi het event)
		processRemainAccounts($jsonAccountActive)
	Else
		; getTimeWaitNextEvent() da tinh moc ke tiep, chi cho 5 phut roi tinh lai.
		writeLogFile($logFile, "Current time > Next Time. Cho 5 phut roi tinh lai" & @CRLF)
		minuteWait(5)
		writeLogFile($logFile, "Next While Loop  >>> ")
	EndIf
EndFunc   ;==>checkThenGoDevilEvent

; Method: testgetTimeWaitNextEvent
; Description: Test nhanh logic getTimeWaitNextEvent theo các mốc giờ chính.
Func testgetTimeWaitNextEvent()
	Local $testCases[10][4] = [ _
		[0, 10, 2, 55], _
		[2, 59, 5, 55], _
		[3, 0, 5, 55], _
		[5, 58, 5, 55], _
		[6, 15, 6, 55], _
		[11, 10, 11, 25], _
		[11, 40, 11, 55], _
		[20, 10, 20, 25], _
		[22, 40, 22, 55], _
		[23, 56, 2, 55] _
	]

	Local $passCount = 0
	Local $total = UBound($testCases)

	For $i = 0 To $total - 1
		Local $inputHour = $testCases[$i][0]
		Local $inputMin = $testCases[$i][1]
		Local $expectedHour = $testCases[$i][2]
		Local $expectedMin = $testCases[$i][3]

		Local $actual = getTimeWaitNextEvent($inputHour, $inputMin)
		Local $ok = ($actual[0] == $expectedHour And $actual[1] == $expectedMin)

		Local $msg = "[TEST getTimeWaitNextEvent] input=" & $inputHour & ":" & StringFormat("%02d", $inputMin) & _
			" expected=" & $expectedHour & ":" & StringFormat("%02d", $expectedMin) & _
			" actual=" & $actual[0] & ":" & StringFormat("%02d", $actual[1]) & _
			" => " & ($ok ? "PASS" : "FAIL")

		ConsoleWrite($msg & @CRLF)
		If IsDeclared("logFile") Then writeLogFile($logFile, $msg)

		If $ok Then $passCount += 1
	Next

	Local $summary = "[TEST SUMMARY] getTimeWaitNextEvent PASS " & $passCount & "/" & $total
	ConsoleWrite($summary & @CRLF)
	If IsDeclared("logFile") Then writeLogFile($logFile, $summary)

	Return $passCount == $total
EndFunc

; Method: reloadArrayActive
; Description: Reload danh sách account devil thuộc type auto_plus.
Func reloadArrayActive()
	$jsonAccountActiveDevil = mergeInfoAccountDevil("auto_plus")
	writeLogFile($logFile, "So luong account active auto_plus: " & UBound($jsonAccountActiveDevil))
	Return $jsonAccountActiveDevil
EndFunc

; Method: processGoEventDevil
; Description: Flow rút gọn: active/switch rồi minisize.
Func processGoEventDevil()
	writeLogFile($logFile, "Start method: processGoEvent")
	Local $jsonAccountActiveDevil = reloadArrayActive()

	If UBound($jsonAccountActiveDevil) == 0 Then Return $jsonAccountActiveDevil

	For $i = 0 To UBound($jsonAccountActiveDevil) - 1
		Local $charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
		Local $mainNo = getMainNoByChar($charName)

		If Not activeAndMoveWin($mainNo) Then switchOtherChar($charName)
		minisizeMainByChar($charName)
	Next

	Return $jsonAccountActiveDevil
EndFunc   ;==>processGoEventDevil

; Method: getFastJoinAccounts
; Description: Tách danh sách fast join.
Func getFastJoinAccounts($jsonAccountActiveDevil)
	Local $fastJoinAccounts[0]
	For $i = 0 To UBound($jsonAccountActiveDevil) - 1
		If _JSONGet($jsonAccountActiveDevil[$i], "is_fast_join") Then
			ReDim $fastJoinAccounts[UBound($fastJoinAccounts) + 1]
			$fastJoinAccounts[UBound($fastJoinAccounts) - 1] = $jsonAccountActiveDevil[$i]
		EndIf
	Next
	Return $fastJoinAccounts
EndFunc

; Method: getRemainAccounts
; Description: Tách danh sách không fast join.
Func getRemainAccounts($jsonAccountActiveDevil)
	Local $remainAccounts[0]
	For $i = 0 To UBound($jsonAccountActiveDevil) - 1
		If Not _JSONGet($jsonAccountActiveDevil[$i], "is_fast_join") Then
			ReDim $remainAccounts[UBound($remainAccounts) + 1]
			$remainAccounts[UBound($remainAccounts) - 1] = $jsonAccountActiveDevil[$i]
		EndIf
	Next
	Return $remainAccounts
EndFunc

; Method: processFastJoinAccounts
; Description: Xử lý fast join theo flow move + follow, có chờ 2 phút khi cần follow.
Func processFastJoinAccounts($jsonAccountActiveDevil)
	Local $fastJoinAccounts = getFastJoinAccounts($jsonAccountActiveDevil)
	If UBound($fastJoinAccounts) == 0 Then Return

	writeLogFile($logFile, "Start method: processFastJoinAccounts with accounts: " & convertJsonToString($fastJoinAccounts))

	For $i = 0 To UBound($fastJoinAccounts) - 1
		Local $charInfo = $fastJoinAccounts[$i]
		Local $charName = _JSONGet($charInfo, "char_name")
		Local $isNeedFollowLeader = _JSONGet($charInfo, "is_need_follow_leader")
		Local $mainNo = getMainNoByChar($charName)

		If Not activeAndMoveWin($mainNo) Then switchOtherChar($charName)
		If Not activeAndMoveWin($mainNo) Then ContinueLoop

		; Chờ 2 phút để lên bãi khi có follow leader.
		;~ If $isNeedFollowLeader Then secondWait(120)

		moveOtherMap($charName)
		If $isNeedFollowLeader Then _MU_followLeader(1)

		minisizeMainByChar($charName)
	Next

	; Cho 3 phut de nhan vat len map neu co fast join accounts
	If UBound($fastJoinAccounts) > 0 Then minuteWait(3)

	; Hoàn thành fast join thì loop lại để switch về main chính nếu cho phép.
	switchToMainChar($fastJoinAccounts)
EndFunc

; Method: processRemainAccounts
; Description: Đợi mốc 26/50 rồi move map + start/stop auto plus cho nhóm còn lại.
Func processRemainAccounts($jsonAccountActiveDevil)
	Local $remainAccounts = getRemainAccounts($jsonAccountActiveDevil)
	If UBound($remainAccounts) == 0 Then Return

	waitToMinuteMinOrMax(22,52)

	For $i = 0 To UBound($remainAccounts) - 1
		Local $charName = _JSONGet($remainAccounts[$i], "char_name")
		Local $mainNo = getMainNoByChar($charName)

		If Not activeAndMoveWin($mainNo) Then switchOtherChar($charName)
		If Not activeAndMoveWin($mainNo) Then ContinueLoop

		; Move map and start auto plus if needed
		moveOtherMap($charName, True)
		
		minisizeMainByChar($charName)
	Next

	; Hoàn thành nhóm còn lại thì switch về main chính nếu cho phép.
	; sleep 1 phut sau do chuyen sang main chinh
	minuteWait(1)
	switchToMainChar($remainAccounts)
EndFunc

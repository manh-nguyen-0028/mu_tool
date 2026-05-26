#include <date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../../include/_ImageSearch_UDF.au3"
#RequireAdmin


Global $sCharNotJoinDevil = "", $timeStartProcess = 0, $sFilePath

start()
;~ processGoEventDevil()

; Method: start
; Description: Initializes the logging process, retrieves active devil accounts, and starts the devil event process if there are active accounts.
Func start()
	$sFilePath = $outputPathRoot & "File_Log_AutoDevil_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	$jsonAccountActiveDevil = getArrayActiveDevil()
	writeLogFile($logFile, "Account active devil: " & UBound($jsonAccountActiveDevil))
	If UBound($jsonAccountActiveDevil) > 0 Then processGoDevil()
	FileClose($logFile)
	Return True
EndFunc   ;==>start

; Method: processGoDevil
; Description: Continuously checks and processes the devil event.
Func processGoDevil()
	While True
		; check timeStartProcess. Neu so lan > 10 thi thuc hien xoa noi dung file log di de tranh truong hop file log qua lon va khong mo duoc file log de ghi log tiep. Neu so lan < 10 thi thuc hien ghi log binh thuong
		If $timeStartProcess > 10 Then
			; Ghi đè (write – xóa nội dung cũ)
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
; Description: Determines the next time to check for the devil event based on the current time and handles the event accordingly.
Func checkThenGoDevilEvent()
	; 01 < current hour < 06 => next time = 06h and minute = 00
	; 06 < current hour < 17 => next time = time /2 and minute = 00
	; 17 < current hour < 20 => $nextHour =@HOUR+1
	; 20 < current hour < 22 => if current min < 30 => next time = current hour, min = 30. if current min > 30 => next time = current hour + 1, min = 00
	Local $nextTime = calculateNextDevilEventTime(@HOUR, @MIN)
	Local $nextHour = $nextTime[0], $nextMin = $nextTime[1], $nextSec = 20

	; Danh sách các giờ cần kiểm tra, cách nhau bởi dấu phẩy
	Local $validHours = ",7,10,12,14,16,18,20,21,22,23,"

	; Kiểm tra xem giờ hiện tại có nằm trong danh sách không
	If StringInStr($validHours, "," & $nextHour & ",") Then
		; Truong hop ma dung trong CC thi doi them 1 phut
		$nextMin = $nextMin
	EndIf

	; Truong hop thoi gian hien tai la 23h va phut > 30 thi thoi gian tiep theo se la 00h00 ngay ke tiep
	If @HOUR == 23 And @MIN > 30 Then
		$nextHour = 0
		$nextMin = 0
		$nextSec = 40
		; Thuc hien cho toi 00h00 ngay ke tiep
		$waitMin = 60 - @MIN
		writeLogFile($logFile, "Current time is 23h and min > 30. Sleep until next day: " & $waitMin & " minutes")
		minuteWait($waitMin)
	EndIf

	$nextTime = createTimeToTicks($nextHour, $nextMin, $nextSec)
	$diffTime = diffTime(getCurrentTime(), $nextTime)

	writeLogFile($logFile, "nextHour: " & $nextHour & " - nextMin: " & $nextMin & " - nextSec: " & $nextSec)
	writeLogFile($logFile, "Current time: " & getCurrentTime() & " - Next time: " & $nextTime & " - Diff time: " & $diffTime)

	If $diffTime > 0 Then
		; Check exists auto_rs.exe
		$processName = "auto_rs.exe"
		If ProcessExists($processName) Then Exit
		; Write log
		writeLogFile($logFile, "Chua toi thoi gian vao devil. Time left: " & timeLeft(getCurrentTime(), $nextTime) & @CRLF)
		; Sleep until next time
		$diffTime = diffTime(getCurrentTime(), $nextTime)
		Sleep($diffTime)
		$jsonAccountActive = processGoEventDevil()

		; Check accounts in devil
		$aCharJoinDevil = checkAccountsInDevil($jsonAccountActive)

		; Process fast join accounts $aCharJoinDevil
		processFastJoinAccounts($aCharJoinDevil)
		secondWait(10)

		; process swith main char
		switchToMainChar($aCharJoinDevil)

		;Sleep 26 minute
		sleep26Min($aCharJoinDevil)

		; Rs after go devil success
		writeLogFile($logFile, "Finish event devil")
	Else
		writeLogFile($logFile, "Current time > Next Time. Cho toi gio tiep theo" & @CRLF)
		;Sleep 1h
		waitToNextMinutes(58)
;~ minuteWait(60)
		writeLogFile($logFile, "Sleep 1h finish")
		writeLogFile($logFile, "Next While Loop  >>> ")
	EndIf
EndFunc   ;==>checkThenGoDevilEvent

Func sleep26Min($aCharJoinDevil)
	; Neu $jsonAccountActiveDevil = 0 thi khong can thuc hien sleep
	If UBound($aCharJoinDevil) == 0 Then
		writeLogFile($logFile, "Khong co tai khoan active devil. Ket thuc xu ly sleep26Min")
		Return
	EndIf

	Local $nextMinFollowLeader = 21
	Local $currentTime = getCurrentTime()

	If @MIN >= 30 Then $nextMinFollowLeader = 51

	Local $nextTimeFollowLeader = createTimeToTicks(@HOUR, $nextMinFollowLeader, 10)
	$timeLeft = timeLeft($currentTime, $nextTimeFollowLeader)
	$diffTime = diffTime($currentTime, $nextTimeFollowLeader)
	;~ writeLogFile($logFile, "Current time: " & $currentTime & " - Next time follow leader: " & $nextTimeFollowLeader)
	writeLogFile($logFile, "Time left util next time follow leader: " & $timeLeft)
	Sleep($diffTime)

	; Chi trong truong hop la 20,21,22 moi thuc hien follow leader
	If @HOUR == 20 Or @HOUR == 21 Or @HOUR == 22 Or @HOUR == 11 Then
		writeLogFile($logFile, "Khong phai thoi gian follow leader hoac chuyen main chinh, chi thuc hien xu ly sau khi ket thuc devil")
		;~ $jsonAccountActiveDevil = getArrayActiveDevil()
		For $i = 0 To UBound($aCharJoinDevil) - 1
			If $aCharJoinDevil[$i] <> '' Then
				$charName = _JSONGet($aCharJoinDevil[$i], "char_name")
				$isNeedFollowLeader = _JSONGet($aCharJoinDevil[$i], "is_need_follow_leader")
				; Truong hop khong can follow leader thi khong can xu ly
				If activeAndMoveWinByChar($charName) Then
					handelWhenFinshDevilEvent()
					minisizeMainByChar($charName)
				EndIf
			EndIf
		Next
	Else
		handleAfterDevilEvent($aCharJoinDevil)
		; Thuc hien swith sang main chinh
		;~ $jsonAccountActiveDevil = getArrayActiveDevil()
		switchToMainChar($aCharJoinDevil)
	EndIf
	Return True
EndFunc   ;==>sleep26Min

; Function: calculateNextDevilEventTime
; Description: Calculates the next hour and minute for the devil event based on the current time.
Func calculateNextDevilEventTime($currentHour = @HOUR, $currentMin = @MIN)
	Local $result[2]     ; Mảng để lưu trữ nextHour và nextMin
	Local $nextHour, $nextMin = 0

	Switch $currentHour
		Case 0 To 2
			$nextHour = 3
		Case 3 To 5
			$nextHour = 6
		Case 6 To 10, 12 To 19
			$nextHour = $currentHour + 1
		Case 11, 20 To 22
			If $currentMin < 30 Then
				$nextHour = $currentHour
				$nextMin = 30
			Else
				$nextHour = $currentHour + 1
				$nextMin = 0
			EndIf
		Case 23
			$nextHour = 0
		Case Else
			$nextHour = $currentHour
	EndSwitch

	; Adjust minutes for specific cases
	If $nextHour > @HOUR Then $nextMin = 0

	; Gán giá trị vào mảng
	$result[0] = $nextHour
	$result[1] = $nextMin

	writeLogFile($logFile, "Next hour: " & $nextHour & " - Next min: " & $nextMin)
	; Trả về mảng chứa nextHour và nextMin

	Return $result
EndFunc   ;==>calculateNextDevilEventTime

Func validateAmountDevil($jsonAccountActiveDevil)
	; Truong hop khong co acc active devil thi ket thuc luon
	If UBound($jsonAccountActiveDevil) == 0 Then
		writeLogFile($logFile, "Khong co tai khoan active devil. Ket thuc xu ly validateAmountDevil")
		Return False
	EndIf
	Return True
EndFunc

Func getListFastMove($jsonAccountActiveDevil)
	Local $jsonAccountFastJoin[0]

	; Get account devil fast move
	For $i = 0 To UBound($jsonAccountActiveDevil) - 1
		$isFastMove = _JSONGet($jsonAccountActiveDevil[$i], "is_fast_join")
		If $isFastMove Then
			ReDim $jsonAccountFastJoin[UBound($jsonAccountFastJoin) + 1]
			$jsonAccountFastJoin[UBound($jsonAccountFastJoin) - 1] = $jsonAccountActiveDevil[$i]
		EndIf
	Next
	Return $jsonAccountFastJoin
EndFunc

Func reloadArrayActive()
	$jsonAccountActiveDevil = getArrayActiveDevil()
	writeLogFile($logFile, "So luong account active: " & UBound($jsonAccountActiveDevil))
	Return $jsonAccountActiveDevil
EndFunc

#cs
	Xu ly vao event devil.
	Can check xem da du 400 lvl hay chua. Neu chua du 400 lvl thi thoi khong can vao lam gi
#ce
; Method: goToDevilEvent
; Description: Manages the process of joining the devil event for each active devil account.
Func processGoEventDevil()
	writeLogFile($logFile, "Start method: processGoEvent")
	Local $jsonAccountActiveDevil, $jsonAccountFastJoin
	; Get account devil
	$jsonAccountActiveDevil = reloadArrayActive()

	If Not validateAmountDevil($jsonAccountActiveDevil) Then Return

	$jsonAccountFastJoin = getListFastMove($jsonAccountActiveDevil)

	writeLogFile($logFile, "So luong account active: " & UBound($jsonAccountActiveDevil))

	writeLogFile($logFile, "DEVIL start at: " & @MIN & " phut - " & @SEC & " giay")
	; Go devil
	For $i = 0 To UBound($jsonAccountActiveDevil) - 1
		; Truong hop thoi gian tham gia khac cac phut 0 > 5, 30 -> 35 thi thuc hien thoat khoi vong for
		If (@MIN > 5 And @MIN < 29) Or (@MIN > 35 And @MIN < 59) Then
			writeLogFile($logFile, "Thoi gian khong thich hop de vao devil. Ket thuc xu ly")
			ExitLoop
		EndIf

		If $jsonAccountActiveDevil[$i] <> '' Then
			writeLogFile($logFile, "char item start at: " & @MIN & " phut - " & @SEC & " giay")
			$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
			;~ $checkRuongK = _JSONGet($jsonAccountActiveDevil[$i], "have_ruong_k")
			$checkRuongK = True
			$devilNo = _JSONGet($jsonAccountActiveDevil[$i], "devil_no")
			$isCheck400Lvl = _JSONGet($jsonAccountActiveDevil[$i], "is_check_400lv")
			$isNeedFollowLeader = _JSONGet($jsonAccountActiveDevil[$i], "is_need_follow_leader")
			$mainNo = getMainNoByChar($charName)
			$isHaveQuest = _JSONGet($jsonAccountActiveDevil[$i], "have_quest")

			writeLogFile($logFile, "Account processGoEvent: " & $charName & " - Devil No: " & $devilNo)

			; Truong hop main hien tai khong duoc active, active main khac
			If Not activeAndMoveWin($mainNo) Then switchOtherChar($charName)

			If Not checkActiveWin($mainNo) Then
				writeLogFile($logFile, "Khong tim thay cua so win")
				writeLogFile($logFile, "Ket thuc xu ly: " & $charName)
				ContinueLoop ;
				
			EndIf

			$checkLvl400 = True
			; Check 400 lvl
			If $isCheck400Lvl Then $checkLvl400 = check400LvlImage()

			If Not $checkLvl400 Or (@MIN > 5 And @MIN < 29) Or (@MIN > 35 And @MIN < 59) Then
				$reason = "Khong du dieu kien di devil. Ly do: "
				If Not $checkLvl400 Then $reason = $reason & "Khong du 400 lvl" & @CRLF
				If (@MIN > 5 And @MIN < 29) Then $reason = $reason & "Da qua 5 phut khong the vao" & @CRLF
				If (@MIN > 35 And @MIN < 59) Then $reason = $reason & "Da qua 35 phut khong the vao" & @CRLF
				writeLogFile($logFile, $reason)
				minisizeMain($mainNo)
				ContinueLoop ;
			EndIf

			; Neu check ruong K = 0 thi thuc hien mo ruong K ra xem co khong, sau do moi click devil
			;~ If Not $checkRuongK Then
			;~ 	$checkRuongK = checkRuongK($jsonAccountActiveDevil[$i])
			;~ 	If $checkRuongK Then
			;~ 		$jsonDevilConfig = getJsonFromFile($jsonPathRoot & $devilFileName)
			;~ 		_JSONSet(True, $jsonDevilConfig, $charName & "." & "have_ruong_k")
			;~ 		setJsonToFileFormat($jsonPathRoot & $devilFileName, $jsonDevilConfig)
			;~ 	EndIf
			;~ EndIf

			; Bat dau click icon devil
			clickIconDevil($charName, $checkRuongK, $isHaveQuest)
			secondWait(1)

			; Check and click into NPC devil
			Local $npcX = 0, $npcY = 0
			If searchNpcDevil($charName, $checkRuongK, $devilNo, $isHaveQuest, $npcX, $npcY) Then
				MouseMove($npcX, $npcY)
				secondWait(1)
				; Click into NPC devil
				clickToNpcDevil($npcX, $npcY)
				; check open popup devil
				If checkColorPopUpDevil() Then 
					actionGoDevilSuccess($devilNo)
				Else
					actionGoDevilFail($isNeedFollowLeader)
				EndIf
			EndIf
			
			
			; check
			;~ clickNpcDevil($npmSearchResult, $devilNo, $isNeedFollowLeader)

			minisizeMainByChar($charName)
			writeLogFile($logFile, "char item end at: " & @MIN & " phut - " & @SEC & " giay")
		EndIf
	Next

	writeLogFile($logFile, "DEVIL end at: " & @MIN & " phut - " & @SEC & " giay")

	Return $jsonAccountActiveDevil

EndFunc   ;==>processGoEvent

Func actionGoDevilSuccess($devilNo)
	writeLogFile($logFile, "Thuc hien click vao devil")
	clickPositionByDevilNo($devilNo)
	secondWait(4)
	_MU_Start_AutoZ()
EndFunc

Func actionGoDevilFail($isNeedFollowLeader)
	writeLogFile($logFile, "Khong tim thay vi tri cua popup chon devil")
	If $isNeedFollowLeader Then
		writeLogFile($logFile, "Thuc hien follow leader")
		_MU_followLeader(1)
	EndIf
EndFunc

Func processFastJoinAccounts($aCharJoinDevil)
	writeLogFile($logFile, "Start method: processFastJoinAccounts with accounts: " & convertJsonToString($aCharJoinDevil))

	;Kiem tra cac truong hop join nhanh, khong can doi het event
	Local $nextMinMove = 6
	Local $nextHourMove = @HOUR

	If @MIN >= 30 Then $nextMinMove = 36

	If @HOUR == 0 Or @HOUR == 24 Then
		$nextHourMove = 0
	EndIf

	Local $nextTimeMove = createTimeToTicks($nextHourMove, $nextMinMove, "05")

	$timeLeftGoFastMove = timeLeft(getCurrentTime(), $nextTimeMove)

	$timeDiffNextMove = diffTime(createTimeToTicks(@HOUR, @MIN, @SEC), $nextTimeMove)

	writeLogFile($logFile, "Begin sleep util next fast move: " & $timeDiffNextMove)

	Sleep($timeDiffNextMove)

	For $i = 0 To UBound($aCharJoinDevil) - 1
		Local $charName = _JSONGet($aCharJoinDevil[$i], "char_name")
		Local $needCheckAutoZ = _JSONGet($aCharJoinDevil[$i], "need_check_auto_z")
		Local $mainNo = getMainNoByChar($charName)
		$fastMove = _JSONGet($aCharJoinDevil[$i], "is_fast_join")
		$onAutoPlus = _JSONGet($aCharJoinDevil[$i], "on_auto_plus")

		If $fastMove Then
			writeLogFile($logFile, "Account: " & $charName & " - Fast move ")
			; Truong hop main hien tai khong duoc active, active main khac
			If Not activeAndMoveWin($mainNo) Then $checkActiveWin = switchOtherChar($charName)
			If activeAndMoveWin($mainNo) Then
				; Move other map
				moveOtherMap($charName)
				; follow leader then auto plus
				followLeadThenStartAutoPlus($charName, $onAutoPlus)
				;~ If $needCheckAutoZ Then checkAutoZAfterFollowLead()
				sendKeyF8()
				writeLogFile($logFile, "Account: " & $charName & " - Fast move thanh cong")
			Else
				writeLogFile($logFile, "Account: " & $charName & " - Fast move that bai vi khong active duoc main nao")
			EndIf
		EndIf
	Next
EndFunc

; Method: handleAfterDevilEvent
; Description: Handles the actions to be taken after finishing the devil event for each active devil account.
Func handleAfterDevilEvent($aCharJoinDevil)
	;~ $jsonAccountActiveDevil = $aCharJoinDevil
	For $i = 0 To UBound($aCharJoinDevil) - 1
		If $aCharJoinDevil[$i] <> '' Then
			$charName = _JSONGet($aCharJoinDevil[$i], "char_name")
			$checkRuongK = _JSONGet($aCharJoinDevil[$i], "have_ruong_k")
			$isFastMove = _JSONGet($aCharJoinDevil[$i], "is_fast_join")
			$isNeedFollowLeader = _JSONGet($aCharJoinDevil[$i], "is_need_follow_leader")
			$mainNo = getMainNoByChar($charName)

			writeLogFile($logFile, "Xu ly sau khi ket thuc devil voi Char: " & $charName)

			; Truong hop la $isFastMove = True thi hien continue sang record tiep theo
			If $isFastMove Then
				writeLogFile($logFile, "Char: " & $charName & " - Fast move khong can xu ly sau khi ket thuc devil")
				minisizeMain($mainNo)
				ContinueLoop
			EndIf

			; Truong hop nam trong $charNotJoinDevil thi khong can xu ly
			If StringInStr($sCharNotJoinDevil, $charName) Then
				writeLogFile($logFile, "Char: " & $charName & " - Khong join devil nen khong can xu ly sau khi ket thuc devil")
				minisizeMain($mainNo)
				ContinueLoop
			EndIf

			; Truong hop khong can follow leader thi khong can xu ly
			If Not $isNeedFollowLeader Then
				writeLogFile($logFile, "Char: " & $charName & " - Khong can follow leader => Ket thuc xu ly")
				minisizeMain($mainNo)
				ContinueLoop
			EndIf

			$checkActiveWin = activeAndMoveWin($mainNo)
			$isActiveParentMain = checkActiveParentMain($charName)

			$isNeedHandleAffterEvent = True
			; Truong hop main hien tai khong duoc active va can follow leader thi thuc hien switch main khac
			If Not $checkActiveWin And $isNeedFollowLeader Then
				$checkActiveWin = switchOtherChar($charName)
				; Truong hop active dc main khac thi khong can xu ly sau event
				If $checkActiveWin Then $isNeedHandleAffterEvent = False
			EndIf

			If $checkActiveWin Then
				; Truong $isActiveParentMain = True thi khong handelWhenFinshDevilEvent ma chi follow leader thoi
				If Not $isActiveParentMain Then handelWhenFinshDevilEvent()
				; Check follow leader
				If $isNeedFollowLeader Then
					; Thuc hien chuyen map
					moveOtherMap($charName)
					writeLogFile($logFile, "Char: " & $charName & " - can follow leader => thuc hien follow leader")
					_MU_followLeader(1)
					secondWait(8)
					If Not $checkRuongK And checkRuongK($aCharJoinDevil[$i]) Then
						$jsonDevilConfig = getJsonFromFile($jsonPathRoot & $devilFileName)
						_JSONSet(True, $jsonDevilConfig, $charName & "." & "have_ruong_k")
						setJsonToFileFormat($jsonPathRoot & $devilFileName, $jsonDevilConfig)
					EndIf

					; Them xu ly check xem co active auto_home hay chua. Neu chua co thi doi them 10s
					checkAutoZAfterFollowLead()
				Else
					writeLogFile($logFile, "Char: " & $charName & " - khong can follow leader => Ket thuc xu ly")
				EndIf
				minisizeMain($mainNo)
			EndIf
		EndIf
	Next
EndFunc   ;==>handleAfterDevilEvent

Func checkAccountsInDevil($jsonAccountActiveDevil)
	writeLogFile($logFile, "Start method: checkAccountsInDevil with accounts")
	Local $sCharNotJoinDevil = "", $charJoinSuccess = ""
	; Tao array de luu danh sach char da join devil thanh cong
	Local $aCharJoinDevil[0]

	; Kiem tra xem cac acc da vao dc devil chua
	For $i = 0 To UBound($jsonAccountActiveDevil) - 1
		$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
		$isNeedFollowLeader = _JSONGet($jsonAccountActiveDevil[$i], "is_need_follow_leader")
		$mainNo = getMainNoByChar($charName)

		; Truong hop main hien tai khong duoc active, active main khac
		If Not activeAndMoveWin($mainNo) Then switchOtherChar($charName)

		If activeAndMoveWin($mainNo) Then
			If checkActiveAutoHome()  Then
				writeLogFile($logFile, "Char: " & $charName & " da vao devil thanh cong")
				; Luu lai danh sach char da join devil thanh cong de sau nay xu ly
				ReDim $aCharJoinDevil[UBound($aCharJoinDevil) + 1]
				$aCharJoinDevil[UBound($aCharJoinDevil) - 1] = $charName
				$charJoinSuccess = $charJoinSuccess & $charName & @CRLF
			Else
				writeLogFile($logFile, "Char: " & $charName & " khong vao dc devil")
				$sCharNotJoinDevil = $sCharNotJoinDevil & $charName & @CRLF
				actionWhenCantJoinDevil($isNeedFollowLeader)
			EndIf
			$charInfo = $jsonAccountActiveDevil[$i]
			Local $charName = _JSONGet($charInfo, "char_name")
			Local $swithOtherMain = _JSONGet($charInfo, "switch_other_main")
			Local $mainCharName = _JSONGet($charInfo, "main_char_name")
			; Chi thuc hien khi $swithOtherMain = true va mainCharName khac rong
			If $swithOtherMain And $mainCharName <> "" Then switchToMainCharItem($charName, $mainCharName)
		EndIf
		; Thuc hien an mainNo
		writeLogFile($logFile, "Char: " & $charName & " - Thuc hien an main")
		minisizeMain($mainNo)
	Next

	writeLogFile($logFile, "Char not join devil: " & $sCharNotJoinDevil)
	writeLogFile($logFile, "Char join devil success: " & $charJoinSuccess)
	;~ switchToMainChar($jsonAccountActiveDevil)
	Return $aCharJoinDevil
EndFunc   ;==>checkAccountsInDevil

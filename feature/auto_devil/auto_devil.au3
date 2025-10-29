#include <date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../../include/_ImageSearch_UDF.au3"
#RequireAdmin


Global $sCharNotJoinDevil = ""

start()
;~ processGoEvent()

; Method: start
; Description: Initializes the logging process, retrieves active devil accounts, and starts the devil event process if there are active accounts.
Func start()
	Local $sFilePath = $outputPathRoot & "File_Log_AutoDevil_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	$jsonAccountActiveDevil = getArrayActiveDevil()
	writeLogFile($logFile, "Account active devil: " & UBound($jsonAccountActiveDevil))
	If UBound($jsonAccountActiveDevil) > 0 Then processGoDevil()
	FileClose($logFile)
	Return True
EndFunc

; Method: processGoDevil
; Description: Continuously checks and processes the devil event.
Func processGoDevil()
	While True
		checkThenGoDevilEvent()
	WEnd
EndFunc

; Method: checkThenGoDevilEvent
; Description: Determines the next time to check for the devil event based on the current time and handles the event accordingly.
Func checkThenGoDevilEvent()
	; 01 < current hour < 06 => next time = 06h and minute = 00
	; 06 < current hour < 17 => next time = time /2 and minute = 00
	; 17 < current hour < 20 => $nextHour =@HOUR+1
	; 20 < current hour < 22 => if current min < 30 => next time = current hour, min = 30. if current min > 30 => next time = current hour + 1, min = 00
	Local $nextTime = calculateNextDevilEventTime(@HOUR, @MIN)
    Local $nextHour = $nextTime[0]
    Local $nextMin = $nextTime[1]

	; Danh sách các giờ cần kiểm tra, cách nhau bởi dấu phẩy
	Local $validHours = ",7,10,12,14,16,18,20,21,22,23,"

	; Kiểm tra xem giờ hiện tại có nằm trong danh sách không
	If StringInStr($validHours, "," & $nextHour & ",") Then
		; Truong hop ma dung trong CC thi doi them 1 phut
		$nextMin = $nextMin
	EndIf

	$nextTime = createTimeToTicks($nextHour, $nextMin, "10")
	$diffTime = diffTime(getCurrentTime(), $nextTime) 

	If $diffTime > 0 Then
		; Check exists auto_rs.exe 
		$processName = "auto_rs.exe"
		If ProcessExists($processName) Then Exit
		; Write log
		writeLogFile($logFile, "Chua toi thoi gian vao devil. Time left: " & timeLeft(getCurrentTime() ,$nextTime) & @CRLF)
		; Sleep until next time
		$diffTime = diffTime(getCurrentTime(), $nextTime) 
		Sleep($diffTime)
		processGoEvent()
		;Sleep 26 minute
		sleep26Min($nextHour)

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
EndFunc

Func sleep26Min($nextHour)
	Local $nextMinFollowLeader = 21, $secondFollowLeader = 10
	Local $nextHourFollowLeader = $nextHour
	Local $currentTime = getCurrentTime()

	If @MIN >= 30 Then $nextMinFollowLeader = 51

	Local $nextTimeFollowLeader = createTimeToTicks($nextHourFollowLeader, $nextMinFollowLeader, $secondFollowLeader)
	$timeLeft = timeLeft($currentTime, $nextTimeFollowLeader)
	$diffTime = diffTime($currentTime, $nextTimeFollowLeader)
	writeLogFile($logFile, "Current time: " & $currentTime & " - Next time follow leader: " & $nextTimeFollowLeader)
	writeLogFile($logFile, "Time left util next time follow leader: " & $timeLeft)
	Sleep($diffTime)

	; Chi trong truong hop la 20,21,22 moi thuc hien follow leader
	If @HOUR == 20 Or @HOUR == 21 Or @HOUR == 22 Or @HOUR == 11 Then
		writeLogFile($logFile, "Khong phai thoi gian follow leader hoac chuyen main chinh, chi thuc hien xu ly sau khi ket thuc devil")
		$jsonAccountActiveDevil = getArrayActiveDevil()
		For $i = 0 To UBound($jsonAccountActiveDevil) -1
			If $jsonAccountActiveDevil[$i] <> '' Then
				$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
				$isNeedFollowLeader = _JSONGet($jsonAccountActiveDevil[$i], "is_need_follow_leader")
				; Truong hop khong can follow leader thi khong can xu ly
				If Not $isNeedFollowLeader Then ContinueLoop
				$mainNo = getMainNoByChar($charName)
				If activeAndMoveWin($mainNo) Then 
					handelWhenFinshDevilEvent()
					minisizeMain($mainNo)
				EndIf
			EndIf
		Next
	Else
		handleAfterDevilEvent()
		; Thuc hien swith sang main chinh
		$jsonAccountActiveDevil = getArrayActiveDevil()
		switchToMainChar($jsonAccountActiveDevil)
	EndIf
	Return True
EndFunc

; Function: calculateNextDevilEventTime
; Description: Calculates the next hour and minute for the devil event based on the current time.
Func calculateNextDevilEventTime($currentHour = @HOUR, $currentMin = @MIN)
    Local $result[2] ; Mảng để lưu trữ nextHour và nextMin
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
EndFunc

#cs
	Xu ly vao event devil.
	Can check xem da du 400 lvl hay chua. Neu chua du 400 lvl thi thoi khong can vao lam gi
#ce
; Method: goToDevilEvent
; Description: Manages the process of joining the devil event for each active devil account.
Func processGoEvent()
	writeLogFile($logFile, "Start method: processGoEvent")
	; Get account devil
	$jsonAccountActiveDevil = getArrayActiveDevil()

	Local $jsonAccountFastJoin[0]

	; Get account devil fast move
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		$isFastMove = _JSONGet($jsonAccountActiveDevil[$i], "is_fast_join")
		If $isFastMove Then
			Redim $jsonAccountFastJoin[UBound($jsonAccountFastJoin) + 1]
			$jsonAccountFastJoin[UBound($jsonAccountFastJoin) - 1] = $jsonAccountActiveDevil[$i]
		EndIf
	Next

	; Go devil
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		; Truong hop thoi gian tham gia khac cac phut 0 > 5, 30 -> 35 thi thuc hien thoat khoi vong for
		If (@MIN > 5 And @MIN < 29) Or (@MIN > 35 And @MIN < 59) Then 
			writeLogFile($logFile, "Thoi gian khong thich hop de vao devil. Ket thuc xu ly")
			ExitLoop
		EndIf
		
		If $jsonAccountActiveDevil[$i] <> '' Then
			$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
			$checkRuongK = _JSONGet($jsonAccountActiveDevil[$i], "have_ruong_k")
			$devilNo = _JSONGet($jsonAccountActiveDevil[$i], "devil_no")
			$isCheck400Lvl = _JSONGet($jsonAccountActiveDevil[$i], "is_check_400lv")
			$isNeedFollowLeader = _JSONGet($jsonAccountActiveDevil[$i], "is_need_follow_leader")
			$mainNo = getMainNoByChar($charName)

			writeLogFile($logFile, "Account: " & $charName & " - Devil No: " & $devilNo)

			; Truong hop main hien tai khong duoc active, active main khac
			If Not activeAndMoveWin($mainNo) Then switchOtherChar($charName)

			If Not activeAndMoveWin($mainNo) Then 
				writeLogFile($logFile, "Khong tim thay cua so win")
				writeLogFile($logFile, "Ket thuc xu ly: " & $charName)
				ContinueLoop;
			EndIf

			$checkLvl400 = True
			; Check 400 lvl
			If $isCheck400Lvl Then $checkLvl400 = checkLvl400($mainNo)

			If Not $checkLvl400 Or (@MIN > 5 And @MIN < 29) Or (@MIN > 35 And @MIN < 59) Then 
				$reason = "Khong du dieu kien di devil. Ly do: "
				If Not $checkLvl400 Then $reason = $reason & "Khong du 400 lvl" & @CRLF
				If (@MIN > 5 And @MIN < 29) Then $reason = $reason & "Da qua 5 phut khong the vao" & @CRLF
				If (@MIN > 35 And @MIN < 59) Then $reason = $reason & "Da qua 35 phut khong the vao" & @CRLF					
				writeLogFile($logFile, $reason)
				minisizeMain($mainNo)
				ContinueLoop;
			EndIf

			; Neu check ruong K = 0 thi thuc hien mo ruong K ra xem co khong, sau do moi click devil
			If Not $checkRuongK Then
				$checkRuongK = checkRuongK($jsonAccountActiveDevil[$i])
				If $checkRuongK Then 
					$jsonDevilConfig = getJsonFromFile($jsonPathRoot & $devilFileName)
					_JSONSet(True, $jsonDevilConfig, $charName & "." & "have_ruong_k")
					setJsonToFileFormat($jsonPathRoot & $devilFileName, $jsonDevilConfig)
				EndIf
			EndIf

			; Thuc hien send enter 1 lan truoc khi click icon devil
			sendKeyEnter()
			secondWait(1)

			; Bat dau click icon devil
			clickIconDevil($checkRuongK)

			; Check and click into NPC devil
			$npmSearchResult = searchNpcDevil($checkRuongK, $devilNo)

			; Click into NPC devil
			clickNpcDevil($npmSearchResult, $devilNo, $isNeedFollowLeader)

			minisizeMain($mainNo)
		EndIf
	Next

	secondWait(5)
	
	; Check accounts in devil
	checkAccountsInDevil($jsonAccountActiveDevil, $isNeedFollowLeader)

	; Process fast join accounts
	processFastJoinAccounts($jsonAccountFastJoin)
	secondWait(30)
	switchToMainChar($jsonAccountActiveDevil)

	writeLogFile($logFile, "Finish processGoEvent")

EndFunc

Func processFastJoinAccounts($jsonAccountFastJoin)
    writeLogFile($logFile, "Start method: processFastJoinAccounts with accounts: " & convertJsonToString($jsonAccountFastJoin))
    
	;Kiem tra cac truong hop join nhanh, khong can doi het event
	Local $nextMinMove = 6
	Local $nextHourMove = @HOUR

	If @MIN >= 30 Then $nextMinMove = 36

	If @HOUR == 0 Or @HOUR == 24 Then
		$nextHourMove = 0
	EndIf

	Local $nextTimeMove = createTimeToTicks($nextHourMove, $nextMinMove, "05")

	$timeLeftGoFastMove = timeLeft(getCurrentTime(), $nextTimeMove)

	writeLogFile($logFile, "Time left util next fast move: " & $timeLeftGoFastMove )

	$timeDiffNextMove = diffTime(createTimeToTicks(@HOUR, @MIN, @SEC), $nextTimeMove)

	writeLogFile($logFile, "Begin sleep util next fast move: " & $timeDiffNextMove )

	Sleep($timeDiffNextMove)

    For $i = 0 To UBound($jsonAccountFastJoin) - 1
        Local $charName = _JSONGet($jsonAccountFastJoin[$i], "char_name")
        Local $mainNo = getMainNoByChar($charName)
        
        Local $checkActiveWin = activeAndMoveWin($mainNo)
        secondWait(2)

        ; Truong hop main hien tai khong duoc active, active main khac
        If $checkActiveWin == False Then $checkActiveWin = switchOtherChar($charName)

        ; Move other map
        moveOtherMap($charName)

        _MU_followLeader(1)    
        
		checkAutoZAfterFollowLead()
		
		minisizeMain($mainNo)
    Next
EndFunc

; Method: handleAfterDevilEvent
; Description: Handles the actions to be taken after finishing the devil event for each active devil account.
Func handleAfterDevilEvent()
	$jsonAccountActiveDevil = getArrayActiveDevil()
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		If $jsonAccountActiveDevil[$i] <> '' Then
			$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
			$checkRuongK = _JSONGet($jsonAccountActiveDevil[$i], "have_ruong_k")
			$isFastMove = _JSONGet($jsonAccountActiveDevil[$i], "is_fast_join")
			$isNeedFollowLeader = _JSONGet($jsonAccountActiveDevil[$i], "is_need_follow_leader")
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

			$isNeedHandleAffterEvent = True
			; Truong hop main hien tai khong duoc active va can follow leader thi thuc hien switch main khac
			If Not $checkActiveWin And $isNeedFollowLeader Then 
				$checkActiveWin = switchOtherChar($charName)
				; Truong hop active dc main khac thi khong can xu ly sau event
				If $checkActiveWin Then $isNeedHandleAffterEvent = False
			EndIf
			
			; Trong truong hop khong duoc active auto home thi moi xu ly sau event + follow leader
			;~ $checkActiveAutoHome = checkActiveAutoHome()

			If $checkActiveWin Then 
				;~ If $isNeedHandleAffterEvent Then 
					handelWhenFinshDevilEvent()
				;~ EndIf
				; Check follow leader
				If $isNeedFollowLeader Then
					; Thuc hien chuyen map
					moveOtherMap($charName)
					writeLogFile($logFile, "Char: " & $charName & " - can follow leader => thuc hien follow leader")
					_MU_followLeader(1)
					secondWait(8)
					If Not $checkRuongK And checkRuongK($jsonAccountActiveDevil[$i]) Then
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
EndFunc

Func checkAccountsInDevil($jsonAccountActiveDevil, $isNeedFollowLeader)
    writeLogFile($logFile, "Start method: checkAccountsInDevil with accounts: " & convertJsonToString($jsonAccountActiveDevil))
	Local $sCharNotJoinDevil = ""
    
    ; Kiem tra xem cac acc da vao dc devil chua
    For $i = 0 To UBound($jsonAccountActiveDevil) - 1
        Local $charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
        Local $mainNo = getMainNoByChar($charName)
        
        ; Truong hop main hien tai khong duoc active, active main khac
        If Not activeAndMoveWin($mainNo) Then switchOtherChar($charName)

        If activeAndMoveWin($mainNo) And Not checkActiveAutoHome() Then
			$sCharNotJoinDevil = $sCharNotJoinDevil & $charName & @CRLF
            actionWhenCantJoinDevil($isNeedFollowLeader)
        EndIf
        minisizeMain($mainNo)
    Next

	writeLogFile($logFile, "Char not join devil: " & $sCharNotJoinDevil)
EndFunc
#include <date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../../include/_ImageSearch_UDF.au3"
#RequireAdmin

Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC

start()

; Method: start
; Description: Initializes the logging process, retrieves active devil accounts, and starts the devil event process if there are active accounts.
Func start()
	Local $sFilePath = $outputPathRoot & "File_Log_AutoDevil_.txt"
	$logFile = FileOpen($sFilePath, $FO_APPEND)
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
	Return True
EndFunc

; Method: checkThenGoDevilEvent
; Description: Determines the next time to check for the devil event based on the current time and handles the event accordingly.
Func checkThenGoDevilEvent()
	; 01 < current hour < 06 => next time = 06h and minute = 00
	; 06 < current hour < 17 => next time = time /2 and minute = 00
	; 17 < current hour < 20 => $nextHour =@HOUR+1
	; 20 < current hour < 22 => if current min < 30 => next time = current hour, min = 30. if current min > 30 => next time = current hour + 1, min = 00
	Switch @HOUR
			Case 0 To 2
					$nextHour = 3
			Case 3 To 5
					$nextHour = 6
			Case 6 To 10
					$nextHour = @HOUR + 1
			Case 11 To 11
				If @MIN < 30 Then 
					$nextHour =@HOUR
					$nextMin = 30
				Else
					$nextHour = @HOUR + 1
					$nextMin = 00
				EndIf
			Case 12 To 19
				$nextHour =@HOUR+1			
			Case 20 To 22
				If @MIN < 30 Then 
					$nextHour =@HOUR
					$nextMin = 30
				Else
					$nextHour = @HOUR+1
					$nextMin = 00
				EndIf
				;~ $nextHour = 23
			Case 23 To 23
				$nextHour =@HOUR+1
			Case Else
				$nextHour = @HOUR
	EndSwitch

	If $nextHour > @HOUR Then $nextMin = 00
	
	$nextMin = $nextMin + 1
	
	$nextTime = createTimeToTicks($nextHour, $nextMin, "05")
	$diffTime = diffTime(getCurrentTime(), $nextTime) 

	If $diffTime > 0 Then
		; Check exists auto_rs.exe 
		$processName = "auto_rs.exe"
		If ProcessExists($processName) Then Exit
		writeLogFile($logFile, "Wait to go to devil event. Time left: " & timeLeft(getCurrentTime() ,$nextTime) & @CRLF)
		$diffTime = diffTime(getCurrentTime(), $nextTime) 
		Sleep($diffTime)
		writeLogFile($logFile, "Begin go to devil event !")
		goToDevilEvent()
		;Sleep 25 minute
		Local $nextMinFollowLeader = $nextMin + 26
		Local $nextHourFollowLeader = $nextHour

		If @MIN >= 30 Then 
			$nextMinFollowLeader = 56
		Else
			$nextMinFollowLeader = 26
		EndIf

		If @HOUR == 0 Then
			$nextMinFollowLeader = 26
			$nextHourFollowLeader = 0
		EndIf

		Local $nextTimeFollowLeader = createTimeToTicks($nextHourFollowLeader, $nextMinFollowLeader, "05")
		writeLogFile($logFile, "Time left util next time follow leader: " & timeLeft(getCurrentTime(), $nextTimeFollowLeader) )
		Sleep(diffTime(createTimeToTicks(@HOUR, @MIN, @SEC), $nextTimeFollowLeader) )
		_MU_handleWhenFinishEvent()
		minuteWait(1)
		; Rs after go devil success
		writeLogFile($logFile, "Finish event devil")
	Else
		writeLogFile($logFile, "Current time > Next Time. Begin sleep 1h. Time left: " & timeToText(60*60*1000)& @CRLF)
		;Sleep 1h
		minuteWait(60)
		writeLogFile($logFile, "Sleep 1h finish")
		writeLogFile($logFile, "Next While Loop  >>> ")
	EndIf
EndFunc

#cs
	Xu ly vao event devil.
	Can check xem da du 400 lvl hay chua. Neu chua du 400 lvl thi thoi khong can vao lam gi
#ce
; Method: goToDevilEvent
; Description: Manages the process of joining the devil event for each active devil account.
Func goToDevilEvent()
	; Get account devil
	$jsonAccountActiveDevil = getArrayActiveDevil()

	Local $jsonAccountFastJoin[0]

	; Get account devil fast move
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		$isFastMove = _JSONGet($jsonAccountActiveDevil[$i], "is_fast_join")
		If $isFastMove == True Then
			Redim $jsonAccountFastJoin[UBound($jsonAccountFastJoin) + 1]
			$jsonAccountFastJoin[UBound($jsonAccountFastJoin) - 1] = $jsonAccountActiveDevil[$i]
		EndIf
	Next

	; Go devil
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		If $jsonAccountActiveDevil[$i] <> '' Then
			writeLogFile($logFile, "Current account go devil : " & $jsonAccountActiveDevil[$i])
			$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
			$checkRuongK = _JSONGet($jsonAccountActiveDevil[$i], "have_ruong_k")
			$devilNo = _JSONGet($jsonAccountActiveDevil[$i], "devil_no")
			$mainNo = getMainNoByChar($charName)
			writeLogFile($logFile, "Dang xu ly voi nhan vat " & $charName & " .Main no: " & $mainNo & " . HaveRuongK : " & $checkRuongK)
			; check active win
			$checkActiveWin = activeAndMoveWin($mainNo)

			; Truong hop main hien tai khong duoc active, active main khac
			If $checkActiveWin == False Then $checkActiveWin = switchOtherChar($charName)

			$checkLvl400 = checkLvl400($mainNo)

			If Not $checkActiveWin Or Not $checkLvl400 Or @MIN > 5 Then 
				$reason = "Khong du dieu kien di devil. Ly do: "
				If Not $checkActiveWin Then $reason = $reason & "Khong tim thay cua so win" & @CRLF
				If Not $checkLvl400 Then $reason = $reason & "Khong du 400 lvl" & @CRLF
				If @MIN > 5 Then $reason = $reason & "Da qua 5 phut khong the vao" & @CRLF
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
			$checkActiveWin = activeAndMoveWin($mainNo)
			_MU_Join_Event_Devil($checkRuongK)
			_MU_Search_Localtion($checkRuongK, $devilNo)
			secondWait(1)
			minisizeMain($mainNo)
		EndIf
	Next

	secondWait(5)
	
	; Check accounts in devil
	checkAccountsInDevil($jsonAccountActiveDevil)

	; Process fast join accounts
	processFastJoinAccounts($jsonAccountFastJoin)

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
        moveOtherMap()

        secondWait(3)

        _MU_followLeader(1)    
        
		checkAutoZAfterFollowLead()
		
		minisizeMain($mainNo)
    Next
EndFunc

; Method: _MU_Search_Localtion
; Description: Searches for the NPC location during the devil event and clicks on it if found.
Func _MU_Search_Localtion($checkRuongK, $devilNo)
	writeLogFile($logFile, "Bat dau tim kiem vi tri cua nhan vat. _MU_Search_Localtion")
	Local $searchPixel = PixelSearch(0,0,720, 793,0xB9AA95);
	writeLogFile($logFile, "searchPixel : " & $searchPixel)
	$countSerchPixel = 0;
	$totalSearch = 0;
	;~ 671 1050
	While $searchPixel  = 0 And $totalSearch < 5
		$searchPixel = PixelSearch(0,0,720, 793,0xB9AA95);
		$countSerchPixel = $countSerchPixel + 1;
		secondWait(1)
		; Nếu tìm quá 3 lần ko thấy thì thực hiện click vao event devil
		While $searchPixel  = 0 And $countSerchPixel < 3
			_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_devil.move_check_npc_x"), _JSONGet($jsonPositionConfig,"button.event_devil.move_check_npc_y"))
			$searchPixel = PixelSearch(0,0,720, 793,0xB9AA95);
			$countSerchPixel = $countSerchPixel + 1;
		WEnd
		If $searchPixel  = 0 And $countSerchPixel > 3 Then
			_MU_Join_Event_Devil($checkRuongK)
			$totalSearch = $totalSearch + 1
		EndIf
	WEnd
	; Neu tim thay toa do thi click vao npc
	clickIntoNpcDevil($searchPixel, $devilNo)
EndFunc

; Method: clickIntoNpcDevil
; Description: Clicks on the NPC devil based on the search results and initiates the devil event.
Func clickIntoNpcDevil($searchPixel, $devilNo)
	; Kiem tra xem co tim duoc vi tri cua npc khong $searchPixel <> 0
	If $searchPixel <> 0 Then
		writeLogFile($logFile, "searchPixel : " & $searchPixel[1]& "-" & $searchPixel[0])
		$npcX = $searchPixel[0]-10
		$npcY = $searchPixel[1] + 20
		mouseClickDelayAlt($npcX, $npcY)
		secondWait(1)
		; Doan nay check xem co mo duoc bang devil hay khong ? Thuc hien check ma mau, neu tim thay thi moi click vao devil + bat autoZ
		$devil_open_x = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_x")
		$devil_open_y = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_y")
		$devil_open_color = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_color")
		
		$checkOpenDevil = checkPixelColor($devil_open_x, $devil_open_y, $devil_open_color)
		If $checkOpenDevil Then
			clickPositionByDevilNo($devilNo)
			secondWait(4)
			_MU_MouseClick_Delay(512, 477)
			_MU_Start_AutoZ()
		Else
			_MU_followLeader(1)
		EndIf
	Else
		_MU_followLeader(1)
	EndIf
EndFunc

; Method: clickPositionByDevilNo
; Description: Clicks on the specific devil event icon based on the devil number.
Func clickPositionByDevilNo($devilNo)
	writeLogFile($logFile, "Click position by devil no: " & $devilNo)
	$devil_position_x = _JSONGet($jsonPositionConfig,"button.event_devil_icon.devil_" & $devilNo & "_x")
	$devil_position_y = _JSONGet($jsonPositionConfig,"button.event_devil_icon.devil_" & $devilNo & "_y")
	writeLogFile($logFile, "Click position x: " & $devil_position_x & " y: " & $devil_position_y)
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,$devil_position_x), _JSONGet($jsonPositionConfig,$devil_position_y))
EndFunc

; Method: _MU_handleWhenFinishEvent
; Description: Handles the actions to be taken after finishing the devil event for each active devil account.
Func _MU_handleWhenFinishEvent()
	$jsonAccountActiveDevil = getArrayActiveDevil()
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		If $jsonAccountActiveDevil[$i] <> '' Then
			writeLogFile($logFile, "Handle when finish event account : " & $jsonAccountActiveDevil[$i])
			$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
			$checkRuongK = _JSONGet($jsonAccountActiveDevil[$i], "have_ruong_k")
			$mainNo = getMainNoByChar($charName)
			$checkActiveWin = activeAndMoveWin($mainNo)

			; Truong hop main hien tai khong duoc active, active main khac
			If $checkActiveWin == False Then $checkActiveWin = switchOtherChar($charName)
			
			; Trong truong hop khong duoc active auto home thi moi xu ly sau event + follow leader
				$checkActiveAutoHome = checkActiveAutoHome()

			If $checkActiveWin Then 
				handelWhenFinshDevilEvent()
				_MU_followLeader(1)
				secondWait(8)
				If Not $checkRuongK And checkRuongK($jsonAccountActiveDevil[$i]) Then
					$jsonDevilConfig = getJsonFromFile($jsonPathRoot & $devilFileName)
					_JSONSet(True, $jsonDevilConfig, $charName & "." & "have_ruong_k")
					setJsonToFileFormat($jsonPathRoot & $devilFileName, $jsonDevilConfig)
				EndIf
				; Them xu ly check xem co active auto_home hay chua. Neu chua co thi doi them 10s
				$checkActiveAutoHome = checkActiveAutoHome()
				$countWaitAutoHome = 0
				While $checkActiveAutoHome == False And $countWaitAutoHome < 2
					secondWait(10)
					$checkActiveAutoHome = checkActiveAutoHome()
					$countWaitAutoHome += 1
				WEnd
				minisizeMain($mainNo)
			EndIf
		EndIf
	Next
EndFunc

Func checkAccountsInDevil($jsonAccountActiveDevil)
    writeLogFile($logFile, "Start method: checkAccountsInDevil with accounts: " & convertJsonToString($jsonAccountActiveDevil))
	Local $sCharNotJoinDevil = ""
    
    ; Kiem tra xem cac acc da vao dc devil chua
    For $i = 0 To UBound($jsonAccountActiveDevil) - 1
        Local $charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
        Local $mainNo = getMainNoByChar($charName)
        Local $checkActiveWin = activeAndMoveWin($mainNo)
        
        ; Truong hop main hien tai khong duoc active, active main khac
        If Not $checkActiveWin Then $checkActiveWin = switchOtherChar($charName)

        If $checkActiveWin And checkActiveAutoHome() == False Then
			$sCharNotJoinDevil = $sCharNotJoinDevil & $charName & @CRLF
            actionWhenCantJoinDevil()
        EndIf

        minisizeMain($mainNo)
    Next

	writeLogFile($logFile, "Char not join devil: " & $sCharNotJoinDevil)
EndFunc
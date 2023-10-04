#include <date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../../include/_ImageSearch_UDF.au3"
#RequireAdmin

start()

Func start()
	$jsonAccountActiveDevil = getArrayActiveDevil()
	writeLog("Account active devil: " & UBound($jsonAccountActiveDevil))
	If UBound($jsonAccountActiveDevil) > 0 Then processGoDevil()
	Return True
EndFunc

Func processGoDevil()
	While True
		checkThenGoDevilEvent()
	WEnd
	Return True
EndFunc

Func checkThenGoDevilEvent()
	; 01 < current hour < 06 => next time = 06h and minute = 00
	; 06 < current hour < 17 => next time = time /2 and minute = 00
	; 17 < current hour < 20 => $nextHour =@HOUR+1
	; 20 < current hour < 22 => if current min < 30 => next time = current hour, min = 30. if current min > 30 => next time = current hour+1, min = 00
	Switch @HOUR
			Case 0 To 2
					$nextHour = 3
			Case 3 To 5
					$nextHour = 6
			Case 6 To 10
					$nextHour =@HOUR+1
			Case 11 To 11
				If @MIN < 30 Then 
					$nextHour =@HOUR
					$nextMin = 30
				Else
					$nextHour = @HOUR+1
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
			Case 23 To 23
				$nextHour =@HOUR+1
			Case Else
				$nextHour = @HOUR
	EndSwitch

	If $nextHour > @HOUR Then $nextMin = 00
	
	$nextTime = createTimeToTicks($nextHour, $nextMin, "05")
	$diffTime = diffTime(getCurrentTime(), $nextTime) 

	If $diffTime > 0 Then
		; Check exists auto_rs.exe 
		$processName = "auto_rs.exe"
		If ProcessExists($processName) Then Exit
		writeLog("Wait to go to devil event. Time left: " & timeLeft(getCurrentTime() ,$nextTime) & @CRLF)
		$diffTime = diffTime(getCurrentTime(), $nextTime) 
		Sleep($diffTime)
		writeLog("Begin go to devil event !")
		goToDevilEvent()
		;Sleep 25 minute
		Local $nextMinFollowLeader = $nextMin + 26
		Local $nextHourFollowLeader = $nextHour
		If @HOUR = 0 Then
			$nextMinFollowLeader = 26
			$nextHourFollowLeader = 0
		EndIf
		Local $nextTimeFollowLeader = createTimeToTicks($nextHourFollowLeader, $nextMinFollowLeader, "05")
		writeLog("Time left util next time follow leader: " & timeLeft(getCurrentTime(), $nextTimeFollowLeader) )
		Sleep(diffTime(createTimeToTicks(@HOUR, @MIN, @SEC), $nextTimeFollowLeader) )
		_MU_handleWhenFinishEvent()
		minuteWait(1)
		; Rs after go devil success
		writeLog("Finish event devil")
	Else
		writeLog("Current time > Next Time. Begin sleep 1h. Time left: " & timeToText(60*60*1000)& @CRLF)
		;Sleep 1h
		minuteWait(60)
		writeLog("Sleep 1h finish")
		writeLog("Next While Loop  >>> ")
	EndIf
EndFunc

#cs
	Xu ly vao event devil.
	Can check xem da du 400 lvl hay chua. Neu chua du 400 lvl thi thoi khong can vao lam gi
#ce
Func goToDevilEvent()
	; Get account devil
	$jsonAccountActiveDevil = getArrayActiveDevil()
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		If $jsonAccountActiveDevil[$i] <> '' Then
			writeLog("Current account go devil : " & $jsonAccountActiveDevil[$i])
			$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
			$checkRuongK = _JSONGet($jsonAccountActiveDevil[$i], "have_ruong_k")
			$devilNo = _JSONGet($jsonAccountActiveDevil[$i], "devil_no")
			$mainNo = getMainNoByChar($charName)
			writeLog("Dang xu ly voi nhan vat " & $charName & " .Main no: " & $mainNo & " . HaveRuongK : " & $checkRuongK)
			; check active win
			$checkActiveWin = activeAndMoveWin($mainNo)
			$checkLvl400 = checkLvl400($mainNo)
			$activeStatus = "1"
			If $activeStatus == "0" Or $checkActiveWin == False Or $checkLvl400 == False Then 
				$reason = ""
				If $activeStatus == "0" Then $reason = $reason & "Account khong duoc kich hoat di devil" & @CRLF
				If $checkActiveWin == False Then $reason = $reason & "Khong tim thay cua so win" & @CRLF
				If $checkLvl400 == False Then $reason = $reason & "Khong du 400 lvl" & @CRLF
				writeLog("Khong du dieu kien di devil. Ly do: " & $reason)
				minisizeMain($mainNo)
				ContinueLoop;
			EndIf
			handelWhenFinshDevilEvent()
			; Neu check ruong K = 0 thi thuc hien mo ruong K ra xem co khong, sau do moi click devil
			If $checkRuongK == False Then
				$checkRuongK = checkRuongK($jsonAccountActiveDevil[$i])
				If $checkRuongK == True Then 
					$jsonDevilConfig = getJsonFromFile($jsonPathRoot & "devil_config.json")
					_JSONSet(True, $jsonDevilConfig, $charName & "." & "have_ruong_k")
					setJsonToFileFormat($jsonPathRoot & "devil_config.json", $jsonDevilConfig)
				EndIf
			EndIf
			$checkActiveWin = activeAndMoveWin($mainNo)
			_MU_Join_Event_Devil($checkRuongK)
			_MU_Search_Localtion($checkRuongK, $devilNo)
			secondWait(1)
			minisizeMain($mainNo)
		EndIf
	Next

	minuteWait(1)
	
	; Kiem tra xem cac acc da vao dc devil chua
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
		$mainNo = getMainNoByChar($charName)
		$checkActiveWin = activeAndMoveWin($mainNo)
		secondWait(2)
		If $checkActiveWin == True And checkActiveAutoHome() == False Then 
			handelWhenFinshDevilEvent()
			_MU_followLeader(1)
		EndIf
		minisizeMain($mainNo)
	Next

	writeLog("Da vao event devil tat ca cac acc !");
	; Kiem tra neu Mod(@HOUR,4) ==0 => thuc hien rut rs  
	writeLog("Gia tri check mod Mod(@HOUR,4) : " & Mod(@HOUR,4) ==0)
EndFunc

Func _MU_Search_Localtion($checkRuongK, $devilNo)
	writeLog("Bat dau tim kiem vi tri cua nhan vat. _MU_Search_Localtion")
	Local $searchPixel = PixelSearch(0,0,720, 793,0xB9AA95);
	writeLog("searchPixel : " & $searchPixel)
	$countSerchPixel = 0;
	$totalSearch = 0;
	;~ 671 1050
	While $searchPixel  = 0 And $totalSearch < 5
		$searchPixel = PixelSearch(0,0,720, 793,0xB9AA95);
		$countSerchPixel = $countSerchPixel + 1;
		secondWait(1)
		; Nếu tìm quá 3 lần ko thấy thì thực hiện click vao event devil
		While $searchPixel  = 0 And $countSerchPixel < 3
			_MU_MouseClick_Delay(483,371)
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

Func clickIntoNpcDevil($searchPixel, $devilNo)
	; Kiem tra xem co tim duoc vi tri cua npc khong $searchPixel <> 0
	If $searchPixel <> 0 Then
		writeLog("searchPixel : " & $searchPixel[1]& "-" & $searchPixel[0])
		$npcX = $searchPixel[0]-10
		$npcY = $searchPixel[1] + 20
		MouseMove($npcX,$npcY)
		Send("{ALTDOWN}")
		_MU_MouseClick_Delay($npcX, $npcY)
		Sleep(1000)
		Send("{ALTUP}")
		secondWait(2)
		_MU_Click_Devil($devilNo)
		secondWait(4)
		_MU_MouseClick_Delay(512, 477)
		_MU_Start_AutoZ()
	Else
		_MU_followLeader(1)
	EndIf
EndFunc

Func _MU_Click_Devil($devilNo)
	; Dv 3
	If $devilNo == 3 Then _MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_devil_icon.devil_3_x"), _JSONGet($jsonPositionConfig,"button.event_devil_icon.devil_3_y"))
	; Dv 4
	If $devilNo == 4 Then _MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_devil_icon.devil_4_x"), _JSONGet($jsonPositionConfig,"button.event_devil_icon.devil_4_y"))
	; Dv 5
	If $devilNo == 5 Then _MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_devil_icon.devil_5_x"), _JSONGet($jsonPositionConfig,"button.event_devil_icon.devil_5_y"))
EndFunc

Func _MU_handleWhenFinishEvent()
	$jsonAccountActiveDevil = getArrayActiveDevil()
	For $i = 0 To UBound($jsonAccountActiveDevil) -1
		If $jsonAccountActiveDevil[$i] <> '' Then
			writeLog("Handle when finish event account : " & $jsonAccountActiveDevil[$i])
			$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
			$checkRuongK = _JSONGet($jsonAccountActiveDevil[$i], "have_ruong_k")
			$mainNo = getMainNoByChar($charName)
			$checkActiveWin = activeAndMoveWin($mainNo)
			If $checkActiveWin == True Then 
				handelWhenFinshDevilEvent()
				_MU_followLeader(1)
				secondWait(8)
				If $checkRuongK == False Then
					; Thuc hien check ruong K doi voi cac account chua co ruong K
					$check = checkRuongK($jsonAccountActiveDevil[$i])
					If $check == True Then 
						$jsonDevilConfig = getJsonFromFile($jsonPathRoot & "devil_config.json")
						_JSONSet(True, $jsonDevilConfig, $charName & "." & "have_ruong_k")
						setJsonToFileFormat($jsonPathRoot & "devil_config.json", $jsonDevilConfig)
					EndIf
				EndIf
				minisizeMain($mainNo)
			EndIf
		EndIf
	Next
EndFunc
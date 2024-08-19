#include-once
#include <date.au3>
#include <MsgBoxConstants.au3>
#include "../include/_ImageSearch_UDF.au3"
#include <AutoItConstants.au3>
#include "../include/json_utils.au3"
#include <Array.au3>
#include "common_utils.au3"

Func _MU_followLeader($position)
	sendKeyDelay("{Enter}")
	sendKeyDelay("{Enter}")
	writeLog("Begin follow leader !")
	If $position == 1 Then
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_x"), _JSONGet($jsonPositionConfig,"button.follow_leader.position_1_y"))
		secondWait(1)
		sendKeyDelay("{Enter}")
	EndIf
EndFunc

Func getMainNoByChar($charName)
	Return "GamethuVN.net - MU Online Season 15 part 2 (Hà Nội - " & $charName &")"
EndFunc

Func checkLvl400($mainNo)
	$is400Lvl = False
	secondWait(1)
	$color = PixelSearch(130, 762, 210, 802, 0x83CD18, 10)
	$countSearch = 0
	While $color = '' And $countSearch < 5
		$color = PixelSearch(130, 762, 210, 802, 0x83CD18, 10)
		secondWait(1)
		$countSearch = $countSearch + 1
	WEnd

	If $color = '' Then $is400Lvl = True

	writeLog("Main no: " & $mainNo & " $is400Lvl: " & $is400Lvl)

	Return $is400Lvl
EndFunc

Func _MU_Start_AutoZ()
	;~ MouseClick($MOUSE_CLICK_LEFT, 299, 56,1)
	sendKeyDelay("{Home}")
EndFunc

Func checkEmptyMinuteStadium($mainNo)
	writeLog("checkEmptyMinuteStadium($mainNo)")
	$isEmptyMinute = False
	; Click vao icon event
	clickEventIcon()
	$color = 0x262626
	; TODO: Doan nay check chuyen thanh check pixel
	If checkPixelColor(528, 494,$color) = True Then
		writeLog("Het phut vao stadium roi !")
		$isEmptyMinute = True
	EndIf
	Return $isEmptyMinute
EndFunc

Func getjsonPositionConfig()
	Return $jsonPositionConfig
EndFunc

Func getConfigByName($jsonName)
	Return _JSONGet($jsonPositionConfig, $jsonName)
EndFunc

Func handelWhenFinshDevilEvent()
	sendKeyDelay("{Enter}")
	sendKeyDelay("{Enter}")
	; Click neu dang bat shop
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.close_shop.x"), _JSONGet($jsonPositionConfig,"button.close_shop.y"))
	; Click vao tat neu dang bat may quay chao
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.close_chao.x"), _JSONGet($jsonPositionConfig,"button.close_chao.y"))
EndFunc

Func openConsoleThenClear()
	; Send F12
	Send("{F12}")
	secondWait(2)
	; Click into console tab
	_MU_MouseClick_Delay(217, 782)
	; click clean console
	_MU_MouseClick_Delay(56, 815)
	; Click vao cuoi man hinh
	_MU_MouseClick_Delay(1837, 1006)
	secondWait(1)
EndFunc

Func clickEventIcon()
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.x"), _JSONGet($jsonPositionConfig,"button.event_icon.y"))
	secondWait(1)
EndFunc

Func clickEventIconThenGoStadium() 
	clickEventIcon() 
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.map_stadium_x"), _JSONGet($jsonPositionConfig,"button.event_icon.map_stadium_y"))
	secondWait(5)
EndFunc

Func clickEventStadium() 
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.map_stadium_x"), _JSONGet($jsonPositionConfig,"button.event_icon.map_stadium_y"))
	secondWait(1)
EndFunc

Func checkActiveAutoHome()
	$pathImage = $imagePathRoot & "common" & "\not_active_auto_home.bmp"
	$result = True
	$imageSearchResult = _ImageSearch_Area($pathImage, 0, 0, 385, 103, 100, True)
	If $imageSearchResult[0] == 1 Then 
		$result = False
		writeLogFile($logFile, "Auto Z khong hoat dong")
	Else
		writeLogFile($logFile, "Auto Z dang hoat dong")
	EndIf
	Return $result
EndFunc

Func checkAutoOnBuff()
	$pathImage = $imagePathRoot & "common" & "\check_on_buff.bmp"
	$result = False
	$imageSearchResult = _ImageSearch_Area($pathImage, 0, 0, 1056, 789, 100, True)
	If $imageSearchResult[0] == 1 Then $result = True
	Return $result
EndFunc

Func checkAutoOffBuff()
	$pathImage = $imagePathRoot & "common" & "\check_off_buff.bmp"
	$result = False
	$imageSearchResult = _ImageSearch_Area($pathImage, 0, 0, 1056, 789, 100, True)
	If $imageSearchResult[0] == 1 Then $result = True
	Return $result
EndFunc

Func checkRuongK($charInfo)
	$charName = _JSONGet($charInfo, "char_name")
	$title = getMainNoByChar($charName)
	$activeWin = activeAndMoveWin($title)
	secondWait(3)
	$result = False
	If $activeWin == True Then
		; mouse move to top
		MouseMove(0,0)

		; send key K
		sendKeyDelay("k")
		$imageSearch = _ImageSearch_Area($imagePathRoot & "devil" & "\ruong_k.bmp", 0, 0, 1019, 471, 100,False)
		If $imageSearch[0] == 1 Then
			writeLog("Tim thay ruong K")
			$result = True
		EndIf
		; send key K
		sendKeyDelay("k")
		minisizeMain($title)
	EndIf
	Return $result
EndFunc

Func getArrayActiveDevil()
	$jsonDevilConfig = getJsonFromFile($jsonPathRoot & $devilFileName)
	Local $jsonAccountActiveDevil[0]
	For $i = 0 To UBound($jsonDevilConfig) -1
		; active win and check ruong K
		writeLog(_JSONGet($jsonDevilConfig[$i], "char_name"))
		$activeDevil = _JSONGet($jsonDevilConfig[$i], "active")
		$ignorePeakHour = _JSONGet($jsonDevilConfig[$i], "ignore_peak_hour")
		$maxHourGo = _JSONGet($jsonDevilConfig[$i], "max_hour_go")
		; 19/07: add check $maxHourGo >= @HOUR
		If $activeDevil == True And $maxHourGo >= @HOUR Then 
			If $ignorePeakHour == True And @HOUR >= 20 And @HOUR <= 22 Then
				writeLog("Peak hour can't go devil. Wait to 23h")
			Else
				Redim $jsonAccountActiveDevil[UBound($jsonAccountActiveDevil) + 1]
				$jsonAccountActiveDevil[UBound($jsonAccountActiveDevil) - 1] = $jsonDevilConfig[$i]
			EndIf
		EndIf
	Next
	Return $jsonAccountActiveDevil
EndFunc

Func _MU_Join_Event_Devil($checkRuongK)
	If $checkRuongK == True Then
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_devil_icon.x"), _JSONGet($jsonPositionConfig,"button.event_devil_icon.y"))
	Else
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_devil_icon_no_had_k.x"), _JSONGet($jsonPositionConfig,"button.event_devil_icon_no_had_k.y"))
	EndIf
	;~ ; Click button move
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_devil_icon.chap_nhan_x"), _JSONGet($jsonPositionConfig,"button.event_devil_icon.chap_nhan_y"))
	;~ ; Sleep 4s
	secondWait(5)
EndFunc

Func switchOtherChar($currentChar)
	$resultSwitch = False
	$otherCharName = ""
	$otherMainNo = ""
	For $i = 0 To UBound($aCharInAccount) -1
		$resultCheck = StringInStr($aCharInAccount[$i], $currentChar & "|")
		If $resultCheck Then
			; Chuyen sang char con lai
			$otherCharName = StringSplit($aCharInAccount[$i],"|")[2]
			writeLog("Da tim thay other char: " & $otherCharName)
			ExitLoop
		EndIf
	Next
	If $otherCharName <> '' Then 
		$otherMainNo = getMainNoByChar($otherCharName)
		$mainNo = getMainNoByChar($otherCharName)
		If activeAndMoveWin($mainNo) == True Then
			; TODO: Thao tac chuyen char
			; TODO: Click vao icon event
			;~ clickEventIcon()
			; TODO: Click vao vi tri trieu hoi ( theo tung acc)
			; TODO: Click vao nhan vat can trieu hoi
			; TODO: Bam vao nut tat ( truong hop nhan vat da dc trieu hoi roi)
			; => Click vao icon chuyen
			_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.switch_char.icon_x"), _JSONGet($jsonPositionConfig,"button.switch_char.icon_y"))
			; => Click vao chuyen
			_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.switch_char.button_change_x"), _JSONGet($jsonPositionConfig,"button.switch_char.button_change_y"))
			; Lay lai mainNo cua current char
			$mainNo = getMainNoByChar($currentChar)
			; Doi khoang 6s
			$timeCheck = 1;
			$checkActiveMain = activeAndMoveWin($mainNo)
			While $checkActiveMain == False And $timeCheck < 5
				$checkActiveMain = activeAndMoveWin($mainNo)
				$timeCheck += 1
				writeLogFile($logFile,"$timeCheck: " & $timeCheck)
				secondWait(2)
			WEnd

			;~ $checkActiveMain = activeAndMoveWin($mainNo);
			;~ writeLog("$checkActiveMain :" & $checkActiveMain)

			If $checkActiveMain == True Then 
				$resultSwitch = True
			Else
				writeLogFile($logFile,"Khong tim thay main duoc chuyen. Main can check: " &$mainNo)
				; De chuot ra man hinh
				_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_x"), _JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_y"))
				secondWait(2)
				;~ writeLog("Dong toan bo cua so")
				writeLogFile($logFile,"Di chuot ra main hinh va minisize Main hien tai: " &$otherMainNo)
				minisizeMain($otherMainNo)
			EndIf
			; Kiem tra title xem dung la title cua minh khong
		EndIf
	EndIf
	Return $resultSwitch
EndFunc

Func moveOtherMap()
	sendKeyDelay("m")
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.move.other_map_x"), _JSONGet($jsonPositionConfig,"button.move.other_map_y"))
EndFunc
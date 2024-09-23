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
	$position_x  = _JSONGet($jsonPositionConfig,"button.follow_leader.position_"& $position &"_x")
	$position_y  = _JSONGet($jsonPositionConfig,"button.follow_leader.position_"& $position &"_y")
	writeLog("_MU_followLeader with position: " & $position & " x:" & $position_x & " y:" & $position_y)
	_MU_MouseClick_Delay($position_x, $position_y)
	secondWait(1)
	sendKeyDelay("{Enter}")
EndFunc

Func getMainNoByChar($charName)
	Return "GamethuVN.net - MU Online Season 15 part 2 (Hà Nội - " & $charName &")"
EndFunc

Func checkLvl400($mainNo)
	$is400Lvl = False
	secondWait(1)
	$x = _JSONGet($jsonPositionConfig,"button.check_lvl_400.x")
	$y = _JSONGet($jsonPositionConfig,"button.check_lvl_400.y")
	;~ $x1 = _JSONGet($jsonPositionConfig,"button.check_lvl_400.x1")
	;~ $y1 = _JSONGet($jsonPositionConfig,"button.check_lvl_400.y1")
	; Check xem co thay mau xanh khong ? neu co thi chua phai la 400 lvl 
	; Day la mau xanh 0x81C024
	$isNotLvl400 = checkPixelColor($x, $y, 0x81C024)
	;~ $color = PixelSearch($x, $y, $x1, $y1, 0x83CD18, 10)
	$countSearch = 0
	While $isNotLvl400 And $countSearch < 5
		$isNotLvl400 = checkPixelColor($x, $y, 0x81C024)
		secondWait(1)
		$countSearch = $countSearch + 1
	WEnd

	If Not $isNotLvl400 Then $is400Lvl = True

	writeLog("Main no: " & $mainNo & " $is400Lvl: " & $is400Lvl)

	Return $is400Lvl
EndFunc

Func _MU_Start_AutoZ()
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
	; Neu lo dang click vao quay chao thi loai bo
	$closeChaoX = _JSONGet($jsonPositionConfig,"button.close_chao.x")
	$closeChaoY = _JSONGet($jsonPositionConfig,"button.close_chao.y")
	_MU_MouseClick_Delay($closeChaoX, $closeChaoY)
	; Neu dang bat shop thi thuc hien tat shop
	$closeShopX = _JSONGet($jsonPositionConfig,"button.close_shop.x")
	$closeShopY = _JSONGet($jsonPositionConfig,"button.close_shop.y")
	_MU_MouseClick_Delay($closeShopX, $closeShopY)
EndFunc

Func actionWhenCantJoinDevil()
	; Thuc hien send Enter 1 lan de loai bo dialog
	sendKeyDelay("{Enter}")
	; Thuc hien follow leader
	_MU_followLeader(1)
	checkAutoZAfterFollowLead()
	Return True
EndFunc

Func checkAutoZAfterFollowLead()
	secondWait(10)
	$countWaitAutoHome = 0
	While Not checkActiveAutoHome() And $countWaitAutoHome < 2
		secondWait(10)
		$countWaitAutoHome += 1
	WEnd
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
	$pathImage = $imagePathRoot & "common" & "\active_auto_home.bmp"
	$result = False
	$x = _JSONGet($jsonPositionConfig,"button.check_active_auto_home.x")
	$y = _JSONGet($jsonPositionConfig,"button.check_active_auto_home.y")
	$x1 = _JSONGet($jsonPositionConfig,"button.check_active_auto_home.x1")
	$y1 = _JSONGet($jsonPositionConfig,"button.check_active_auto_home.y1")

	$imageSearchResult = _ImageSearch_Area($pathImage, $x, $y, $x1, $y1, 100, True)
	If $imageSearchResult[0] == 1 Then $result = True
	If Not $result Then writeLogFile($logFile, "Auto Z khong hoat dong")
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
	;~ _MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_devil_icon.chap_nhan_x"), _JSONGet($jsonPositionConfig,"button.event_devil_icon.chap_nhan_y"))
	sendKeyDelay("{Enter}")
	;~ ; Sleep 4s
	secondWait(5)
EndFunc

Func switchOtherChar($currentChar)
	$resultSwitch = False	
	$otherCharName = getOtherChar($currentChar)
	If $otherCharName <> '' Then 
		$otherMainNo = getMainNoByChar($otherCharName)
		$currentMainNo = getMainNoByChar($otherCharName)
		If activeAndMoveWin($otherMainNo) Then
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
			secondWait(5)
			$currentMainNo = getMainNoByChar($currentChar)
			; Doi khoang 6s
			$timeCheck = 1;
			$checkActiveMain = activeAndMoveWin($currentMainNo)
			While Not $checkActiveMain And $timeCheck < 5
				$checkActiveMain = activeAndMoveWin($currentMainNo)
				$timeCheck += 1
				writeLogFile($logFile,"$timeCheck: " & $timeCheck)
				secondWait(2)
			WEnd

			If $checkActiveMain Then 
				writeLogFile($logFile,"Da tim thay main duoc chuyen: " & $currentChar)
				$resultSwitch = True
			Else
				writeLogFile($logFile,"Khong tim thay main duoc chuyen. Main can check: " & $currentChar)
				; De chuot ra man hinh
				_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_x"), _JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_y"))
				secondWait(2)
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
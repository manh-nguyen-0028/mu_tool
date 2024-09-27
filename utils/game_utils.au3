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
	secondWait(3)
	$x = _JSONGet($jsonPositionConfig,"button.check_lvl_400.x")
	$y = _JSONGet($jsonPositionConfig,"button.check_lvl_400.y")
	$x1 = _JSONGet($jsonPositionConfig,"button.check_lvl_400.x1")
	$y1 = _JSONGet($jsonPositionConfig,"button.check_lvl_400.y1")
	$color = _JSONGet($jsonPositionConfig,"button.check_lvl_400.color")

	; Check xem co thay mau xanh khong ? neu co thi chua phai la 400 lvl 
	; Day la mau xanh 0x81C024
	Local $pos = PixelSearch($x, $y, $x1, $y1, $color)

	If Not @error Then
		; Nếu tìm thấy màu
		;~ writeLogFile($logFile,"Màu đã được tìm thấy tại tọa độ: " & $pos[0] & ", " & $pos[1])
		$is400Lvl = False
		writeLogFile($logFile,"Chưa đạt 400 lvl")
	Else
		; Nếu không tìm thấy màu
		;~ writeLogFile($logFile,"Màu không tồn tại trên màn hình.")
		$is400Lvl = True
		writeLogFile($logFile,"Đã đạt 400 lvl")
	EndIf

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

Func clickEventStadium() 
	$mapStadiumX = _JSONGet($jsonPositionConfig,"button.event_icon.map_stadium_x")
	$mapStadiumY = _JSONGet($jsonPositionConfig,"button.event_icon.map_stadium_y")
	_MU_MouseClick_Delay($mapStadiumX, $mapStadiumY)
	secondWait(3)
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
	Return searchImageFullScreenMu($pathImage)
EndFunc

Func checkAutoOffBuff()
	$pathImage = $imagePathRoot & "common" & "\check_off_buff.bmp"
	Return searchImageFullScreenMu($pathImage)
EndFunc

Func searchImageFullScreenMu($pathImage) 
	$result = False
	$fullScreenX = _JSONGet($jsonPositionConfig,"common.full_screen.x")
	$fullScreenY = _JSONGet($jsonPositionConfig,"common.full_screen.y")
	$fullScreenX1 = _JSONGet($jsonPositionConfig,"common.full_screen.x1")
	$fullScreenY1 = _JSONGet($jsonPositionConfig,"common.full_screen.y1")
	$imageSearchResult = _ImageSearch_Area($pathImage, $fullScreenX, $fullScreenY, $fullScreenX1, $fullScreenY1, 100, True)
	;~ $imageSearchResult = _ImageSearch_Area($pathImage, 0, 0, 1056, 789, 100, True)
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

Func clickIconDevil($checkRuongK)
	writeLogFile($logFile,"Click event devil. Check ruong K: " & $checkRuongK)
	If $checkRuongK Then
		; Click vao icon event devil
		$devilIconX = _JSONGet($jsonPositionConfig,"button.event_devil_icon.x")
		$devilIconY = _JSONGet($jsonPositionConfig,"button.event_devil_icon.y")
		_MU_MouseClick_Delay($devilIconX, $devilIconY)
	Else
		; Click vao icon event devil khi ruong K khong co
		$devilIconNoHadKX = _JSONGet($jsonPositionConfig,"button.event_devil_icon_no_had_k.x")
		$devilIconNoHadKY = _JSONGet($jsonPositionConfig,"button.event_devil_icon_no_had_k.y")
		_MU_MouseClick_Delay($devilIconNoHadKX, $devilIconNoHadKY)
	EndIf
	; Nhap enter de vao devil
	sendKeyDelay("{Enter}")
	;~ ; Sleep 4s
	secondWait(4)
EndFunc

Func switchOtherChar($currentChar)
	writeLogFile($logFile,"Bat dau tim kiem nhan vat khac cung tai khoan cua: " & $currentChar)

	$resultSwitch = False	

	$otherCharName = getOtherChar($currentChar)
	
	If $otherCharName <> '' Then 
		$otherMainNo = getMainNoByChar($otherCharName)

		If activeAndMoveWin($otherMainNo) Then
			writeLogFile($logFile,"Da tim thay main khac cung tai khoan: " & $otherCharName)
			$swithCharIconX = _JSONGet($jsonPositionConfig,"button.switch_char.icon_x")
			$swithCharIconY = _JSONGet($jsonPositionConfig,"button.switch_char.icon_y")
			$swithCharButtonChangeX = _JSONGet($jsonPositionConfig,"button.switch_char.button_change_x")
			$swithCharButtonChangeY = _JSONGet($jsonPositionConfig,"button.switch_char.button_change_y")

			writeLogFile($logFile,"Bat dau chuyen vao main chinh: " & $currentChar)

			; => Click vao icon chuyen
			_MU_MouseClick_Delay($swithCharIconX, $swithCharIconY)
			; => Click vao chuyen
			_MU_MouseClick_Delay($swithCharButtonChangeX, $swithCharButtonChangeY)
			; Lay lai mainNo cua current char
			secondWait(6)
			$currentMainNo = getMainNoByChar($currentChar)
			; Doi khoang 6s
			$timeCheck = 1;

			While Not activeAndMoveWin($currentMainNo) And $timeCheck < 5
				$timeCheck += 1
			WEnd

			If activeAndMoveWin($currentMainNo) Then 
				$resultSwitch = True
				writeLogFile($logFile,"Da chuyen thanh cong vao main chinh: " & $currentChar)
			Else
				writeLogFile($logFile,"Khong chuyen duoc vao main chinh: " & $currentChar & " sau " & $timeCheck & " lan thu")
				; De chuot ra man hinh
				$mouseMoveCenterX =_JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_x")
				$mouseMoveCenterY =_JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_y")
				_MU_MouseClick_Delay($mouseMoveCenterX, $mouseMoveCenterY)
				secondWait(1)
				; Minisize main
				writeLogFile($logFile,"Minisize main: " & $otherMainNo)
				minisizeMain($otherMainNo)
			EndIf

		EndIf
	EndIf
	Return $resultSwitch
EndFunc

Func moveOtherMap()
	writeLogFile($logFile,"Bat dau chuyen map khac")
	sendKeyDelay("m")
	$moveOtherMapX = _JSONGet($jsonPositionConfig,"button.move.other_map_x")
	$moveOtherMapY = _JSONGet($jsonPositionConfig,"button.move.other_map_y")
	_MU_MouseClick_Delay($moveOtherMapX, $moveOtherMapY)
EndFunc
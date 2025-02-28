#include-once
#include <date.au3>
#include <MsgBoxConstants.au3>
#include "../include/_ImageSearch_UDF.au3"
#include <AutoItConstants.au3>
#include "../include/json_utils.au3"
#include <Array.au3>
#include "common_utils.au3"

Func _MU_followLeader_ControlClick($hWnd, $position)
	ControlSend($hWnd, "", "", "{ENTER}")
	ControlSend($hWnd, "", "", "{ENTER}")
	$position_x  = _JSONGet($jsonPositionConfig,"button.follow_leader.position_"& $position &"_x")
	$position_y  = _JSONGet($jsonPositionConfig,"button.follow_leader.position_"& $position &"_y")
	writeLog("_MU_followLeader with position: " & $position & " x:" & $position_x & " y:" & $position_y)
	_MU_ControlClick_Delay($hWnd, $position_x, $position_y)
	secondWait(1)
	ControlSend($hWnd, "", "", "{ENTER}")
	; Di chuot ra giua man hinh
	mouseMoveCenterChar_Control($hWnd)
EndFunc

Func _MU_followLeader($position)
	sendKeyEnter()
	sendKeyEnter()
	$position_x  = _JSONGet($jsonPositionConfig,"button.follow_leader.position_"& $position &"_x")
	$position_y  = _JSONGet($jsonPositionConfig,"button.follow_leader.position_"& $position &"_y")
	writeLog("_MU_followLeader with position: " & $position & " x:" & $position_x & " y:" & $position_y)
	_MU_MouseClick_Delay($position_x, $position_y)
	secondWait(1)
	sendKeyEnter()
	; Di chuot ra giua man hinh
	mouseMoveCenterChar()
EndFunc

Func mouseMoveCenterChar()
	; Di chuot ra giua man hinh
	writeLogFile($logFile,"Di chuot ra giua man hinh nhan vat")
	$position_char_x  = _JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_char_x")
	$position_char_y  = _JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_char_y")
	MouseMove($position_char_x, $position_char_y)
	secondWait(1)
	Return True
EndFunc

Func mouseMoveCenterChar_Control($hWnd)
	; Di chuot ra giua man hinh
	writeLogFile($logFile,"Di chuot ra giua man hinh nhan vat")
	$position_char_x  = _JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_char_x")
	$position_char_y  = _JSONGet($jsonPositionConfig,"button.screen_mouse_move.center_char_y")
	ControlMouseMove($hWnd, "", $position_char_x, $position_char_y) ; Di chuyển chuột đến tọa độ (100, 50) trong control
	secondWait(1)
	;~ MouseMove($position_char_x, $position_char_y)
	;~ secondWait(1)
	Return True
EndFunc

Func checkLvl400($mainNo)
    writeLogFile($logFile, "Start method: checkLvl400 with mainNo: " & $mainNo)
    
    Local $is400Lvl = False
    Local $x = _JSONGet($jsonPositionConfig, "button.check_lvl_400.x")
    Local $y = _JSONGet($jsonPositionConfig, "button.check_lvl_400.y")
    Local $color = _JSONGet($jsonPositionConfig, "button.check_lvl_400.color_master_3")
    Local $color_2 = _JSONGet($jsonPositionConfig, "button.check_lvl_400.color_master_4")
    
    ; Check initial pixel color
    If checkPixelColor($x, $y, $color) Or checkPixelColor($x, $y, $color_2) Then
        $is400Lvl = True
    Else
        ; Retry checking pixel color up to 5 times
        Local $countCheck = 0
        While Not $is400Lvl And ($countCheck < 5)
            $countCheck += 1
            secondWait(1)
            If checkPixelColor($x, $y, $color) Or checkPixelColor($x, $y, $color_2) Then
                $is400Lvl = True
            EndIf
        WEnd
		writeLogFile($logFile, "Check 400 lvl after " & $countCheck & " times")
    EndIf
    
    ; Log the result
    If $is400Lvl Then
        writeLogFile($logFile, "DA DAT 400 lvl")
    Else
        writeLogFile($logFile, "CHUA DAT 400 lvl")
    EndIf
    
    Return $is400Lvl
EndFunc

Func _MU_Start_AutoZ()
	sendKeyHome()
EndFunc

Func checkEmptyMapStadium($mainNo)
	writeLogFile($logFile, "Start method: checkEmptyMapStadium with mainNo: " & $mainNo)
	
	Local $isEmptyMap = False
	Local $x = _JSONGet($jsonPositionConfig, "button.check_empty_map_stadium.x")
	Local $y = _JSONGet($jsonPositionConfig, "button.check_empty_map_stadium.y")
	Local $color = _JSONGet($jsonPositionConfig, "button.check_empty_map_stadium.color")
	
	; Check initial pixel color
	If checkPixelColor($x, $y, $color) Then
		$isEmptyMap = True
	Else
		; Retry checking pixel color up to 5 times
		Local $countCheck = 0
		While Not $isEmptyMap And ($countCheck < 5)
			$countCheck += 1
			secondWait(1)
			If checkPixelColor($x, $y, $color) Then
				$isEmptyMap = True
			EndIf
		WEnd
		writeLogFile($logFile, "Check empty map after " & $countCheck & " times")
	EndIf
	
	; Log the result
	If $isEmptyMap Then
		writeLogFile($logFile, "Da het luot di map stadium")
	Else
		writeLogFile($logFile, "Van con luot di map stadium")
	EndIf
	
	Return $isEmptyMap
EndFunc

Func checkEmptyMapLvl($mainNo)
	writeLogFile($logFile, "Start method: checkEmptyMapLvl with mainNo: " & $mainNo)
	
	Local $isEmptyMap = False
	Local $x = _JSONGet($jsonPositionConfig, "button.check_empty_map_lvl.x")
	Local $y = _JSONGet($jsonPositionConfig, "button.check_empty_map_lvl.y")
	Local $color = _JSONGet($jsonPositionConfig, "button.check_empty_map_lvl.color")
	
	; Check initial pixel color
	If checkPixelColor($x, $y, $color) Then
		$isEmptyMap = True
	Else
		; Retry checking pixel color up to 5 times
		Local $countCheck = 0
		While Not $isEmptyMap And ($countCheck < 5)
			$countCheck += 1
			secondWait(1)
			If checkPixelColor($x, $y, $color) Then
				$isEmptyMap = True
			EndIf
		WEnd
		writeLogFile($logFile, "Check empty map after " & $countCheck & " times")
	EndIf
	
	; Log the result
	If $isEmptyMap Then
		writeLogFile($logFile, "Da het luot di map lvl")
	Else
		writeLogFile($logFile, "Van con luot di map lvl")
	EndIf
	
	Return $isEmptyMap
EndFunc

Func getjsonPositionConfig()
	Return $jsonPositionConfig
EndFunc

Func getConfigByName($jsonName)
	Return _JSONGet($jsonPositionConfig, $jsonName)
EndFunc

Func handelWhenFinshDevilEvent()
	sendKeyEnter()
	sendKeyEnter()
	; Neu dang bat shop thi thuc hien tat shop
	$closeShopX = _JSONGet($jsonPositionConfig,"button.close_shop.x")
	$closeShopY = _JSONGet($jsonPositionConfig,"button.close_shop.y")
	_MU_MouseClick_Delay($closeShopX, $closeShopY)
	; Neu lo dang click vao quay chao thi loai bo
	$closeChaoX = _JSONGet($jsonPositionConfig,"button.close_chao.x")
	$closeChaoY = _JSONGet($jsonPositionConfig,"button.close_chao.y")
	_MU_MouseClick_Delay($closeChaoX, $closeChaoY)
EndFunc

Func actionWhenCantJoinDevil()
	; Thuc hien send Enter 1 lan de loai bo dialog
	sendKeyEnter()
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
	; can phai doi 5s de check auto home
	secondWait(5)
	; Thuc hien check auto home
	$pathImage = $imagePathRoot & "common" & "\active_auto_home.bmp"
	$result = False
	$x = _JSONGet($jsonPositionConfig,"button.check_active_auto_home.x")
	$y = _JSONGet($jsonPositionConfig,"button.check_active_auto_home.y")
	$x1 = _JSONGet($jsonPositionConfig,"button.check_active_auto_home.x1")
	$y1 = _JSONGet($jsonPositionConfig,"button.check_active_auto_home.y1")
	$imageTolerance = _JSONGet($jsonPositionConfig,"common.image_search.tolerance")
	If $imageTolerance = "" Or Number($imageTolerance) == 0 Then $imageTolerance = 50

	$imageSearchResult = _ImageSearch_Area($pathImage, $x, $y, $x1, $y1, $imageTolerance, True)
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
	If $activeWin Then
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
		If $activeDevil And $maxHourGo >= @HOUR Then 
			If $ignorePeakHour And @HOUR >= 20 And @HOUR <= 22 Then
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
	sendKeyEnter()
	;~ ; Sleep 4s
	secondWait(4)
EndFunc

Func switchOtherChar($currentChar)
	writeLogFile($logFile,"Bat dau tim kiem nhan vat khac cung tai khoan cua: " & $currentChar)

	$resultSwitch = False	

	$otherCharName = getOtherChar($currentChar)
	
	If $otherCharName <> '' Then 
		; chuoi $otherCharName = "char1|char2|char3"
		; Tach chuoi dua tren dau | va kiem tra xem co nhan vat nao duoc active hay khong
		$otherCharNameArray = StringSplit($otherCharName, "|")
		$numberChar = $otherCharNameArray[0]
		$charName = ""

		For $i = 1 To UBound($otherCharNameArray) - 1
			$charName = $otherCharNameArray[$i]
			writeLogFile($logFile,"Check nhan vat: " & $charName)
			If activeAndMoveWinByChar($charName) Then ExitLoop
		Next

		;~ $otherMainNo = getMainNoByChar($otherCharName)

		If activeAndMoveWinByChar($charName) Then
			writeLogFile($logFile,"Tim thay nhan vat: " & $charName & " cung tai khoan")
			writeLogFile($logFile,"Bat dau chuyen sang main chinh: " & $currentChar)
			; Thuc hien click chuyen nhan vat cung tai khoan
			clickOtherChar()

			$timeCheck = 1;

			While Not activeAndMoveWinByChar($currentChar) And $timeCheck < 5
				If $timeCheck >= 2 And Number($numberChar) > 1 Then
					clickOtherChar2()
				Else
					secondWait(1)
				EndIf
				secondWait(1)
				$timeCheck += 1
			WEnd

			If activeAndMoveWinByChar($currentChar) Then 
				$resultSwitch = True
				writeLogFile($logFile,"Switch account SUCCESS: " & $currentChar)
			Else
				writeLogFile($logFile,"Switch account FAIL: " & $currentChar & " affter " & $timeCheck & " time")
				; De chuot ra man hinh
				mouseMoveCenterChar()
				; Minisize main
				minisizeMainByChar($charName)
			EndIf

		EndIf
	EndIf
	Return $resultSwitch
EndFunc

Func clickOtherChar()
	$swithCharIconX = _JSONGet($jsonPositionConfig,"button.switch_char.icon_x")
	$swithCharIconY = _JSONGet($jsonPositionConfig,"button.switch_char.icon_y")
	clickOtherCharWithPosition($swithCharIconX, $swithCharIconY)
	Return True
EndFunc

Func clickOtherChar2()
	$swithCharIconX = _JSONGet($jsonPositionConfig,"button.switch_char.icon_x_2")
	$swithCharIconY = _JSONGet($jsonPositionConfig,"button.switch_char.icon_y_2")
	clickOtherCharWithPosition($swithCharIconX, $swithCharIconY)
EndFunc

Func clickOtherCharWithPosition($swithCharIconX, $swithCharIconY)
	$swithCharButtonChangeX = _JSONGet($jsonPositionConfig,"button.switch_char.button_change_x")
	$swithCharButtonChangeY = _JSONGet($jsonPositionConfig,"button.switch_char.button_change_y")

	writeLogFile($logFile,"Bat dau click voi toa do: " & $swithCharIconX & " - " & $swithCharIconY & " - " & $swithCharButtonChangeX & " - " & $swithCharButtonChangeY)

	; => Click vao icon chuyen
	_MU_MouseClick_Delay($swithCharIconX, $swithCharIconY)
	; => Click vao chuyen
	_MU_MouseClick_Delay($swithCharButtonChangeX, $swithCharButtonChangeY)
	; Lay lai mainNo cua current char
	secondWait(3)
	; De chuot ra man hinh
	;~ mouseMoveCenterChar()
	Return True
EndFunc

Func moveOtherMap($charName)
	; Thuc hien get mainNo cua charName
	$mainNo = getMainNoByChar($charName)
	; Thuc hien active va move win
	$activeWin = activeAndMoveWin($mainNo)
	; Neu khong duoc active thi thuc hien switch sang main khac
	If Not $activeWin Then
		$activeWin = switchOtherChar($charName)
	EndIf
	; Chi nhung truong hop duoc active moi thuc hien move map
	If $activeWin Then
		secondWait(1)
		writeLogFile($logFile,"Bat dau chuyen map khac")
		sendKeyDelay("m")
		$moveOtherMapX = _JSONGet($jsonPositionConfig,"button.move.other_map_x")
		$moveOtherMapY = _JSONGet($jsonPositionConfig,"button.move.other_map_y")
		_MU_MouseClick_Delay($moveOtherMapX, $moveOtherMapY)
		writeLogFile($logFile,"Da chuyen map khac voi toa do: " & $moveOtherMapX & " - " & $moveOtherMapY)
	Else
		writeLogFile($logFile,"Khong the chuyen map khac")
	EndIf
EndFunc

Func checkEnterChat()
	$x = _JSONGet($jsonPositionConfig,"button.check_enter_chat.x")
	$y = _JSONGet($jsonPositionConfig,"button.check_enter_chat.y")
	$color = _JSONGet($jsonPositionConfig,"button.check_enter_chat.color")
	; Truong hop ton tai cua so chat, thuc hien enter 1 lan nua
	If checkPixelColor($x, $y, $color) Then
		writeLogFile($logFile,"Ton tai cua so chat, thuc hien enter 1 lan nua")
		sendKeyEnter()
	EndIf
	Return True
EndFunc

Func switchToMainChar($jsonAccountActiveDevil)
	; Thuc hien check trong $jsonAccountActiveDevil xem acc nao can chuyen sang main chinh hay khong ?
	For $i = 0 To UBound($jsonAccountActiveDevil) - 1
		$switch_other_main = _JSONGet($jsonAccountActiveDevil[$i], "switch_other_main")
		$main_char_name = _JSONGet($jsonAccountActiveDevil[$i], "main_char_name")
		If $switch_other_main Then
			$charName = _JSONGet($jsonAccountActiveDevil[$i], "char_name")
			$active = _JSONGet($jsonAccountActiveDevil[$i], "active")
			$mainNo = getMainNoByChar($charName)
			If $active And activeAndMoveWin($mainNo) Then
				; Thuc hien swith
				$resultSwitch = switchOtherChar($main_char_name)
				; Neu thanh cong thi an main da duoc swith di, neu khong thi an main hien tai
				If $resultSwitch Then
					minisizeMain(getMainNoByChar($main_char_name))
				Else
					minisizeMain($mainNo)
				EndIf
			EndIf
		EndIf
	Next
EndFunc
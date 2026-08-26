#include-once
#include <date.au3>
#include <MsgBoxConstants.au3>
#include "../include/_ImageSearch_UDF.au3"
#include <AutoItConstants.au3>
#include "../include/json_utils.au3"
#include <Array.au3>
#include "common_utils.au3"
#include <GUIConstantsEx.au3> ;< - -Bổ sung dòng này để có $GUI_RUNDEFMSG
#include <WinAPI.au3>
;~ #include <WindowsConstants.au3>

; === Cấu hình giới hạn ===
Global $MIN_W = 800
Global $MIN_H = 600
Global $MAX_W = 1280
Global $MAX_H = 1024
Global $hWnd

Func _MU_followLeader_ControlClick($hWnd, $position)
	ControlSend($hWnd, "", "", "{ENTER}")
	ControlSend($hWnd, "", "", "{ENTER}")
	$position_x = _JSONGet($jsonPositionConfig, "button.follow_leader.position_" & $position & "_x")
	$position_y = _JSONGet($jsonPositionConfig, "button.follow_leader.position_" & $position & "_y")
	writeLog("_MU_followLeader with position: " & $position & " x:" & $position_x & " y:" & $position_y)
	_MU_ControlClick_Delay($hWnd, $position_x, $position_y)
	secondWait(1)
	ControlSend($hWnd, "", "", "{ENTER}")
EndFunc   ;==>_MU_followLeader_ControlClick

Func _MU_followLeader($position)
	; khi can follow lead thi bam 2 lan cho chac an
	;~ For $i = 0 To 1 Step +1
		$position_x = _JSONGet($jsonPositionConfig, "button.follow_leader.position_" & $position & "_x")
		$position_y = _JSONGet($jsonPositionConfig, "button.follow_leader.position_" & $position & "_y")
		writeLog("_MU_followLeader with position: " & $position & " x:" & $position_x & " y:" & $position_y)
		mouseClickDelayShift($position_x, $position_y)
	;~ Next

	secondWait(1)
EndFunc   ;==>_MU_followLeader

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
EndFunc   ;==>checkLvl400

Func _MU_Start_AutoZ()
	sendKeyHome()
EndFunc   ;==>_MU_Start_AutoZ

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
EndFunc   ;==>checkEmptyMapStadium

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
EndFunc   ;==>checkEmptyMapLvl

Func getjsonPositionConfig()
	Return $jsonPositionConfig
EndFunc   ;==>getjsonPositionConfig

Func getConfigByName($jsonName)
	Return _JSONGet($jsonPositionConfig, $jsonName)
EndFunc   ;==>getConfigByName

Func handelWhenFinshDevilEvent()
	For $i = 0 To 3 Step +1
		sendKeyEnter()
	Next
	; Neu dang bat shop thi thuc hien tat shop
	;~ $closeShopX = _JSONGet($jsonPositionConfig, "button.close_shop_chao.x")
	;~ $closeShopY = _JSONGet($jsonPositionConfig, "button.close_shop_chao.y")
	;~ For $i = 0 To 1 Step +1
	;~ 	_MU_MouseClick_Delay($closeShopX, $closeShopY)
	;~ Next
	; Click ra ngaoi 1 lan nua cho chac
	;~ _MU_MouseClick_Delay(150, 228)
	clickCenterChar()
EndFunc   ;==>handelWhenFinshDevilEvent

Func handleBeforeReset()
	sendEnterThenClickCenter()
EndFunc

Func sendEnterThenClickCenter()
	;~ sendKeyEnter()
	sendKeyEnter()
	clickCenterChar()
	Return True
EndFunc

Func actionWhenCantJoinDevil($charInfo)
	$isNeedFollowLeader = _JSONGet($charInfo, "is_need_follow_leader")
	; Thuc hien send Enter 1 lan de loai bo dialog
	sendEnterThenClickCenter()
	; Close popup event devil 239, 126
	$closePopupX = _JSONGet($jsonPositionConfig, "button.event_devil.close_popup_event_devil_x")
	$closePopupY = _JSONGet($jsonPositionConfig, "button.event_devil.close_popup_event_devil_y")
	
	_MU_MouseClick_Delay($closePopupX, $closePopupY)

	; Thuc hien follow leader
	If $isNeedFollowLeader Then
		_MU_followLeader(1)
		checkAutoZAfterFollowLead($charInfo, True)
	EndIf
	Return True
EndFunc   ;==>actionWhenCantJoinDevil

Func checkAutoZAfterFollowLead($charInfo, $needCheck = False)
	Local $timeWaitAfterFollow = getTimeWaitAfterFollowLead($charInfo)

	If $needCheck Then
		secondWait($timeWaitAfterFollow)
		$countWaitAutoHome = 0
		While Not checkActiveAutoHome() And $countWaitAutoHome < 2
			secondWait($timeWaitAfterFollow)
			$countWaitAutoHome += 1
		WEnd
	EndIf
EndFunc   ;==>checkAutoZAfterFollowLead

Func getTimeWaitAfterFollowLead($charInfo)
	Local $timeWaitAfterFollow = 10
	Local $configWait = Number(_JSONGet($charInfo, "time_wait_after_follow"))
	If $configWait > 0 Then $timeWaitAfterFollow = $configWait
	Return $timeWaitAfterFollow
EndFunc   ;==>getTimeWaitAfterFollowByDevilConfig

Func clickEventIcon()
	secondWait(3)
	sendKeyS()
	secondWait(1)
EndFunc   ;==>clickEventIcon

Func clickEventStadium()
	$mapStadiumX = _JSONGet($jsonPositionConfig, "button.event_icon.map_stadium_x")
	$mapStadiumY = _JSONGet($jsonPositionConfig, "button.event_icon.map_stadium_y")
	_MU_MouseClick_Delay($mapStadiumX, $mapStadiumY)
	secondWait(3)
EndFunc   ;==>clickEventStadium

Func clickEventLvl()
	$mapLvlX = _JSONGet($jsonPositionConfig, "button.event_icon.map_lvl_x")
	$mapLvlY = _JSONGet($jsonPositionConfig, "button.event_icon.map_lvl_y")
	_MU_MouseClick_Delay($mapLvlX, $mapLvlY)
	secondWait(3)
EndFunc   ;==>clickEventLvl

Func goCenterMapLvl()
	$mapLvlCenterX = _JSONGet($jsonPositionConfig, "button.event_icon.map_lvl_center_x")
	$mapLvlCenterY = _JSONGet($jsonPositionConfig, "button.event_icon.map_lvl_center_y")
	_MU_MouseClick_Delay($mapLvlCenterX, $mapLvlCenterY)
	secondWait(2)
EndFunc   ;==>goCenterMapLvl

Func checkActiveAutoHome()
	$pathImage = $imagePathRoot & "common" & "\active_auto_home.bmp"
	$imageTolerance = _JSONGet($jsonPositionConfig, "common.image_search.tolerance")
	$x = _JSONGet($jsonPositionConfig, "button.check_active_auto_home.x")
	$y = _JSONGet($jsonPositionConfig, "button.check_active_auto_home.y")
	$x1 = _JSONGet($jsonPositionConfig, "button.check_active_auto_home.x1")
	$y1 = _JSONGet($jsonPositionConfig, "button.check_active_auto_home.y1")
	Return checkActiveAutoHomeCommon($pathImage,$imageTolerance, $x, $y, $x1, $y1)
EndFunc

Func checkActiveAutoHomePlus()
	$pathImage = $imagePathRoot & "common" & "\active_auto_home_plus.bmp"
	$imageTolerance = _JSONGet($jsonPositionConfig, "common.image_search.tolerance_auto_home_plus")
	$x = _JSONGet($jsonPositionConfig, "button.check_active_auto_home.plus_x")
	$y = _JSONGet($jsonPositionConfig, "button.check_active_auto_home.plus_y")
	$x1 = _JSONGet($jsonPositionConfig, "button.check_active_auto_home.plus_x1")
	$y1 = _JSONGet($jsonPositionConfig, "button.check_active_auto_home.plus_y1")
	writeLogFile($logFile, "Check active auto home plus with param: x:" & $x & " y:" & $y & " x1:" & $x1 & " y1:" & $y1 & " and path image: " & $pathImage)
	Return checkActiveAutoHomeCommon($pathImage,$imageTolerance, $x, $y, $x1, $y1)
EndFunc

Func checkActiveAutoHomeCommon($pathImage,$imageTolerance, $x, $y, $x1, $y1)
	secondWait(5)
	$result = False
	If $imageTolerance = "" Or Number($imageTolerance) == 0 Then $imageTolerance = 50

	$imageSearchResult = _ImageSearch_Area($pathImage, $x, $y, $x1, $y1, $imageTolerance, True)
	If $imageSearchResult[0] == 1 Then
		$result = True
	EndIf
	If Not $result Then writeLogFile($logFile, "Auto Z khong hoat dong")
	Return $result
EndFunc

Func checkOpenPopupDevil()
	Return checkColorPopUpDevil()
EndFunc   ;==>checkOpenPopupDevil

Func searchNvpNotActiveAutoZ()
	; can phai doi 5s de check auto home
	secondWait(5)
	; Thuc hien check auto home
	$pathImage = $imagePathRoot & "common" & "\nvp_not_active_auto_z.bmp"
	$x = _JSONGet($jsonPositionConfig, "common.screen_800_600.x")
	$y = _JSONGet($jsonPositionConfig, "common.screen_800_600.y")
	$x1 = _JSONGet($jsonPositionConfig, "common.screen_800_600.x1")
	$y1 = _JSONGet($jsonPositionConfig, "common.screen_800_600.y1")
	$imageTolerance = _JSONGet($jsonPositionConfig, "common.image_search.tolerance")
	If $imageTolerance = "" Or Number($imageTolerance) == 0 Then $imageTolerance = 50

	$imageSearchResult = _ImageSearch_Area($pathImage, $x, $y, $x1, $y1, $imageTolerance, True)
	If $imageSearchResult[0] == 1 Then
;~ $result = True
		Return True
;~ MouseMove(607,541)
	Else
		writeLogFile($logFile, "Khong tim thay button nvp_not_active_auto_z")
		Return False
	EndIf
EndFunc   ;==>searchNvpNotActiveAutoZ

Func checkAutoOnBuff()
	$pathImage = $imagePathRoot & "common" & "\check_on_buff.bmp"
	Return searchImageFullScreenMu($pathImage)
EndFunc   ;==>checkAutoOnBuff

Func checkAutoOffBuff()
	$pathImage = $imagePathRoot & "common" & "\check_off_buff.bmp"
	Return searchImageFullScreenMu($pathImage)
EndFunc   ;==>checkAutoOffBuff

Func check400LvlImage()
	secondWait(1)
	$pathImage = $imagePathRoot & "common" & "\400lv.bmp"
	Return searchImageFullScreenMu($pathImage)
EndFunc   ;==>check400LvlImage

Func searchImageFullScreenMu($pathImage)
	$result = False
	$fullScreenX = _JSONGet($jsonPositionConfig, "common.screen_800_600.x")
	$fullScreenY = _JSONGet($jsonPositionConfig, "common.screen_800_600.y")
	$fullScreenX1 = _JSONGet($jsonPositionConfig, "common.screen_800_600.x1")
	$fullScreenY1 = _JSONGet($jsonPositionConfig, "common.screen_800_600.y1")
	writeLogFile($logFile, "Search image full screen with param: x:" & $fullScreenX & " y:" & $fullScreenY & " x1:" & $fullScreenX1 & " y1:" & $fullScreenY1 & " and path image: " & $pathImage)
	$imageSearchResult = _ImageSearch_Area($pathImage, $fullScreenX, $fullScreenY, $fullScreenX1, $fullScreenY1, 100, True)
	If $imageSearchResult[0] == 1 Then $result = True
	Return $result
EndFunc   ;==>searchImageFullScreenMu

Func checkRuongK($charInfo)
	$charName = _JSONGet($charInfo, "char_name")
	$title = getMainNoByChar($charName)
	$activeWin = activeAndMoveWin($title)
	secondWait(3)
	$result = False
	If $activeWin Then
		; mouse move to top
		MouseMove(0, 0)

		; send key K
		sendKeyDelay("k")
		$imageSearch = _ImageSearch_Area($imagePathRoot & "devil" & "\ruong_k.bmp", 0, 0, 1019, 471, 100, False)
		If $imageSearch[0] == 1 Then
			writeLog("Tim thay ruong K")
			$result = True
		EndIf
		; send key K
		sendKeyDelay("k")
		minisizeMain($title)
	EndIf
	Return $result
EndFunc   ;==>checkRuongK

Func clickIconDevil($charInfo)
	$charName = _JSONGet($charInfo, "char_name")
	$checkRuongK = _JSONGet($charInfo, "have_ruong_k")
	$isHaveQuest = _JSONGet($charInfo, "have_quest")
	$mainNo = getMainNoByChar($charName)
	$fixedCoordFirst = _JSONGet($charInfo, "fixed_coord_first")
	$iconDevilPriorityX = _JSONGet($charInfo, "icon_devil_x")
	$iconDevilPriorityY = _JSONGet($charInfo, "icon_devil_y")
	$isFastJoin = _JSONGet($charInfo, "is_fast_join")

	activeAndMoveWinByChar($charName)
	writeLogFile($logFile, "Click event devil. Check ruong K: " & $checkRuongK)
	$haveIp = True
	$haveAddPoint = True
	$typeCheck = 1
	; 1. co ip, co ruong k, co + diem
	; 2. co ip, co ruong k, chua + diem
	; 3. ko co ip, co ruong k, co + diem
	; 4. ko co ip, co ruong k, chua + diem
	If $haveIp And $haveAddPoint Then
		$typeCheck = 1
	ElseIf $haveIp And Not $haveAddPoint Then
		$typeCheck = 2
	ElseIf Not $haveIp And Not $haveAddPoint Then
		$typeCheck = 3
	EndIf
	$devilIconX = 0 
	$devilIconY = 0
	clickIconDevilByCondition($typeCheck, $isHaveQuest, $devilIconX, $devilIconY)

	; Thay doi cach lay toa do icon devil, neu co toa do uu tien "fixed_coord_first": true thi de lay toa do fixed ("icon_devil_x" va "icon_devil_y")
	If $fixedCoordFirst Then
			$devilIconX = $iconDevilPriorityX
			$devilIconY = $iconDevilPriorityY
	EndIf

	; Trong truong hop fast join thi can thuc hien Enter them 1 lan de loai bo popup event devil
	If $isFastJoin Then
		sendEnterThenClickCenter()
	EndIf

	; Click vao icon event
	_MU_MouseClick_Delay($devilIconX, $devilIconY)

	; Nhap enter de vao devil
	sendKeyEnter()
	secondWait(1)
EndFunc   ;==>clickIconDevil

Func clickIconDevilByCondition($type, $isHaveQuest, ByRef $devilIconX, ByRef $devilIconY)
	; 1. co ip, co ruong k, co + diem
	; 2. co ip, co ruong k, chua + diem
	; 3. co ip, co ruong k, co + diem
	; 4. ko co ip, co ruong k, chua + diem
	If $type == 1 Then
		; Click vao icon event devil
		$devilIconX = _JSONGet($jsonPositionConfig, "button.event_devil_icon.x")
		$devilIconY = _JSONGet($jsonPositionConfig, "button.event_devil_icon.y")
		If $isHaveQuest Then
			$devilIconX = _JSONGet($jsonPositionConfig, "button.event_devil_icon.x_quest")
			$devilIconY = _JSONGet($jsonPositionConfig, "button.event_devil_icon.y_quest")
		EndIf
	ElseIf $type == 2 Then
		; Click vao icon event devil
		$devilIconX = _JSONGet($jsonPositionConfig, "button.event_devil_icon.x_2")
		$devilIconY = _JSONGet($jsonPositionConfig, "button.event_devil_icon.y_2")
	ElseIf $type == 3 Then
		; Click vao icon event devil
		$devilIconX = _JSONGet($jsonPositionConfig, "button.event_devil_icon.x_3")
		$devilIconY = _JSONGet($jsonPositionConfig, "button.event_devil_icon.y_3")
	Else
		; Click vao icon event devil
		$devilIconX = _JSONGet($jsonPositionConfig, "button.event_devil_icon.x_3")
		$devilIconY = _JSONGet($jsonPositionConfig, "button.event_devil_icon.y_3")
	EndIf
	Return True
EndFunc   ;==>clickIconDevilByCondition

; get array other char name in json config by current char name
Func checkActiveOtherChar($currentChar)
	$charName = ""
	$numberChar = 0
	$otherCharName = getOtherChar($currentChar)

	If $otherCharName <> '' Then 
		; chuoi $otherCharName = "char1|char2|char3"
		; Tach chuoi dua tren dau | va tra ve array
		$result = StringSplit($otherCharName, "|")
		$numberChar = $result[0]
		For $i = 1 To UBound($result) - 1
			; Neu trung voi currentChar thi bo qua
			If $result[$i] == $currentChar Then ContinueLoop

			$charName = $result[$i]
			writeLogFile($logFile, "Check nhan vat: " & $charName)
			If checkActiveWinByChar($charName) Then
				writeLogFile($logFile, "Tim thay nhan vat: " & $charName & " cung tai khoan va duoc active")
				ExitLoop
			Else
				$charName = ""
			EndIf
		Next
	EndIf
	writeLogFile($logFile, "checkActiveOtherChar tra ve: charName: " & $charName & " - numberChar: " & $numberChar)
	Return $charName & "|" & $numberChar 
EndFunc   ;==>checkActiveOtherChar

Func switchOtherChar($currentChar)
	writeLogFile($logFile, "switchOtherChar -> Bat dau tim kiem nhan vat khac cung tai khoan cua: " & $currentChar)

	$resultSwitch = False

	$charNameOtherChar = checkActiveOtherChar($currentChar)
	; $charNameOtherChar: JoyBoy|2 - > charFound: JoyBoy - numberChar: 2
	$charFound = StringSplit($charNameOtherChar, "|")[1]
	$numberChar = StringSplit($charNameOtherChar, "|")[2]

	writeLogFile($logFile, "switchOtherChar -> checkActiveOtherChar tra ve: charFound: " & $charFound & " - numberChar: " & $numberChar & " - $charNameOtherChar: " & $charNameOtherChar)

	If $charFound <> "" Then
			writeLogFile($logFile, "Bat dau chuyen sang main cần thiết: " & $currentChar)
			; active + move main tim thay
			activeAndMoveWinByChar($charFound)
			;~ secondWait(2)
			sendEnterThenClickCenter()
			; Thuc hien click chuyen nhan vat cung tai khoan
			clickOtherChar($currentChar)

			$timeCheck = 1 ;

			While Not activeAndMoveWinByChar($currentChar) And $timeCheck < 5
				If $timeCheck >= 2 And Number($numberChar) > 1 Then
					clickOtherChar2($currentChar)
				;~ Else
				;~ 	secondWait(1)
				EndIf
				secondWait(1)
				$timeCheck += 1
			WEnd

			If activeAndMoveWinByChar($currentChar) Then
				$resultSwitch = True
				writeLogFile($logFile, "Switch account SUCCESS: " & $currentChar)
			Else
				writeLogFile($logFile, "Switch account FAIL: " & $currentChar & " affter " & $timeCheck & " time")
				; Minisize main
				minisizeMainByChar($charFound)
			EndIf

		EndIf
	Return $resultSwitch
EndFunc   ;==>switchOtherChar

Func clickOtherChar($charName)
	$swithCharIconX = _JSONGet($jsonPositionConfig, "button.switch_char.icon_x")
	$swithCharIconY = _JSONGet($jsonPositionConfig, "button.switch_char.icon_y")
	clickOtherCharCommon($swithCharIconX, $swithCharIconY, $charName)
EndFunc   ;==>clickOtherChar

Func clickOtherCharCommon($swithCharIconX, $swithCharIconY, $charName)
	$swithCharButtonChangeX_activeAutoZ = _JSONGet($jsonPositionConfig, "button.switch_char.button_change_x_active_autoz")
	$swithCharButtonChangeY_activeAutoZ = _JSONGet($jsonPositionConfig, "button.switch_char.button_change_y_active_autoz")

	$swithCharButtonChangeX_not_activeAutoZ = _JSONGet($jsonPositionConfig, "button.switch_char.button_change_x_not_active_autoz")
	$swithCharButtonChangeY_not_activeAutoZ = _JSONGet($jsonPositionConfig, "button.switch_char.button_change_y_not_active_autoz")

	$closePopupX = _JSONGet($jsonPositionConfig, "button.switch_char.close_popup_x")
	$closePopupY = _JSONGet($jsonPositionConfig, "button.switch_char.close_popup_y")

	; => Click vao icon chuyen
	_MU_MouseClick_Delay($swithCharIconX, $swithCharIconY)

	;~ secondWait(2)

	; => Kiem tra tinh trang active AutoZ cua nhan vat phu
	$result = searchNvpNotActiveAutoZ()
	; Truong hop nvp khong duoc active autoZ ( result = true ) thi click vao vi tri 1
	If $result Then
		_MU_MouseClick_Delay($swithCharButtonChangeX_not_activeAutoZ, $swithCharButtonChangeY_not_activeAutoZ, True)
	Else
		_MU_MouseClick_Delay($swithCharButtonChangeX_activeAutoZ, $swithCharButtonChangeY_activeAutoZ, True)
	EndIf
	secondWait(2)

	; Truong hop van khong duoc active thi thuc hien chon nhan vat dau tien trong bang chuyen nhan vat cung tai khoan
	If activeAndMoveWinByChar($charName) Then
		writeLogFile($logFile, "Switch account SUCCESS after click change button: " & $charName)
	Else
		writeLogFile($logFile, "Switch account FAIL after click change button: " & $charName & " - Need click close popup")
		; thuc hien click vao nhan vat dau tien trong bang chuyen nhan vat cung tai khoan
		$button_first_char_x = _JSONGet($jsonPositionConfig, "button.switch_char.button_first_char_x")
		$button_first_char_y = _JSONGet($jsonPositionConfig, "button.switch_char.button_first_char_y")
		_MU_MouseClick_Delay($button_first_char_x, $button_first_char_y)
		; Doi 2s sau do check lai 1 lan nua, neu van khong active duoc thi thuc hien click vao vi tri close popup de tat popup chuyen nhan vat cung tai khoan
		secondWait(2)
		If Not activeAndMoveWinByChar($charName) Then _MU_MouseClick_Delay($closePopupX, $closePopupY)
		Return False
	EndIf

	Return True
EndFunc   ;==>clickOtherCharCommon

Func clickOtherChar2($charName)
	$swithCharIconX = _JSONGet($jsonPositionConfig, "button.switch_char.icon_x_2")
	$swithCharIconY = _JSONGet($jsonPositionConfig, "button.switch_char.icon_y_2")
	; TODO:
	clickOtherCharCommon($swithCharIconX, $swithCharIconY, $charName)
EndFunc   ;==>clickOtherChar2

Func moveOtherMap($charName, $startAutoPlus = False)
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
		writeLogFile($logFile, "Bat dau chuyen map khac")
		sendEnterThenClickCenter()
		sendKeyM()
		secondWait(1)
		$moveOtherMapX = _JSONGet($jsonPositionConfig, "button.move.other_map_x")
		$moveOtherMapY = _JSONGet($jsonPositionConfig, "button.move.other_map_y")
		; Click lien tuc 3 lan
		For $i = 0 To 1 Step +1
			_MU_MouseClick_Delay($moveOtherMapX, $moveOtherMapY)
		Next

		writeLogFile($logFile, "Da chuyen map khac voi toa do: " & $moveOtherMapX & " - " & $moveOtherMapY)
		secondWait(5)

		; Truong hop $startAutoPlus = True thi thuc hien startAutoPlus()
		If $startAutoPlus Then startAutoPlus()
	Else
		writeLogFile($logFile, "Khong the chuyen map khac")
	EndIf
EndFunc   ;==>moveOtherMap

Func switchToMainChar($jsonAccountActiveDevil)
    ; Thuc hien check trong $jsonAccountActiveDevil xem acc nao can chuyen sang main chinh hay khong ?
    For $i = 0 To UBound($jsonAccountActiveDevil) - 1
		Local $charInfo = $jsonAccountActiveDevil[$i]
		Local $charName = _JSONGet($charInfo, "char_name")
		Local $swithOtherMain = _JSONGet($charInfo, "switch_other_main")
		Local $mainCharName = _JSONGet($charInfo, "main_char_name")
		; Chi thuc hien khi $swithOtherMain = true va mainCharName khac rong
		If $swithOtherMain And $mainCharName <> "" Then switchToMainCharItem($charName, $mainCharName)
    Next
EndFunc   ;==>switchToMainChar

; Method: switchToMainCharItem
; Description: Xu ly chuyen sang main chinh cho 1 nhan vat trong truong hop main chinh chua duoc active
; - Neu main chinh da duoc active thi khong can switch nua, chi can minisize main con lai
; - Neu main chinh chua duoc active thi thuc hien switch sang main chinh, neu switch thanh cong thi minisize main con lai, neu switch khong thanh cong thi minisize main hien tai
Func switchToMainCharItem($charName, $mainCharName)
    Local $mainNo = getMainNoByChar($charName)

    ; Truong hop main cha da duoc active thi khong can switch nua
    If activeAndMoveWinByChar($mainCharName) Then
        writeLogFile($logFile, "Main cha da duoc active roi. Khong can swith nua: " & $mainCharName)
        minisizeMain(getMainNoByChar($mainCharName))
        Return
    EndIf

    writeLogFile($logFile, "Main cha chua duoc active. Thuc hien swith sang main cha: " & $mainCharName)

    ; Thuc hien check active main con. Neu duoc active thi thuc hien switch sang main cha
    If Not activeAndMoveWin($mainNo) Then Return

    Local $resultSwitch = switchOtherChar($mainCharName)
    ; Neu thanh cong thi an main da duoc swith di, neu khong thi an main hien tai
    If $resultSwitch Then
        minisizeMain(getMainNoByChar($mainCharName))
    Else
        minisizeMain($mainNo)
    EndIf
EndFunc   ;==>switchToMainCharItem

Func changeServer($mainNo)
	writeLogFile($logFile, "Begin change server !")
	sendKeyEsc()
	secondWait(1)
	; Bam chon nhat vat server
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig, "button.change_server.button_x"), _JSONGet($jsonPositionConfig, "button.change_server.button_y"))
	secondWait(3)
	; Check title
	For $i = 0 To 3 Step +1
		$checkActive = activeAndMoveWin($mainNo)
		If $checkActive Then
			sendKeyEsc()
			; Bam chon nhat vat khac
			_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig, "button.change_server.button_x"), _JSONGet($jsonPositionConfig, "button.change_server.button_y"))
			secondWait(3)
		Else
			; Click button chon server
			secondWait(3)
			_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig, "button.change_server.choise_sv_x"), _JSONGet($jsonPositionConfig, "button.change_server.choise_sv_y"))
			ExitLoop
		EndIf
	Next

EndFunc   ;==>changeServer

Func choise_sv()
	; thuc hien active title game main
	$checkActive = activeAndMoveWin($titleGameMain)
	If $checkActive Then
		writeLogFile($logFile, "Bat dau chon server vao lai game ! ")
		; Click vi tri 0 - 0
		secondWait(2)
;~ _MU_MouseClick_Delay(0,0)
;~ secondWait(1)
		; Click button chon server
		_MU_MouseClick_Delay(getProperty("button.change_server.choise_sv_x"), getProperty("button.change_server.choise_sv_y"))
		secondWait(2)
		; Click vao chon sv 1
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig, "button.change_server.choise_sv_1_x"), _JSONGet($jsonPositionConfig, "button.change_server.choise_sv_1_y"))
		secondWait(3)
		sendKeyEnter()
	Else
		writeLogFile($logFile, "Khong the active title game main de vao server !")
	EndIf
EndFunc   ;==>choise_sv

Func goSportStadium($sportNo = 1)
	writeLogFile($logFile, "Bat dau vao sport arena: " & $sportNo)
	sendKeyTab()
;~ secondWait(2)
	; sport chia lam tung cap do tu de toi kho, tuy muc dich su dung
	$sportArenaX = 269
	$sportArenaY = 329
	If ($sportNo == 1) Then
		$sportArenaX = _JSONGet($jsonPositionConfig, "button.sport_arena_1.x")
		$sportArenaY = _JSONGet($jsonPositionConfig, "button.sport_arena_1.y")
	ElseIf ($sportNo == 2) Then
		$sportArenaX = _JSONGet($jsonPositionConfig, "button.sport_arena_2.x")
		$sportArenaY = _JSONGet($jsonPositionConfig, "button.sport_arena_2.y")
	ElseIf ($sportNo == 3) Then
		$sportArenaX = _JSONGet($jsonPositionConfig, "button.sport_arena_3.x")
		$sportArenaY = _JSONGet($jsonPositionConfig, "button.sport_arena_3.y")
	EndIf
	_MU_MouseClick_Delay($sportArenaX, $sportArenaY)
	secondWait(2)
	sendKeyTab()
EndFunc   ;==>goSportStadium

; Method: getNpcSearchArea
; Description: Lấy tọa độ vùng tìm kiếm NPC từ config
Func getNpcSearchArea(ByRef $npcSearchX, ByRef $npcSearchY, ByRef $npcSearchX1, ByRef $npcSearchY1)
	$npcSearchX = _JSONGet($jsonPositionConfig, "button.npc_search.npc_search_x")
	$npcSearchY = _JSONGet($jsonPositionConfig, "button.npc_search.npc_search_y")
	$npcSearchX1 = _JSONGet($jsonPositionConfig, "button.npc_search.npc_search_x_1")
	$npcSearchY1 = _JSONGet($jsonPositionConfig, "button.npc_search.npc_search_y_1")
EndFunc   ;==>getNpcSearchArea

; Method: moveAndSearchNpcPixel
; Description: Di chuyển nhân vật và tìm kiếm NPC bằng pixel search, thử tối đa $maxRetry lần
Func moveAndSearchNpcPixel($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor, $maxRetry = 2)
	Local $npcSearch = 0
	Local $countSearchPixel = 0

	While $npcSearch = 0 And $countSearchPixel < $maxRetry
		$moveCheckNpcX = _JSONGet($jsonPositionConfig, "button.event_devil.move_check_npc_x")
		$moveCheckNpcY = _JSONGet($jsonPositionConfig, "button.event_devil.move_check_npc_y")
		_MU_MouseClick_Delay($moveCheckNpcX, $moveCheckNpcY)
		secondWait(2)
		$npcSearch = PixelSearch($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor, 4)
		$countSearchPixel = $countSearchPixel + 1
	WEnd

	Return $npcSearch
EndFunc   ;==>moveAndSearchNpcPixel

Func checkColorPopUpDevil()
	;~ 0x9A3C00
	;~ 250, 460
	$npcSearch = PixelSearch(0, 0, 250, 460, 0x9A3C00, 4)
	If $npcSearch = 0 Then
		;~ clickIconDevil($charName, $checkRuongK, $isHaveQuest)
		Return False
	Else
		; Truong hop thay roi thi thoat khoi vong lap
		writeLogFile($logFile, "checkColorPopUpDevil tai vi tri : " & $npcSearch[0] & "-" & $npcSearch[1])
		;~ $npcX = $npcSearch[0]
		;~ $npcY = $npcSearch[1]
		Return True
	EndIf 

EndFunc

; Method: searchNpcDevil
; Description: Tìm kiếm NPC Devil, thử di chuyển và click icon devil nếu không thấy
Func searchNpcDevil($charInfo, ByRef $npcX, ByRef $npcY)
	$charName = _JSONGet($charInfo, "char_name")
	$checkRuongK = _JSONGet($charInfo, "have_ruong_k")
	$isHaveQuest = _JSONGet($charInfo, "have_quest")
	$devilNo = _JSONGet($charInfo, "devil_no")
	
	writeLogFile($logFile, "Start method: searchNpcDevil " & " - devilNo" & $devilNo)
	$result = False

	Local $npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor, $npcSearch = 0, $totalSearch = 0

	While $npcSearch = 0 And $totalSearch < 5
		$npcSearch = npcSearchColorResult($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor)

		;~ If $npcSearch = 0 Then
		;~ 	$npcSearch = moveAndSearchNpcPixel($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor)
		;~ EndIf

		If $npcSearch = 0 Then
			clickIconDevil($charInfo)
			$totalSearch = $totalSearch + 1
		Else
			; Truong hop thay roi thi thoat khoi vong lap
			writeLogFile($logFile, "Da tim thay NPC tai vi tri : " & $npcSearch[0] & "-" & $npcSearch[1])
			$npcX = $npcSearch[0]
			$npcY = $npcSearch[1]
			$result = True
			ExitLoop
		EndIf
	WEnd

	Return $result
EndFunc   ;==>searchNpcDevil

Func npcSearchColorResult(ByRef $npcSearchX, ByRef $npcSearchY, ByRef $npcSearchX1, ByRef $npcSearchY1, ByRef $npcSearchColor)
	secondWait(1)
	$npcSearchColor = 0xB9AA95
	getNpcSearchArea($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1)
	Local $npcSearch = PixelSearch($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor, 5)
	Return $npcSearch
EndFunc   ;==>npcSearchColor

Func clickToNpcDevil($npcSearchX, $npcSearchY)
	$npcSearchDeviationX = _JSONGet($jsonPositionConfig, "button.npc_search.deviation_x")
	$npcSearchDeviationY = _JSONGet($jsonPositionConfig, "button.npc_search.deviation_y")
	$npcX = $npcSearchX + Number($npcSearchDeviationX)
	$npcY = $npcSearchY + Number($npcSearchDeviationY)
	mouseClickDelayAlt($npcX, $npcY)
	secondWait(3)
EndFunc
; Method: clickNpcDevil
; Description: Clicks on the NPC devil based on the search results and initiates the devil event.
Func clickNpcDevil($npcSearch, $devilNo, $isNeedFollowLeader)
	; Kiem tra xem co tim duoc vi tri cua npc khong $npcSearch <> 0
	If $npcSearch <> 0 Then
		writeLogFile($logFile, "Da tim thay NPC tai vi tri : " & $npcSearch[1] & "-" & $npcSearch[0])
		$npcSearchDeviationX = _JSONGet($jsonPositionConfig, "button.npc_search.deviation_x")
		$npcSearchDeviationY = _JSONGet($jsonPositionConfig, "button.npc_search.deviation_y")

		$npcX = $npcSearch[0] + Number($npcSearchDeviationX)
		$npcY = $npcSearch[1] + Number($npcSearchDeviationY)
		mouseClickDelayAlt($npcX, $npcY)
		secondWait(3)
		; Doan nay check xem co mo duoc bang devil hay khong ? Thuc hien check ma mau, neu tim thay thi moi click vao devil + bat autoZ
		$devil_open_x = _JSONGet($jsonPositionConfig, "button.event_devil.check_devil_open_x")
		$devil_open_y = _JSONGet($jsonPositionConfig, "button.event_devil.check_devil_open_y")
		$devil_open_color = _JSONGet($jsonPositionConfig, "button.event_devil.check_devil_open_color")

		$checkOpenDevil = checkOpenPopupDevil()
		If $checkOpenDevil Then
			writeLogFile($logFile, "Thuc hien click vao devil")
			clickPositionByDevilNo($devilNo)
			secondWait(4)
			_MU_Start_AutoZ()
		Else
			writeLogFile($logFile, "Khong tim thay vi tri cua popup chon devil")
			If $isNeedFollowLeader Then
				writeLogFile($logFile, "Thuc hien follow leader")
				_MU_followLeader(1)
			EndIf
		EndIf
	Else
		writeLogFile($logFile, "Search NPC khong thanh cong")
		If $isNeedFollowLeader Then
			writeLogFile($logFile, "Thuc hien follow leader")
			_MU_followLeader(1)
		EndIf
	EndIf
EndFunc   ;==>clickNpcDevil

; Method: clickPositionByDevilNo
; Description: Clicks on the specific devil event icon based on the devil number.
Func clickPositionByDevilNo($devilNo)
	writeLogFile($logFile, "Click position by devil no: " & $devilNo)
	$devil_position_x = _JSONGet($jsonPositionConfig, "button.event_devil_icon.devil_" & $devilNo & "_x")
	$devil_position_y = _JSONGet($jsonPositionConfig, "button.event_devil_icon.devil_" & $devilNo & "_y")
	writeLogFile($logFile, "Click position x: " & $devil_position_x & " y: " & $devil_position_y)
	_MU_MouseClick_Delay($devil_position_x, $devil_position_y)
EndFunc   ;==>clickPositionByDevilNo

Func checkOpenDevil()
	; Doan nay check xem co mo duoc bang devil hay khong ? Thuc hien check ma mau, neu tim thay thi moi click vao devil + bat autoZ
	$devil_open_x = _JSONGet($jsonPositionConfig, "button.event_devil.check_devil_open_x")
	$devil_open_y = _JSONGet($jsonPositionConfig, "button.event_devil.check_devil_open_y")
	$devil_open_color = _JSONGet($jsonPositionConfig, "button.event_devil.check_devil_open_color")

	$checkOpenDevil = checkPixelColor($devil_open_x, $devil_open_y, $devil_open_color)

	;~ _ArrayDisplay($checkOpenDevil)
	Return True
EndFunc   ;==>checkOpenDevil

Func resizeGame($GAME_TITLE)
	; === Tiêu đề cửa sổ MU ===
;~ Local $GAME_TITLE = getMainNoByChar($charName)

	; === Đợi game mở ===
	WinWait($GAME_TITLE, "", 3)
	$hWnd = WinGetHandle($GAME_TITLE)
	If @error Or $hWnd = "" Then
		;~ MsgBox(16, "Lỗi", "Không tìm thấy cửa sổ: " & $GAME_TITLE)
		writeLogFile($logFile, "Không tìm thấy cửa sổ: " & $GAME_TITLE)
		Exit
	EndIf

	; === Đặt kích thước khởi đầu 800x600 ===
	WinMove($hWnd, "", Default, Default, 800, 600)

	; === Đăng ký xử lý thông điệp resize ===
;~ GUIRegisterMsg($WM_SIZING, "WM_SIZING_Handler")

	; === Vòng lặp giữ script chạy ===
;~ While WinExists($hWnd)
;~ 	Sleep(100)
;~ WEnd

	Return True
EndFunc   ;==>resizeGame

; === Hàm giới hạn kích thước khi resize ===
Func WM_SIZING_Handler($hWndMsg, $iMsg, $wParam, $lParam)
	; Chỉ xử lý nếu đúng là cửa sổ MU
	If $hWndMsg <> $hWnd Then Return $GUI_RUNDEFMSG

	Local $tRect = DllStructCreate("long Left; long Top; long Right; long Bottom", $lParam)
	Local $width = DllStructGetData($tRect, "Right") - DllStructGetData($tRect, "Left")
	Local $height = DllStructGetData($tRect, "Bottom") - DllStructGetData($tRect, "Top")

	; Giới hạn kích thước
	If $width < $MIN_W Then DllStructSetData($tRect, "Right", DllStructGetData($tRect, "Left") + $MIN_W)
	If $height < $MIN_H Then DllStructSetData($tRect, "Bottom", DllStructGetData($tRect, "Top") + $MIN_H)
	If $width > $MAX_W Then DllStructSetData($tRect, "Right", DllStructGetData($tRect, "Left") + $MAX_W)
	If $height > $MAX_H Then DllStructSetData($tRect, "Bottom", DllStructGetData($tRect, "Top") + $MAX_H)

	Return True
EndFunc   ;==>WM_SIZING_Handler

Func checkActiveWinByChar($charName)
	Local $mainName = getMainNoByChar($charName)
	Return checkActiveWin($mainName)
EndFunc

Func checkActiveWin($mainName)
	Local $expected = $mainName
	Local $list = WinList()
	Local $i, $result
	For $i = 1 To $list[0][0]
		; so sánh tuyệt đối
		If $list[$i][0] = $expected Then
			$result = True
			ExitLoop
		EndIf
	Next
	If $result Then writeLogFile($logFile, "Tìm thấy MU đúng title: " & $expected)
	Return $result
EndFunc

; Method: closeWinByExactTitle
; Description: Dong cua so theo title chinh xac (khong dung prefix), cho toi da timeoutSec giay
Func closeWinByExactTitle($gameTitle, $timeoutSec = 10)
	If $gameTitle = "" Then
		writeLogFile($logFile, "LỖI: gameTitle rỗng, không thể đóng cửa sổ")
		Return False
	EndIf

	If Not WinExists($gameTitle) Then
		writeLogFile($logFile, "Không tìm thấy cửa sổ cần đóng: " & $gameTitle)
		Return True
	EndIf

	writeLogFile($logFile, "Thực hiện WinClose đúng title: " & $gameTitle)
	WinClose($gameTitle)

	Local $iWaitCount = 0
	While $iWaitCount < $timeoutSec
		If Not WinExists($gameTitle) Then
			writeLogFile($logFile, "✓ Đã đóng cửa sổ: " & $gameTitle)
			Return True
		EndIf

		$iWaitCount += 1
		secondWait(1)
	WEnd

	writeLogFile($logFile, "LỖI: Không thể đóng cửa sổ " & $gameTitle & " sau " & $timeoutSec & " giây")
	Return False
EndFunc

; Method: activeAndMoveWin
; Description: Activates and moves a specified window to the top-left corner of the screen.
Func activeAndMoveWin($mainName)
	;~ writeLogFile($logFile, "Begin active and move win: " & $mainName)
	Local $expected = $mainName
	Local $list = WinList()
	Local $i

	For $i = 1 To $list[0][0]
		; so sánh tuyệt đối
		If $list[$i][0] = $expected Then
			WinSetState($list[$i][1], "", @SW_SHOW)
			WinActivate($list[$i][1])
			WinMove($list[$i][1], "", 0, 0)
			resizeGame($list[$i][1])
			secondWait(2)
			Return True
		EndIf
	Next

	writeLogFile($logFile, "Không tìm thấy MU đúng title: " & $expected)
	Return False
EndFunc   ;==>activeAndMoveWin

Func closeWinExact($mainName)
	;~ writeLogFile($logFile, "Begin active and move win: " & $mainName)
	Local $expected = $mainName
	Local $list = WinList()
	Local $i

	For $i = 1 To $list[0][0]
		; so sánh tuyệt đối
		If $list[$i][0] = $expected Then
			 Local $hWnd = $list[$i][1]
        	Local $iPID = WinGetProcess($hWnd)
        	;~ ConsoleWrite($iPID & @CRLF)
			;~ WinClose($list[$i][1])
			writeLogFile($logFile, "Đã đóng cửa sổ: " & $expected)
			secondWait(2)
			Return True
		EndIf
	Next

	writeLogFile($logFile, "Không tìm thấy MU đúng title: " & $expected)
	Return False
EndFunc   ;==>closeWinExact

Func activeAndMoveWinByChar($charName)
	;~ writeLogFile($logFile, "Begin active and move win by char: " & $charName)
	$mainName = getMainNoByChar($charName)
	Return activeAndMoveWin($mainName)
EndFunc   ;==>activeAndMoveWinByChar

Func clickCenterChar()
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig, "button.screen_mouse_move.center_char_x"), _JSONGet($jsonPositionConfig, "button.screen_mouse_move.center_char_y"))
	Return True
EndFunc   ;==>clickCenterChar

; Send key enter
Func sendKeyEnter()
	sendKeyDelay("{Enter}")
EndFunc   ;==>sendKeyEnter

; Send key home
Func sendKeyHome()
	writeLogFile($logFile, "Send key home !")
	sendKeyDelay("{Home}")
	secondWait(1)
EndFunc   ;==>sendKeyHom

Func sendKeyTab()
	writeLogFile($logFile, "Send key tab !")
	sendKeyDelay("{Tab}")
	secondWait(1)
EndFunc   ;==>sendKeyTab

Func sendKeyEsc()
	writeLogFile($logFile, "Send key ESC !")
	sendKeyDelay("{ESC}")
	secondWait(1)
EndFunc   ;==>sendKeyEsc

Func sendKeyM()
	sendKeyDelay("m")
	secondWait(1)
EndFunc   ;==>sendKeyM

Func sendKeyC()
	sendKeyDelay("c")
	secondWait(1)
EndFunc   ;==>sendKeyC

Func sendKeyS()
	clickCenterChar()
	writeLogFile($logFile, "Send key +S !")
	sendKeyDelay("s")
	secondWait(1)
EndFunc   ;==>sendKeyS

Func sendKeyF8()
	writeLogFile($logFile, "Send key F8 !")
	sendKeyDelay("{F8}")
	secondWait(1)
EndFunc   ;==>sendKeyF8

; send key Shift + F
Func sendKeyShiftF()
	writeLogFile($logFile, "Send key Shift + F !")
	sendKeyDelay("+f")
	secondWait(1) 
EndFunc

; Huy trang thai Shift + F bang cach click vao giua man hinh
Func cancelShiftF()
	writeLogFile($logFile, "Cancel Shift + F by click center screen !")
	clickCenterChar()
	secondWait(1)
EndFunc


Func goMapArena($rsCount)
	; neu thoi gian tu phut 0 -5, 30 - 35 thi se cho cho toi khi thoi gian nay qua, sau do moi vao sport arena
	If (@MIN >= 0 And @MIN < 5) Or (@MIN >= 30 And @MIN < 35) Then
		writeLogFile($logFile, "Thoi gian hien tai: " & @HOUR & ":" & @MIN & " - Chua den thoi gian vao arena, cho toi 5 phut nua !")
		If (@MIN >= 0 And @MIN < 5) Then
			; Neu thoi gian tu 0 - 5 thi cho toi den 5 phut
			; Wait 5 minute
			minuteWait(5 - @MIN)
		Else
			; Neu thoi gian tu 30 - 35 thi cho toi den 35 phut
			; Wait 5 minute
			minuteWait(35 - @MIN)
		EndIf
	EndIf
	writeLogFile($logFile, "Bat dau map event arena ! ")
	; Click event icon then go arena map
	clickEventIcon()
	clickEventStadium()
	; Trong truong hop rs count < 30 thi chi toi sport 1 thoi, <50 thi ra port 2, nguoc lai thi ra sport 3
	$sportArenaNo = 3
	If ($rsCount < 30) Then
		$sportArenaNo = 1
	ElseIf ($rsCount < 50) Then
		$sportArenaNo = 2
	EndIf
	; Go to sport
	goSportStadium($sportArenaNo)
EndFunc   ;==>goMapArena

#cs
	Vao event Lvl
#ce
Func goMapLvl()
	writeLogFile($logFile, "Bat dau map event lvl ! ")

	; Click event icon
	clickEventIcon()

	; Click map lvl
	clickEventLvl()

	; Go to center
	goCenterMapLvl()

	; Enable Auto Home
	sendKeyHome()
EndFunc   ;==>goMapLvl

Func checkActiveParentMain($charName)
	$result = False
	; Check active main cha, neu chua duoc active thi thuc hien switch sang main cha
	$parentCharName = getOtherChar($charName)
	If activeAndMoveWinByChar($parentCharName) Then
		writeLogFile($logFile, "Main cha da duoc active roi: " & $parentCharName)
		minisizeMainByChar($parentCharName)
		$result = True
	Else
		writeLogFile($logFile, "Main cha chua duoc active: " & $parentCharName)
	EndIf
	Return $result
EndFunc   ;==>checkActiveParentMain

; Method: startAutoPlusWithReset
; Description: Mo Auto Plus, tick checkbox reset, click Start
Func startAutoPlusWithReset()
	; 1. Click vao button train in game (mo cua so Auto Plus)
	_MU_MouseClick_Delay(getProperty("button.train_in_game.button_x"), getProperty("button.train_in_game.button_y"))
	secondWait(2)
	; 2. Click vao checkbox reset de tick
	_MU_MouseClick_Delay(getProperty("button.train_in_game.checkbox_reset_x"), getProperty("button.train_in_game.checkbox_reset_y"))
	secondWait(1)
	; 3. Click vao button Start
	_MU_MouseClick_Delay(getProperty("button.train_in_game.button_start_x"), getProperty("button.train_in_game.button_start_y"))
EndFunc   ;==>startAutoPlusWithReset

; Method: startAutoPlusWithoutReset
; Description: Mo Auto Plus, bo tick checkbox reset, click Start
Func startAutoPlusWithoutReset()
	; 1. Click vao button train in game (mo cua so Auto Plus)
	_MU_MouseClick_Delay(getProperty("button.train_in_game.button_x"), getProperty("button.train_in_game.button_y"))
	secondWait(2)
	; 2. Click vao checkbox reset de bo tick
	_MU_MouseClick_Delay(getProperty("button.train_in_game.checkbox_reset_x"), getProperty("button.train_in_game.checkbox_reset_y"))
	secondWait(1)
	; 3. Click vao button Start
	_MU_MouseClick_Delay(getProperty("button.train_in_game.button_start_x"), getProperty("button.train_in_game.button_start_y"))
EndFunc   ;==>startAutoPlusWithoutReset

Func switchSvInGame($oAccountInfo)
	; 3. Thuc hien doi server trong game nhe
	_MU_MouseClick_Delay(getProperty("button.swith_sv_in_game.button_x"), getProperty("button.swith_sv_in_game.button_y"))
	; 4. click vao sv tuong ung voi server
	; Lay thong tin server server_number, sau do thuc hien click vao server tuong ung _MU_MouseClick_Delay(getProperty("button.swith_sv_in_game.choise_sv_1_x"), getProperty("button.swith_sv_in_game.choise_sv_1_u"))
	$serverNumber = $oAccountInfo.Item("serverNumber")
	$positionServerX = getProperty("button.swith_sv_in_game.choise_sv_" & $serverNumber & "_x")
	$positionServerY = getProperty("button.swith_sv_in_game.choise_sv_" & $serverNumber & "_y")
	If $positionServerX <> "" And $positionServerX <> Default And $positionServerY <> "" And $positionServerY <> Default Then
		writeLogFile($logFile, "Tim thay toa do server " & $serverNumber & " can vao: X: " & $positionServerX & " - Y: " & $positionServerY)
		_MU_MouseClick_Delay($positionServerX, $positionServerY)
	Else
		writeLogFile($logFile, "Khong tim thay toa do server " & $serverNumber & " can vao, mac dinh chon server 1 !")
		; Click vao chon sv 1
		_MU_MouseClick_Delay(getProperty("button.swith_sv_in_game.choise_sv_1_x"), getProperty("button.swith_sv_in_game.choise_sv_1_y"))	
	EndIf
EndFunc

; Thuc hien thay doi nhan vat, sau do thuc vao lai game ngay
Func changeThenReturnChar($charName)
	; Thuc hiện active cửa sổ game, kiểm tra xem nhân vật có được mở không, nếu không thì kiểm tra xem nhân vật cùng tài khoản có được mở không
	If checkActiveWinByChar($charName) Then
		writeLogFile($logFile, "Tim thay cua so game cho " & $charName)
		activeAndMoveWinByChar($charName)
	Else
		writeLogFile($logFile, "Khong tim thay cua so game cho " & $charName)
		switchOtherChar($charName)
		secondWait(5)
	EndIf
	
	; Thưc hiện thay đổi nhân vật nếu active được cửa sổ game, nếu không active được cửa sổ game nào thì thôi không cần thực hiện nữa
	If activeAndMoveWinByChar($charName) Then
		writeLogFile($logFile, "Da active duoc cua so game cho " & $charName & ", tiep tuc thuc hien reset online !")
		; Thuc hien thay doi nhan vat
		changeChar(getMainNoByChar($charName))
		secondWait(5)
		; Thuc hien return lại char
		returnChar(getMainNoByChar($charName))
	Else
		writeLogFile($logFile, "Khong the active duoc cua so game cho " & $charName & ", khong the thay đổi nhân vật online !")
	EndIf
	Return True
EndFunc

#cs
Thay đổi nhân vật để reset.
Trước khi thay đổi nhân vật cần check xem đã đủ lvl reset hay chưa ( 400 ).
Nếu không đủ lvl rs thì thực hiện follow leader ( mục đích nếu bị bắn về thành ) và chờ 15p để check lại lvl
Nếu đủ thì thực hiện thay đổi nhân vật
#ce
Func changeChar($mainNo)
	writeLogFile($logFile, "Begin change char !")
	Local $result = False
	; Lap lai hanh dong thay doi nhan vat cho toi khi nao thay doi duoc nhan vat moi (activeAndMoveWin($mainNo) = False). Toi da 3 lan thu, moi lan thu cach nhau 5s
	For $i = 1 To 3 Step +1
		sendKeyEsc()
		; Bam chon nhat vat khac
		_MU_MouseClick_Delay(getProperty("button.change_char.x"), getProperty("button.change_char.y"))
		secondWait(2) 
		If Not activeAndMoveWin($mainNo) Then
			writeLogFile($logFile, "Lan thu " & $i & ": Khong the active duoc cua so game sau khi bam chon nhan vat khac !")
			$result = True
			ExitLoop
		EndIf
	Next
	Return $result
EndFunc   ;==>changeChar

#cs
	Dang nhap lai vao nhan vat
#ce
Func returnChar($mainNo)
	$checkActive = activeAndMoveWin($mainNo)
	secondWait(1)
	writeLogFile($logFile, "Bat dau chon nhan vat vao lai game ! Main No: " & $mainNo)
	$timeCheck = 0
	While Not $checkActive And $timeCheck <= 5
		; Active title game main
		If activeAndMoveWin($titleGameMain) Then
			; Bam chon nhat vat khac
			secondWait(1)
			sendKeyEnter()
			secondWait(2)
			$checkActive = activeAndMoveWin($mainNo)
			If $checkActive Then secondWait(3)
		EndIf
		$timeCheck += 1
	WEnd

	If $checkActive Then
		writeLogFile($logFile, "Vao lai game thanh cong ! Main No: " & $mainNo)
	Else
		writeLogFile($logFile, "Vao lai game that bai ! Sau " & $timeCheck & " lan thu ! ")
	EndIf

EndFunc   ;==>returnChar

; Method: returnServer
; Description: Chon lai server de vao game sau khi reset
Func returnServer($serverNumber)
    writeLogMethodStart("returnServer", @ScriptLineNumber)

    If $serverNumber <= 0 Then $serverNumber = 1

    writeLogFile($logFile, "Begin return server !")
    writeLogFile($logFile, "Server number: " & $serverNumber)

    If Not activeAndMoveWin($titleGameMain) Then
        writeLogFile($logFile, "Khong the active title game main de vao server !")
        writeLogMethodEnd("returnServer", @ScriptLineNumber)
        Return False
    EndIf

    writeLogFile($logFile, "Bat dau chon server vao lai game !")
    secondWait(1)

    ; Click button mở danh sách server
    _MU_MouseClick_Delay(getProperty("button.change_server.choise_sv_x"), getProperty("button.change_server.choise_sv_y"))
    secondWait(2)

    ; Ưu tiên server cấu hình, nếu không có thì fallback về server 1
    If Not _clickServerChoice($serverNumber) Then
        writeLogFile($logFile, "Mac dinh chon server 1 !")
        If Not _clickServerChoice(1) Then
            writeLogFile($logFile, "Khong tim thay toa do server 1 !")
            writeLogMethodEnd("returnServer", @ScriptLineNumber)
            Return False
        EndIf
    EndIf

    secondWait(2)
    writeLogMethodEnd("returnServer", @ScriptLineNumber)
    Return True
EndFunc   ;==>returnServer

; Method: _clickServerChoice
; Description: Click vào tọa độ server theo số server, trả về True nếu thành công
Func _clickServerChoice($serverNumber)
    Local $svX = getProperty("button.change_server.choise_sv_" & $serverNumber & "_x")
    Local $svY = getProperty("button.change_server.choise_sv_" & $serverNumber & "_y")

    If $svX = "" Or $svX = Default Or $svY = "" Or $svY = Default Then
        writeLogFile($logFile, "Khong tim thay toa do server " & $serverNumber)
        Return False
    EndIf

    writeLogFile($logFile, "Tim thay toa do server " & $serverNumber & " can vao: X=" & $svX & " - Y=" & $svY)
    _MU_MouseClick_Delay(Number($svX), Number($svY))
    Return True
EndFunc   ;==>_clickServerChoice

Func followLeadThenStartAutoPlus($charName, $onAutoPlus, $timeWaitFollowLeader)
	writeLogFile($logFile, "Bat dau follow leader va start auto plus !" & " - Char: " & $charName & " - onAutoPlus: " & $onAutoPlus & " - timeWaitFollowLeader: " & $timeWaitFollowLeader)
	; Thuc hien click vao giua man hinh truoc da
	clickCenterChar()
	; follow leader
	_MU_followLeader(1)
	; start auto plus
	If $onAutoPlus Then startAutoPlus()
EndFunc

Func handleIsNotMainChar($oAccountInfo)
	$charName = $oAccountInfo.Item("charName")
	$mainNoMinisize = getMainNoByChar($charName)
	If Not $oAccountInfo.Item("isMainCharacter") Then
		writeLogFile($logFile, "Xu ly truong hop main khong phai la main chinh")
		$otherChar = $oAccountInfo.Item("mainCharName")
		If $otherChar <> "" Then
			$resultWwithChar = switchOtherChar($otherChar)
			If $resultWwithChar Then $mainNoMinisize = getMainNoByChar($otherChar)
		EndIf
		minisizeMain($mainNoMinisize)
		writeLogFile($logFile, "mainNoMinisize: " & $mainNoMinisize)
	EndIf
EndFunc

Func startStopAutoPlus()
	secondWait(1)
	stopAutoPlus()
	secondWait(2)
	startAutoPlus()
	secondWait(1)
EndFunc

Func stopAutoPlus()
	$stopAutoPlusX = _JSONGet($jsonPositionConfig, "button.train_in_game.button_stop_x")
	$stopAutoPlusY = _JSONGet($jsonPositionConfig, "button.train_in_game.button_stop_y")
	_MU_MouseClick_Delay($stopAutoPlusX, $stopAutoPlusY)

	Return True
EndFunc

Func startAutoPlus()
	; 1. Click vao button train in game
	_MU_MouseClick_Delay(getProperty("button.train_in_game.button_x"), getProperty("button.train_in_game.button_y"))
	; 2. Click vao button bat dau train
	secondWait(2)
	_MU_MouseClick_Delay(getProperty("button.train_in_game.button_start_x"), getProperty("button.train_in_game.button_start_y"))
	secondWait(1)
EndFunc
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
		_MU_MouseClick_Delay(995, 147)
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
	mouseMainClick(327, 104)
	; Click vao tat neu dang bat may quay chao
	mouseMainClick(508, 526)
EndFunc

Func openConsoleThenClear()
	; Send F12
	Send("{F12}")
	secondWait(2)
	; Click into console tab
	MouseClick("main",217, 782,2)
	; click clean console
	MouseClick("main",56, 815,2)
	; Click vao cuoi man hinh
	MouseClick("main",1837, 1006,1)
	secondWait(1)
EndFunc

Func clickEventIcon()
	writeLog("clickEventIcon() ")
	MouseClick("main",157, 119, 1)
	secondWait(1)
EndFunc

Func clickEventIconThenGoStadium() 
	clickEventIcon() 
	MouseClick("main",503, 493,1)
	secondWait(5)
EndFunc

Func clickEventStadium() 
	MouseClick("main",503, 493,1)
	secondWait(1)
EndFunc

Func checkActiveAutoHome()
	$pathImage = $imagePathRoot & "common" & "\not_active_auto_home.bmp"
	$result = True
	$imageSearchResult = _ImageSearch_Area($pathImage, 0, 0, 385, 103, 100, True)
	If $imageSearchResult[0] == 1 Then $result = False
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
	$jsonDevilConfig = getJsonFromFile($jsonPathRoot & "devil_config.json")
	Local $jsonAccountActiveDevil[0]
	For $i = 0 To UBound($jsonDevilConfig) -1
		; active win and check ruong K
		writeLog(_JSONGet($jsonDevilConfig[$i], "char_name"))
		$activeDevil = _JSONGet($jsonDevilConfig[$i], "active")
		If $activeDevil == True Then 
			Redim $jsonAccountActiveDevil[UBound($jsonAccountActiveDevil) + 1]
			$jsonAccountActiveDevil[UBound($jsonAccountActiveDevil) - 1] = $jsonDevilConfig[$i]
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
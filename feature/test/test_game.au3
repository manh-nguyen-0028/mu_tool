#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../auto_reset/auto_rs.au3"
;~ #include "../auto_devil/auto_devil.au3"

#include "../auto_reset/withdraw_rs.au3"
#RequireAdmin


$charName="Gamez"

;~ startPath()
;~ test()\
test3()
;~ start()


Func testChrome()
    $sSession = SetupChrome()
    secondWait(9)
    Return True
EndFunc

Func test3()
    ;~ $charName="RunOrDie"
	;~ $charName="Gamez"
	$charName="Porsche718"
	;~ $charName="MieMie"
	;~ $charName="GameCenter"

    $devilNo = 6
    
    $mainNo = getMainNoByChar($charName)

    activeAndMoveWin($mainNo)

    secondWait(2)

    checkLvl400($mainNo)
	;~ $devil_open_x = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_x")
	;~ $devil_open_y = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_y")
	;~ $devil_open_color = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_color")
	
	;~ $checkOpenDevil = checkPixelColor($devil_open_x, $devil_open_y, $devil_open_color)
    ;~ checkActiveAutoHome()
    ;~ clickEventIcon()
    ;~ clickIconDevil(True)
    ;~ searchNpcDevil(True, 4)

    ;~ checkLvl400($mainNo)
    ;~ clickEventIcon()
    ;~ checkLvl400($mainNo)
    ;~ clickEventStadium() 

    ;~ $rsCount = 99
    ;~ ; Trong truong hop rs count < 30 thi chi toi sport 1 thoi, <50 thi ra port 2, nguoc lai thi ra sport 3
	;~ $sportArenaNo = 3
	;~ If ($rsCount < 30) Then
	;~ 	$sportArenaNo = 1
	;~ ElseIf ($rsCount < 50) Then
	;~ 	$sportArenaNo = 2
	;~ EndIf
	; Go to sport
	;~ goSportStadium($sportArenaNo)

    minisizeMain($mainNo)
EndFunc

Func test()
    $charName="Cuongkd"
    
    $mainNo = getMainNoByChar($charName)

    writeLog("Get Main No: " & $mainNo)
    activeAndMoveWin($mainNo)
    secondWait(1)
    ;~ 64 620
    ;~ 0x81C024
    
    ; Test An Hien Main
    ;~ secondWait(3)
    ;~ writeLog("Bam F8")
    ;~ ; Example of calling a Windows API function
    ;~ Local $hwnd = WinGetHandle("[CLASS:Shell_TrayWnd]")
    ;~ If $hwnd Then
    ;~     ; Example API call; replace with actual call and parameters
    ;~     Local $result = DllCall("main.exe", "int", "SomeApiFunction", "hwnd", $hwnd)
    ;~ EndIf
    ;~ Send("{F8}") ; Send the F8 key
    ;~ activeAndMoveWin($mainNo)
    _MU_followLeader(1)
    ;~ writeLog(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_x"))
	;~ writeLog(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_y"))
    Return True
EndFunc

; Method: _MU_Search_Localtion
; Description: Searches for the NPC location during the devil event and clicks on it if found.
Func searchNpcDevil($checkRuongK, $devilNo)
	writeLogFile($logFile, "Start method: searchNpcDevil " & " - devilNo" & $devilNo)

	; Search NPC devil
	$npcSearchX = 0
	$npcSearchY = 0
	$npcSearchX1 = 720
	$npcSearchY1 = 793
	$npcSearchColor = 0xB9AA95

	$npcSearch = PixelSearch($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor)
	
	$totalSearch = 0;
	;~ 671 1050
	While $npcSearch = 0 And $totalSearch < 5
		$npcSearch = PixelSearch($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor)

		$countSearchPixel = 0;

		; Nếu tìm quá 3 lần ko thấy thì thực hiện click vao event devil
		While $npcSearch  = 0 And $countSearchPixel < 2
			$moveCheckNpcX = _JSONGet($jsonPositionConfig,"button.event_devil.move_check_npc_x")
			$moveCheckNpcY = _JSONGet($jsonPositionConfig,"button.event_devil.move_check_npc_y")
			_MU_MouseClick_Delay($moveCheckNpcX, $moveCheckNpcY)
			$npcSearch = PixelSearch($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor)
			$countSearchPixel = $countSearchPixel + 1;
		WEnd

		If $npcSearch  = 0 Then
			clickIconDevil($checkRuongK)
			$totalSearch = $totalSearch + 1
		EndIf
	WEnd
	
	; Neu tim thay toa do thi click vao npc
	clickNpcDevil($npcSearch, $devilNo)
EndFunc

; Method: clickNpcDevil
; Description: Clicks on the NPC devil based on the search results and initiates the devil event.
Func clickNpcDevil($npcSearch, $devilNo)
	; Kiem tra xem co tim duoc vi tri cua npc khong $npcSearch <> 0
	If $npcSearch <> 0 Then
		writeLogFile($logFile, "searchPixel : " & $npcSearch[1]& "-" & $npcSearch[0])
		$npcX = $npcSearch[0]-10
		$npcY = $npcSearch[1] + 20
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
		writeLogFile($logFile, "Khong tim thay vi tri cua NPC devil => Thuc hien len lai bai")
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
	_MU_MouseClick_Delay($devil_position_x, $devil_position_y)
EndFunc
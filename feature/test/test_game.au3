#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../auto_reset/auto_rs.au3"
;~ #include "../auto_devil/auto_devil.au3"

#include "../auto_reset/withdraw_rs.au3"
#RequireAdmin


$charName="SandyX"


activeAndMoveWin(getMainNoByChar($charName))
$checkRuongK = True
$devilNo = 3
$isNeedFollowLeader = False
; 221 -91
;~ writeLogFile($logFile, "Start method: searchNpcDevil " & " - devilNo" & $devilNo)
; Check and click into NPC devil
$npmSearchResult = searchNpcDevil($checkRuongK, $devilNo)




; Click into NPC devil
clickNpcDevil($npmSearchResult, $devilNo, $isNeedFollowLeader)

;~ secondWait(3)

;~ ;~ goMapLvl()
;~ moveOtherMap($charName)

secondWait(3)

;~ _MU_followLeader(1)

;~ $devil_open_x = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_x")
;~ 		$devil_open_y = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_y")
;~ 		$devil_open_color = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_color")
		

;~ 		$checkOpenDevil = checkPixelColor($devil_open_x, $devil_open_y, $devil_open_color)
;~ 		If $checkOpenDevil Then
;~ 			;~ clickPositionByDevilNo($devilNo)
;~ 			secondWait(4)
;~ 			;~ _MU_MouseClick_Delay(512, 477)
;~ 			_MU_Start_AutoZ()
;~ 		Else
;~ 			writeLogFile($logFile, "Khong tim thay vi tri cua popup chon devil => Thuc hien len lai bai")
;~ 			;~ If $isNeedFollowLeader Then _MU_followLeader(1)
;~ 		EndIf

;~ minisizeMain(getMainNoByChar($charName))

; Sử dụng hàm
;~ Local $hWnd = WinGetHandle(getMainNoByChar($charName)) ; Thay "Tên của cửa sổ" bằng tên cửa sổ cần thao tác
;~ ControlMouseMove($hWnd, "", 732, 95) ; Di chuyển chuột đến tọa độ (100, 50) trong control
;~ secondWait(1)
;~ ControlClick_NoFocus($hWnd, "", 732, 95) ; Click không chiếm chuột vào tọa độ (100, 50) trong control 

; Thuc hien swith sang main chinh
;~ $jsonAccountActiveDevil = getArrayActiveDevil()
;~ switchToMainChar($jsonAccountActiveDevil)


Func testControlClick()
	; Lấy handle của cửa sổ Q-Dir
	$charName="ThuTuong"
	$mainNo = getMainNoByChar($charName)
    Local $hWnd = WinGetHandle($mainNo)

    ; Kiểm tra nếu cửa sổ có tồn tại
    If Not @error Then
        ; Thực hiện click tại tọa độ (186, 11) của control SysTabControl32, Instance 4
        ControlMouseDown($hWnd,727, 101)
		Sleep(500) ; Tạm dừng 500ms để đảm bảo thực hiện xong
		ControlMouseUp($hWnd, 727, 101)
		;~ ControlSend($hWnd, "", "","{Enter}")
    Else
        ConsoleWrite("Không tìm thấy cửa sổ Q-Dir!" & @CRLF)
    EndIf

	
	Return True
EndFunc

Func ControlMouseDown($hWnd, $toadoX, $toadoY)
	; Nhấn chuột mà không nhả ra
	ControlClick($hWnd, "", "", "Left", 10, $toadoX, $toadoY)
	Sleep(1000) ; Thời gian nhấn giữ
EndFunc

Func ControlMouseUp($hWnd, $toadoX, $toadoY)
	; Nhả chuột bằng một lần nhấn tiếp theo
	ControlClick($hWnd, "", "", "Left", 10, $toadoX, $toadoY)
EndFunc


Func testChrome()
    $sSession = SetupChrome()
    secondWait(9)
    Return True
EndFunc

Func test3()
    ;~ $charName="RunOrDie"
	;~ $charName="Gamez"
	;~ $charName="Porsche718"
	;~ $charName="MieMie"
	;~ $charName="GameCenter"
	;~ $charName="HaGiangOi"
	;~ $charName="ThuTuong"

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
	$npcSearchColor = 0x2A1B43

	$npcSearch = PixelSearch($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor,5)
	
	$totalSearch = 0;
	;~ 671 1050
	;~ While $npcSearch = 0 And $totalSearch < 5
	;~ 	$npcSearch = PixelSearch($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor)

	;~ 	$countSearchPixel = 0;

	;~ 	; Nếu tìm quá 3 lần ko thấy thì thực hiện click vao event devil
	;~ 	While $npcSearch  = 0 And $countSearchPixel < 2
	;~ 		$moveCheckNpcX = _JSONGet($jsonPositionConfig,"button.event_devil.move_check_npc_x")
	;~ 		$moveCheckNpcY = _JSONGet($jsonPositionConfig,"button.event_devil.move_check_npc_y")
	;~ 		_MU_MouseClick_Delay($moveCheckNpcX, $moveCheckNpcY)
	;~ 		$npcSearch = PixelSearch($npcSearchX, $npcSearchY, $npcSearchX1, $npcSearchY1, $npcSearchColor)
	;~ 		$countSearchPixel = $countSearchPixel + 1;
	;~ 	WEnd

	;~ 	If $npcSearch  = 0 Then
	;~ 		clickIconDevil($checkRuongK)
	;~ 		$totalSearch = $totalSearch + 1
	;~ 	EndIf
	;~ WEnd
	;~ writeLogFile($logFile, "searchNpcDevil result: " & $npcSearch[0] & "- " & $npcSearch[1])
	MouseMove($npcSearch[0],$npcSearch[1])
	;~ _ArrayDisplay($npcSearch)
	Return $npcSearch
EndFunc

; Method: clickNpcDevil
; Description: Clicks on the NPC devil based on the search results and initiates the devil event.
Func clickNpcDevil($npcSearch, $devilNo, $isNeedFollowLeader)
	; Kiem tra xem co tim duoc vi tri cua npc khong $npcSearch <> 0
	If $npcSearch <> 0 Then
		writeLogFile($logFile, "searchPixel : " & $npcSearch[1]& "-" & $npcSearch[0])
		$npcSearchDeviationX = _JSONGet($jsonPositionConfig,"button.npc_search.deviation_x")
		$npcSearchDeviationY = _JSONGet($jsonPositionConfig,"button.npc_search.deviation_y")

		writeLogFile($logFile, "Do chenh lech: X= " & $npcSearchDeviationX & " - Y= " & $npcSearchDeviationY)

		$npcX = $npcSearch[0] - 131
		$npcY = $npcSearch[1]
		;~ mouseClickDelayAlt($npcX, $npcY)
		MouseMove($npcX, $npcY)
		secondWait(3)
		;~ ; Doan nay check xem co mo duoc bang devil hay khong ? Thuc hien check ma mau, neu tim thay thi moi click vao devil + bat autoZ
		;~ $devil_open_x = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_x")
		;~ $devil_open_y = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_y")
		;~ $devil_open_color = _JSONGet($jsonPositionConfig,"button.event_devil.check_devil_open_color")
		
		;~ $checkOpenDevil = checkPixelColor($devil_open_x, $devil_open_y, $devil_open_color)
		;~ If $checkOpenDevil Then
		;~ 	writeLogFile($logFile, "Thuc hien click vao devil")
		;~ 	clickPositionByDevilNo($devilNo)
		;~ 	secondWait(6)
		;~ 	_MU_Start_AutoZ()
		;~ Else
		;~ 	writeLogFile($logFile, "Khong tim thay vi tri cua popup chon devil")
		;~ 	If $isNeedFollowLeader Then 
		;~ 		writeLogFile($logFile, "Thuc hien follow leader")
		;~ 		_MU_followLeader(1)
		;~ 	EndIf
		;~ EndIf
	Else
		writeLogFile($logFile, "Search NPC khong thanh cong")
		;~ If $isNeedFollowLeader Then 
		;~ 	writeLogFile($logFile, "Thuc hien follow leader")
		;~ 	_MU_followLeader(1)
		;~ EndIf
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
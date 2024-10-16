#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../auto_reset/auto_rs.au3"
;~ #include "../auto_devil/auto_devil.au3"

#include "../auto_reset/withdraw_rs.au3"
#RequireAdmin

;~ startPath()
;~ test()
test3()
;~ start()

Func test3()
    $charName="GymerX"

    $devilNo = 6
    
    $mainNo = getMainNoByChar($charName)

    activeAndMoveWin($mainNo)

    secondWait(2)

    checkActiveAutoHome()
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
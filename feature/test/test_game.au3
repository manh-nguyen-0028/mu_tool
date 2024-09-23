#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../auto_reset/auto_rs.au3"

#include "../auto_reset/withdraw_rs.au3"
#RequireAdmin

;~ startPath()
test()
;~ start()

Func test()
    $charName="Louis"
    
    $mainNo = getMainNoByChar($charName)

    writeLog("Get Main No: " & $mainNo)
    activeAndMoveWin($mainNo)
    ; Test An Hien Main
    secondWait(3)
    writeLog("Bam F8")
    ; Example of calling a Windows API function
    Local $hwnd = WinGetHandle("[CLASS:Shell_TrayWnd]")
    If $hwnd Then
        ; Example API call; replace with actual call and parameters
        Local $result = DllCall("main.exe", "int", "SomeApiFunction", "hwnd", $hwnd)
    EndIf
    ;~ Send("{F8}") ; Send the F8 key
    ;~ activeAndMoveWin($mainNo)
    ;~ _MU_followLeader(1)
    ;~ writeLog(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_x"))
	;~ writeLog(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_y"))
    Return True
EndFunc
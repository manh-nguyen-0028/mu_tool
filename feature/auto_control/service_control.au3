#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../auto_reset/auto_rs.au3"
#include "../auto_reset/withdraw_rs.au3"
#RequireAdmin

;~ startPath()
;~ test()
start()

Func test()
    $charName="MonkeyKing"
    $mainNo = getMainNoByChar($charName)
    activeAndMoveWin($mainNo)
    _MU_followLeader(1)
    Return True
EndFunc

Func start()
    While True
        ;~ If @HOUR < 20 Or @HOUR > 22 Then startPath()
        If @HOUR < 19 Or @HOUR > 22 Then 
            writeLog("Start rs")
            startWithDrawRs()
            secondWait(30)
            startAutoRs()
        EndIf
        waitToNextHourMinutes(1, 31, 00)
    WEnd
EndFunc

Func startPath()
    ; withdraw reset
    $exePath = $featurePathRoot &"auto_reset\withdraw_rs.exe"

    writeLog($exePath)
    Run($exePath)

    ProcessWaitClose("withdraw_rs.exe")
    secondWait(30)

    ; auto reset
    $exePath = $featurePathRoot &"auto_reset\auto_rs.exe"

    writeLog($exePath)
    Run($exePath)

    ProcessWaitClose("auto_rs.exe")
    Return True
EndFunc
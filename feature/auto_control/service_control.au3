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
    $charName="EasyGamez"
    $mainNo = getMainNoByChar($charName)
    ;~ activeAndMoveWin($mainNo)
    ;~ _MU_followLeader(1)
    writeLog(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_x"))
    writeLog(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_y"))
    Return True
EndFunc

Func start()
    ; 1. Delete file in folder log
    deleteFileInFolder($outputPathRoot)

    While True
        ;~ If @HOUR <> 23 And checkProcessExists("mu_auction.exe") == FALSE
        If checkProcessExists("mu_auction.exe") == False And @HOUR <> 23 Then 
            writeLog("Start rs")
            ;~ startWithDrawRs()
            ;~ secondWait(10)
            startAutoRs()
        EndIf
        waitToNextHourMinutes(1, 38, 00)
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
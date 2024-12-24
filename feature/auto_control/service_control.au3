#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../auto_reset/auto_rs.au3"

#include "../auto_reset/withdraw_rs.au3"
#RequireAdmin

;~ startPath()
;~ test()
start()

; Method: test
; Description: A test function that retrieves the main number associated with a character name and logs the positions for the follow leader button.
Func test()
    $charName="EasyGamez"
    $mainNo = getMainNoByChar($charName)
    ;~ activeAndMoveWin($mainNo)
    ;~ _MU_followLeader(1)
    writeLog(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_x"))
    writeLog(_JSONGet($jsonPositionConfig,"button.follow_leader.position_1_y"))
    Return True
EndFunc

; Method: start
; Description: Main function that deletes log files, checks if the "mu_auction.exe" process is running, and starts the auto reset process if the process is not running and the current hour is not 23.
Func start()
    ; 1. Delete file in folder log
    ;~ deleteFileInFolder($outputPathRoot)

    While True
        If Not checkProcessExists("mu_auction.exe") And @HOUR <> 23 Then 
            writeLog("Start rs")
            ;~ startWithDrawRs()
            ;~ secondWait(10)
            startAutoRs()
        EndIf
        waitToNextHourMinutes(1, 38, 00)
    WEnd
EndFunc

; Method: startPath
; Description: Executes the withdraw reset and auto reset processes sequentially, logging the paths and waiting for each process to close before proceeding.
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
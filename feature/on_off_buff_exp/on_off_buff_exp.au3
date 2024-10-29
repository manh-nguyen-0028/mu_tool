#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#RequireAdmin

Local $toaDoBuffX = 875, $toaDoBuffY = 589
Local $toaDoSaveAutoX = 915, $toaDoSaveAutoY = 673

Func onOffBuffExp($charName, $isOnBuff)
    $checkOffBuff = False
    ; Thuc hien open main + check xem da duoc bat buff chua
    $mainNo = getMainNoByChar($charName)
    writeLog("Bat dau bat z")
    ; check active win
    $checkActiveWin = activeAndMoveWin($mainNo)

    ; Truong hop main hien tai khong duoc active, active main khac
    If Not $checkActiveWin Then $checkActiveWin = switchOtherChar($charName)

    If Not $checkActiveWin Then 
        writeLogFile($logFile, "Khong tim duoc main active voi char: " & $charName)
    Else
        ; Bat phim Z
        sendKeyDelay("z")

        secondWait(2)
        If $isOnBuff Then 
            ; Kiem tra xem co phai o trang thai CHUA BAT ( off ) buff hay khong
            $checkOffBuff = checkAutoOffBuff()
        Else
            ; Kiem tra xem co phai o trang thai BAT buff ( on ) hay khong
            $checkOffBuff = checkAutoOnBuff()
        EndIf
        
        writeLogFile($logFile,"checkOffBuff: " & $checkOffBuff)

        If $checkOffBuff Then
            ; Click vao vi tri bat/tat auto buff
            _MU_MouseClick_Delay($toaDoBuffX, $toaDoBuffY)
            ; Click vao button Save auto
            _MU_MouseClick_Delay($toaDoSaveAutoX, $toaDoSaveAutoY)
        Else
            ; Tat bang Z
            secondWait(2)
            sendKeyDelay("z")
        EndIf

        ; An win
        minisizeMain($mainNo)
    EndIf
EndFunc
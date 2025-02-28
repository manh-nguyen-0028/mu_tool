#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"
#include "../../utils/game_utils.au3"
#RequireAdmin

; Các công việc cần thực hiện
; Lấy các account cần auto login trong file json
; Kiểm tra xem hiện tại đã tồn tại chưa
; Nếu tồn tại rồi thì thực hiện enter 2 lần
; Check lại xem còn main hay không ? Nếu không thì thực hiện login
; Thực hiện login (mở chương trình game, nhập user, pass, enter)

Func start()
    
    Return True
EndFunc

Func processAutoLogin()
    $jAccountActive = getJsonFromFile($jsonPathRoot & $autoLoginFileName)

    ; Neu khong co account nao thi thoat
    If UBound($jAccountActive) = 0 Then
        writeLogFile($logFile, "Khong co account nao de auto login.")
        Return False
    Else
        writeLogFile($logFile, "Co " & UBound($jAccountActive) & " account de auto login.")
        
        ; Duyet qua tung account de auto login
        For $i = 0 To UBound($jAccountActive) - 1
            $active = getPropertyJson($jAccountActive[$i], "active")
            If $active Then
                $username = getPropertyJson($jAccountActive[$i], "username")
                $password = getPropertyJson($jAccountActive[$i], "password")
                $charName = getPropertyJson($jAccountActive[$i], "char_name")
                $mainName = getMainNoByChar($charName)
                $activeMainNo = activeAndMoveWin($mainName)
                $needLogin = False
                If Not $activeMainNo Then
                    writeLogFile($logFile, "Khong tim thay main no: " & $mainName)
                    $needLogin = True
                    Return False
                Else
                    writeLogFile($logFile, "Tim thay main no: " & $mainName)
                    sendKeyEnter()
                    sendKeyEnter()
                    If Not activeAndMoveWin($charName) Then $needLogin = True
                EndIf

                If $needLogin Then processLogin($username, $password, $charName)
            EndIf
        Next
    EndIf
    Return True
EndFunc

Func processLogin($username, $password, $charName)
    ; Mở chương trình game
    ; Đường dẫn đến file game .exe
    $gamePath = "C:\Path\To\Your\Game.exe"
    
    ; Chạy chương trình game
    Run($gamePath)

    ; Chờ 5s
    secondWait(5)

    ; Kích hoạt cửa sổ game
    WinActivate("Tên cửa sổ của game")

    ; Click vao vi tri dang nhap
    _MU_MouseClick_Delay(100,100)

    ; Chờ 5s
    secondWait(5)

    ; Click vao vi tri them tai khoan
    _MU_MouseClick_Delay(100,100)

    ; Click vao tri tri dien user sau do nhap user name + pass
    ; Click username
    _MU_MouseClick_Delay(100,100)
    sendKeyDelay($username)

    ; Click password
    _MU_MouseClick_Delay(100,100)
    sendKeyDelay($password)

    ; Click vao nhap xong
    _MU_MouseClick_Delay(100,100)

    ; click vao vi tri dang nhap
    _MU_MouseClick_Delay(100,100)

    $mainName = getMainNoByChar($charName)

    $activeMainNo = activeAndMoveWin($mainName)

    $countWait = 0

    While Not activeAndMoveWin($mainName) And $countWait < 10
        secondWait(10)
        chonServer()
        $countWait += 1
    WEnd
    
    If activeAndMoveWin($mainName) Then
        writeLogFile($logFile, "Login success.")
        ; Bam shift + h
        sendKeyH()

        ; minimize window
        minisizeMain($mainName)
    Else
        writeLogFile($logFile, "Login fail.")
    EndIf

    Return True
EndFunc

Func chonServer()
    ; Chon server ( HN, BV ...)
    _MU_MouseClick_Delay(100,100)

    ; Chọn kênh
    _MU_MouseClick_Delay(100,100)

    ; Chờ 5s
    secondWait(5)

    ; Send enter để vào game
    sendKeyEnter()

    Return True
EndFunc
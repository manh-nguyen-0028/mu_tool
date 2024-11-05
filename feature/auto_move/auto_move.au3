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

Local $aActiveMove[0]
Local $sSession,$logFile
Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
Local $sDate = @YEAR & @MON & @MDAY
Local $className = @ScriptName


Local $sFilePath = $outputPathRoot & "File_Log_Auto_Move.txt"

Func start()
    writeLogFile($logFile, "Begin start auto move !")
    ; 1. Thuc hien lay danh sach account can auto move, chi lay nhung account co active = true
    $aAccountAutoMove = getJsonFromFile($jsonPathRoot & $autoMoveConfigFileName)
    For $i = 0 To UBound($aAccountAutoMove) - 1
        $active = getPropertyJson($aAccountAutoMove[$i], "active")
        If $active Then
            Redim $aActiveMove[UBound($aActiveMove) + 1]
            $aActiveMove[UBound($aActiveMove) - 1] = $aAccountAutoMove[$i]
        EndIf
    Next

    ; 1.1. Kiem tra xem co account nao active khong
    If UBound($aActiveMove) == 0 Then 
        writeLogFile($logFile, "Khong co account nao active => Ket thuc chuong trinh !")
        FileClose($logFile)
        Return
    EndIf

    ; 2. Thuc hien lay danh sach password account
    $aAccountPassword = getJsonFromFile($jsonPathRoot & $accountPasswordFileName)
    ; Merge thong tin $aActiveMove va $aAccountPassword
    $aActiveMove = mergeInfoAccountRs($aActiveMove, $aAccountPassword)
    writeLogFile($logFile, "Thong tin account sau khi merge: " & $aActiveMove)
    ; 3. Duyet danh sach account da active auto move, kiem tra xem co duoc active hay khong 
    For $i = 0 To UBound($aActiveMove) - 1
        $charName = getPropertyJson($aActiveMove[$i], "char_name")
        $mainName = getMainNoByChar($charName)
        If activeAndMoveWin($mainName) Then
            writeLogFile($logFile, "Account " & $mainName & " da active va move thanh cong")
            ; 3.2. Neu co thi kiem tra xem autoZ co hoat dong hay khong
            $checkAutoZ = checkActiveAutoHome()
            ; 3.2.1. Neu autoZ hoat dong thi thuc hien minizie cua so game
            If checkActiveAutoHome() Then 
                minisizeMain($mainName)
            Else
                ; 3.2.2. Neu autoZ khong hoat dong thi thuc hien login va move tren web
                ; open chorme
                $sSession = SetupChrome()
                $username = getPropertyJson($aActiveMove[$i], "user_name")
                $password = getPropertyJson($aActiveMove[$i], "password")
                ;~ "switch_map": false,
                ;~ "map_name": "Lorencia",
                ;~ "postion_move_x": 100,
                ;~ "postion_move_y": 100
                $swithMap = getPropertyJson($aActiveMove[$i], "switch_map")
                $mapName = getPropertyJson($aActiveMove[$i], "map_name")
                $postionMoveX = getPropertyJson($aActiveMove[$i], "postion_move_x")
                $postionMoveY = getPropertyJson($aActiveMove[$i], "postion_move_y")

                $loginSuccess = login($sSession, $username, $password)
                ; 3.2.1.2. Thuc hien move tren web
                If $loginSuccess Then
                    If $swithMap Then
                        ;~ moveToMapInWeb($sSession, $mapName)
                    Else
                        moveToPostionInWeb($sSession, $charName, $postionMoveX, $postionMoveY)
                        ; Doi khoang 1 phut
                        minuteWait(1)
                    EndIf
                    ; 3.2.1.4. Thuc hien logout
                    _WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
                    secondWait(5)
                EndIf
            EndIf
        Else
            writeLogFile($logFile, "Account " & $mainName & " da active nhung move khong thanh cong")
        EndIf
    Next
    
    Return True
EndFunc
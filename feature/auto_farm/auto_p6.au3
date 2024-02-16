#include <date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../../include/_ImageSearch_UDF.au3"
#include "../auto_reset/withdraw_rs.au3"
#RequireAdmin

Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
Local $aAccountActiveFarm[0]

; Cac cong viec can lam
; 1. Mo file config. Check xem con thoi gian vao p6 hay khong ( time rs >= 29 ). 
;   +Thuc hien mo main => Neu co hoat dong main thi thuc hien rut rs. Neu khong thi khong lam gi ca
; 2. Duyet danh sach nhan vat => open main tuong ung voi nhan vat
; 3. Check xem co dang active auto hay khong
; 4. Truong hop dang active => khong can lam gi ca
; 5. Truong hop dang de-active => Lay thong tin map, toa do sau do move len
; 6. minisize main

start()

Func start()
	Local $sFilePath = $outputPathRoot & "File_" & $sDateTime & ".txt"
	$logFile = FileOpen($sFilePath, $FO_OVERWRITE)
	$charFarmConfig = getJsonFromFile($jsonPathRoot & "account_reset.json")
	For $i = 0 To UBound($charFarmConfig) - 1
		$active = getPropertyJson($charFarmConfig[$i], "active")
		If $active == True Then
			Redim $aAccountActiveFarm[UBound($aAccountActiveFarm) + 1]
			$aAccountActiveFarm[UBound($aAccountActiveFarm) - 1] = $charFarmConfig[$i]
		EndIf
	Next
EndFunc

Func checkTimeP6()
    For $i = 0 To UBound($aAccountActiveFarm) - 1
        $lastTimeRs = getPropertyJson($aAccountActiveFarm[$i], "last_time_reset")
        $hourPerRs = getPropertyJson($aAccountActiveWithrawRs[$i],"hour_per_reset")
        $nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
        $charName = getPropertyJson($aAccountActiveWithrawRs[$i],"char_name")
        $timeNow = getTimeNow()
        $mainNo = getMainNoByChar($charName)
        $activeMain = activeAndMoveWin($mainNo)

        If $activeMain == True Then
            If $timeNow < $nextTimeRs Then 
                writeLogFile($logFile, "Chua het thoi gian phong 6. Last time rs: " & $lastTimeRs)
                ; check active auto home
                $activeAutoHome = checkActiveAutoHome()
                If $activeAutoHome == False Then
                    ; Move toi toa do duoc chi dinh
                    $positionMove = getPropertyJson($aAccountActiveWithrawRs[$i],"position")
                    $toaDoX = StringSplit($positionMove,"-")[1]
                    $toaDoY = StringSplit($positionMove,"-")[2]
                    ; Bam tab va move
                    Send("{Tab}")
	                secondWait(2)
                    _MU_MouseClick_Delay($toaDoX, $toaDoY)
                    secondWait(1)
	                Send("{Tab}")
                    minisizeMain($mainNo)
                EndIf
            Else
                writeLogFile($logFile, "Chuan bi het thoi gian phong 6. Bat dau thuc hien reset. Last time rs: " & $lastTimeRs)
                ; bat dau reset
                $username = getPropertyJson($aAccountActiveWithrawRs[$i],"user_name")
                $password = getPropertyJson($aAccountActiveWithrawRs[$i],"password")
                ; Begin withdraw reset
                checkThenCloseChrome()
                ; open sesssion chrome 
                $sSession = SetupChrome()
                secondWait(5)
                withdrawRs($username, $password, $charName,$hourPerRs)
                ; Logout account
                _WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
                secondWait(5)
                ; Close webdriver neu thuc hien xong 
                If $sSession Then _WD_DeleteSession($sSession)
                
                _WD_Shutdown()
            EndIf
        EndIf
	Next
    Return True
EndFunc

Func getConfigFarm()

EndFunc
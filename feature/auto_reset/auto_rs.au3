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

$className = "auto_rs.au3"

;~ startAutoRs()

Func startAutoRs()
	Local $aAccountActive[0], $aAccountWithDraw[0], $aAccountActiveRs[0]
	; get array account need withdraw reset
	Local $sFilePath = $outputPathRoot & "File_Log_AutoRS_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	writeLogMethodStart("startAutoRs", @ScriptLineNumber)
	writeLogFile($logFile, "Begin start auto reset !", @ScriptLineNumber)

	$jAccMerge = mergeInfoAccountRs()

	For $i = 0 To UBound($jAccMerge) - 1
		$active = getPropertyJson($jAccMerge[$i], "active")
		$type = getPropertyJson($jAccMerge[$i], "type")
		; Tu gio se chia ra 2 loai type = reset hoac withdraw
		; "reset" la reset account, "withdraw" la withdraw account
		If $active Then
			$aAccountActive = redimArray($aAccountActive, $jAccMerge[$i])
			If "withdraw" == $type Then
				$aAccountWithDraw = redimArray($aAccountWithDraw, $jAccMerge[$i])
			Else
				$aAccountActiveRs = redimArray($aAccountActiveRs, $jAccMerge[$i])
			EndIf
		EndIf
	Next

	If UBound($aAccountActive) == 0 Then
		writeLogFile($logFile, "Khong co account nao active => Ket thuc chuong trinh !")
		FileClose($logFile)
		Return
	EndIf

	; Validate account reset
	$aAccValidate = validAccountRs($aAccountActive)

	If UBound($aAccValidate) == 0 Then
		writeLogFile($logFile, "Khong co account valid thoa man => Ket thuc chuong trinh !")
		FileClose($logFile)
		Return
	Else
		; close all chrome browser
		checkThenCloseChrome()
		$sSession = SetupChrome()
		; Thuc hien sap xep lai thu tu $aAccValidate theo user_name
		$aAccValidate = sortArrayByProperty($aAccValidate, "user_name", True)
	EndIf

	For $i = 0 To UBound($aAccValidate) - 1
		$type = getPropertyJson($aAccValidate[$i], "type")
		writeLogFile($logFile, "type rs = " & $type & "---" & "Dang xu ly voi account => " & convertJsonToString($aAccValidate[$i]))

		If "withdraw" == $type Then
			withDrawRs($aAccValidate[$i])
		Else
			reset($aAccValidate[$i])
		EndIf

		; Trong truong hop van con user trong $aAccValidate va user $aAccValidate[$i +1] trung username voi user hien tai thi khong thuc hien logout
		Local $currentUser = getPropertyJson($aAccValidate[$i], "user_name")
		Local $nextUser = ""
		If $i + 1 < UBound($aAccValidate) Then
			$nextUser = getPropertyJson($aAccValidate[$i + 1], "user_name")
		EndIf
		writeLogFile($logFile, " $currentUser: " & $currentUser & " - $nextUser: " & $nextUser)
		If $currentUser <> $nextUser Then
			writeLogFile($logFile, " $currentUser <> $nextUser => Thuc hien logut")
			logout($sSession)
		EndIf
	Next

	writeLogMethodEnd("startAutoRs", @ScriptLineNumber)

	FileClose($logFile)

	; Close webdriver neu thuc hien xong
	If $sSession Then
		_WD_DeleteSession($sSession)
		_WD_Shutdown()
	EndIf

EndFunc   ;==>startAutoRs

Func reset($jAccountInfo)
	$charName = getPropertyJson($jAccountInfo, "char_name")
	$resetOnline = getPropertyJson($jAccountInfo, "reset_online")
	$mainNo = getMainNoByChar($charName)
	writeLogFile($logFile, "Begin handle reset with account: " & $charName & " - reset online: " & $resetOnline & " - main no: " & $mainNo)
	If Not $resetOnline Then
		; Begin reset
		$activeMain = activeAndMoveWin($mainNo)
		; Truong hop main hien tai khong duoc active, active main khac
		If Not $activeMain Then $activeMain = switchOtherChar($charName)
		If $activeMain Then
			; Thuc hien minize main
			minisizeMain($mainNo)
			; Neu dang o phut thut > 52 hoac < 8 thi thuc hien doi cho den khi o phut > 8
			$minuteCheck = Number(@MIN)
			If $minuteCheck > 52 Then
				$minuteWait = (60 - $minuteCheck) + 8
				minuteWait($minuteWait)
			ElseIf $minuteCheck < 8 Then
				; Wait 1 min
				$minuteWait = 8 - $minuteCheck
				minuteWait($minuteWait)
			EndIf
			processReset($jAccountInfo)
		EndIf
	Else
		processReset($jAccountInfo)
	EndIf
	writeLogFile($logFile, "End handle reset with account: " & getPropertyJson($jAccountInfo, "char_name"))
EndFunc   ;==>reset

Func withDrawRs($jAccountInfo)
	writeLogMethodStart("processWithDrawReset", @ScriptLineNumber, $jAccountInfo)
	$username = getPropertyJson($jAccountInfo, "user_name")
	$password = getPropertyJson($jAccountInfo, "password")
	$charName = getPropertyJson($jAccountInfo, "char_name")
	$hourPerRs = getPropertyJson($jAccountInfo, "hour_per_reset")
	$resetOnline = getPropertyJson($jAccountInfo, "reset_online")
	$isMainCharacter = getPropertyJson($jAccountInfo, "is_main_character")
	$mainCharName = getPropertyJson($jAccountInfo, "main_char_name")

	writeLogFile($logFile, "Begin handle withdraw reset with account: " & $charName)
	$isLoginSuccess = login($sSession, $username, $password)
	secondWait(5)
	If $isLoginSuccess Then
		; Check IP
		$haveIP = checkIP($sSession)
		If Not $haveIP Then
			writeLogFile($logFile, "Khong co IP hoac IP khong hop le, ket thuc xu ly !")
			; Cap nhat time rs de khong thuc hien lai nua ( time = time + 24h)
			$timeNow = getTimeNow()
			$hourPerRs = 24
			$lastTimeRs = _DateAdd('h', $hourPerRs, $timeNow)
			updateLastTimeRs($charName, $lastTimeRs)
			Return False
		Else
			writeLogFile($logFile, "Co IP hop le, tiep tuc xu ly !")
			$timeNow = getTimeNow()
			$sLogReset = getLogReset($sSession, $charName)
			$lastTimeRs = getTimeReset($sLogReset, 0)
			$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
			If $timeNow < $nextTimeRs Then
				writeLogFile($logFile, "Chua den thoi gian reset. getTimeNow() < $nextTimeRs = " & $timeNow < $nextTimeRs)
				writeLogFile($logFile, "Thoi gian hien tai: " & $timeNow)
				writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
				updateLastTimeRs($charName, $lastTimeRs)
				Return
			EndIf

			; withraw reset
			$errorIp = _Demo_NavigateCheckBanner($sSession, combineUrl("web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char=" & $charName))
			secondWait(5)
			writeLogFile($logFile, "$errorIp: " & $errorIp)

			If $errorIp == $_WD_ERROR_Timeout Then
				; Thuc hien set lai vao file de khong thuc hien rs nua
				findAndClick($sSession, "//button[@type='submit']")
				findAndClick($sSession, "//button[@class='swal2-confirm swal2-styled']")
				writeLogFile($logFile, "IP khong chinh chu khong the RS")
			Else
				; thuc hien nhap captcha va submit
				solveImageCaptchaAz($sSession,"//img[@class='captcha_img']", 90, 5)
				checkCaptchaThenSubmit($sSession)
				findAndClick($sSession, "//button[@class='swal2-confirm swal2-styled']")
				writeLogFile($logFile, "Rut reset thanh cong !")
				; Thực hiện thay đổi nhân vật nếu reset_online = false, nếu reset_online = true thì không cần thực hiện thay đổi nhân vật mà sẽ thực hiện reset online luôn
				If Not $resetOnline Then
					writeLogFile($logFile, "Thuc hien thay đổi nhân vật sau khi withdraw reset !")
					changeThenReturnChar($charName)
					; Thuc hien switch sang main neu is_main_character = false
					If Not $isMainCharacter Then
						writeLogFile($logFile, "Thuc hien switch sang main character sau khi withdraw reset !")
						switchToMainCharItem($charName, $mainCharName)
					EndIf
				EndIf
				$jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
				For $i = 0 To UBound($jsonRsGame) - 1
					$charNameTmp = getPropertyJson($jsonRsGame[$i], "char_name")
					If $charNameTmp == $charName Then
						$sLogReset = getLogReset($sSession, $charName)
						$resetInDay = getRsInDay($sLogReset)
					Local $jItem = $jsonRsGame[$i]
					_JSONSet($resetInDay, $jItem, "time_rs")
					; last time rs
					$sTimeReset = getTimeReset($sLogReset, 0)
					_JSONSet($sTimeReset, $jItem, "last_time_reset")
					$jsonRsGame[$i] = $jItem
					setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
					EndIf
				Next
			EndIf
		EndIf
	Else
		writeLogFile($logFile, "Dang nhap that bai voi account: " & $charName)
		Return False
	EndIf
	writeLogMethodEnd("processWithDrawReset", @ScriptLineNumber, $jAccountInfo)
EndFunc   ;==>withDrawRs

Func extractAccountInfo($jAccountInfo)
	Local $oAccountInfo = ObjCreate("Scripting.Dictionary")

	$oAccountInfo.Item("username") = getPropertyJson($jAccountInfo, "user_name")
	$oAccountInfo.Item("password") = getPropertyJson($jAccountInfo, "password")
	$oAccountInfo.Item("charName") = getPropertyJson($jAccountInfo, "char_name")
	$oAccountInfo.Item("typeRs") = getPropertyJson($jAccountInfo, "type_rs")
	$oAccountInfo.Item("lvlMove") = getPropertyJson($jAccountInfo, "lvl_move")
	$oAccountInfo.Item("hourPerRs") = getPropertyJson($jAccountInfo, "hour_per_reset")
	$oAccountInfo.Item("resetOnline") = getPropertyJson($jAccountInfo, "reset_online")
	$oAccountInfo.Item("isBuff") = getPropertyJson($jAccountInfo, "is_buff")
	$oAccountInfo.Item("isMainCharacter") = getPropertyJson($jAccountInfo, "is_main_character")
	$oAccountInfo.Item("mainCharName") = getPropertyJson($jAccountInfo, "main_char_name")
	$oAccountInfo.Item("positionLeader") = getPropertyJson($jAccountInfo, "position_leader")
	$oAccountInfo.Item("serverNumber") = getPropertyJson($jAccountInfo, "server_number")
	$oAccountInfo.Item("isTrainInGame") = getPropertyJson($jAccountInfo, "train_in_game")
	$oAccountInfo.Item("onAutoPlus") = getPropertyJson($jAccountInfo, "on_auto_plus")
	$oAccountInfo.Item("switchServer") = getPropertyJson($jAccountInfo, "swith_server")
	$oAccountInfo.Item("time_in_night") = getPropertyJson($jAccountInfo, "time_in_night")
	$oAccountInfo.Item("time_rs") = getPropertyJson($jAccountInfo, "time_rs")
	$oAccountInfo.Item("rs") = getPropertyJson($jAccountInfo, "rs")
	$oAccountInfo.Item("max_rs") = getPropertyJson($jAccountInfo, "max_rs")
	$oAccountInfo.Item("postionMoveX") = getPropertyJson($jAccountInfo, "postion_move_x")
	$oAccountInfo.Item("postionMoveY") = getPropertyJson($jAccountInfo, "postion_move_y")

	Return $oAccountInfo
EndFunc   ;==>extractAccountInfo

Func updateResetTimeIfNotReached($jAccountInfo, $lastTimeRs, $nextTimeRs, $charName)
	writeLogFile($logFile, "Chua den thoi gian reset.")
	writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
	updateLastTimeRs($charName, $lastTimeRs)
EndFunc   ;==>updateResetTimeIfNotReached

Func calculateRequiredLevelForReset($rsCount)
	$lvlCanRs = 400
	If $rsCount < 50 Then
		$lvlCanRs = 200 + ($rsCount * 5)
		If $lvlCanRs > 400 Then $lvlCanRs = 400
	EndIf
	Return $lvlCanRs
EndFunc   ;==>calculateRequiredLevelForReset

; Method: _ProcessRs_PrepareGameBeforeReset
; Description: Chuan bi game truoc khi reset (active cua so, xu ly thong bao, doi server)
Func _ProcessRs_PrepareGameBeforeReset($resetOnline, $mainNo, $charName)
	If Not $resetOnline Then
		$activeWin = activeAndMoveWin($mainNo)
		If Not $activeWin Then $activeWin = switchOtherChar($charName)
		If $activeWin Then
			handleBeforeReset()
			changeServer($mainNo)
		EndIf
	Else
		writeLogFile($logFile, "Kiem tra Auto Z tren web truoc khi reset ! => Bo o phien ban nay")
	EndIf
EndFunc   ;==>_ProcessRs_PrepareGameBeforeReset

; Method: _ProcessRs_UpdateAccountInfo
; Description: Cap nhat thong tin reset vao file JSON config sau khi reset. Tra ve so lan reset trong ngay
Func _ProcessRs_UpdateAccountInfo($sSession, $charName, $rsCount, $isBuff)
	$jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
	Local $resetInDay = 0
	For $i = 0 To UBound($jsonRsGame) - 1
		$charNameTmp = getPropertyJson($jsonRsGame[$i], "char_name")
		If $charNameTmp == $charName Then
			$sLogReset = getLogReset($sSession, $charName)
			$resetInDay = getRsInDay($sLogReset)
			$currentRs = getCurrentReset($sLogReset)
			$currentLvl = getCurrentlvl($sLogReset)
			Local $jItem = $jsonRsGame[$i]
			_JSONSet($currentRs, $jItem, "rs")
			_JSONSet($resetInDay, $jItem, "time_rs")
			$sTimeReset = getTimeReset($sLogReset, 0)
			If $sTimeReset = 0 Or $currentLvl <> 1 Or $currentRs == $rsCount Then
				$sTimeReset = getTimeNow()
				writeLogFile($logFile, "Khong tim thay last time reset, set thanh thoi gian hien tai: " & $sTimeReset)
			EndIf
			_JSONSet($sTimeReset, $jItem, "last_time_reset")
			$jsonRsGame[$i] = $jItem
			setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
			If $resetInDay == 1 And $isBuff Then goPageBuffChar($sSession)
		EndIf
	Next
	Return $resetInDay
EndFunc   ;==>_ProcessRs_UpdateAccountInfo

; Method: _ProcessRs_ReturnGameAfterReset
; Description: Quay lai game sau khi reset va xu ly cac buoc tiep theo (chon server, chon nhan vat, train)
Func _ProcessRs_ReturnGameAfterReset($sSession, $oAccountInfo, $mainNo, $rsCount, $resetInDay)
	$serverNumber = $oAccountInfo.Item("serverNumber")
	returnServer($serverNumber)
	returnChar($mainNo)
	If Not $oAccountInfo.Item("isTrainInGame") Then
		processResetNomal($sSession, $oAccountInfo, $rsCount, $resetInDay)
	Else
		writeLogFile($logFile, "Xu ly doi voi truong hop can train in game ! Thuc hien active train in game !")
		activeTrainInGame($oAccountInfo)
	EndIf
	minisizeMain($mainNo)
EndFunc   ;==>_ProcessRs_ReturnGameAfterReset

; Method: _ProcessRs_HandleNotEnoughLevel
; Description: Xu ly truong hop chua du level de reset
Func _ProcessRs_HandleNotEnoughLevel($oAccountInfo, $nLvl, $lvlCanRs, $rsCount, $charName, $resetOnline)
	writeLogFile($logFile, "Lvl hien tai: " & $nLvl & " - Lvl can de reset: " & $lvlCanRs)
	If Not $resetOnline Then
		If $oAccountInfo.Item("isTrainInGame") Then
			writeLogFile($logFile, "Van dang thuc hien train in game ! Ket thuc xu ly reset !")
		Else
			actionNextResetNotEnoughLevel($oAccountInfo, $rsCount, $lvlCanRs)
		EndIf
	EndIf
	writeLogFile($logFile, "Chua du lvl de reset => Ket thuc xu ly reset !")
	updateLastTimeRs($charName, getTimeNow())
EndFunc   ;==>_ProcessRs_HandleNotEnoughLevel

; Method: _ProcessRs_CheckTimeToReset
; Description: Kiem tra thoi gian co the reset sau khi login. Tra ve True neu co the reset, False neu chua den thoi gian
Func _ProcessRs_CheckTimeToReset($jAccountInfo, $checkTimeInNight, $timeNow, $lastTimeRs, $nextTimeRs, $charName)
	If $checkTimeInNight Then
		writeLogFile($logFile, "Dang o trong khoang thoi gian dem => Bo qua viec kiem tra thoi gian reset !")
		Return True
	EndIf
	writeLogFile($logFile, "Khong o trong khoang thoi gian dem => Tiep tuc kiem tra thoi gian reset ! Thoi gian hien tai: " & $timeNow & " - Thoi gian co the reset: " & $nextTimeRs)
	If ($timeNow < $nextTimeRs) Then
		updateResetTimeIfNotReached($jAccountInfo, $lastTimeRs, $nextTimeRs, $charName)
		Return False
	EndIf
	Return True
EndFunc   ;==>_ProcessRs_CheckTimeToReset

Func processReset($jAccountInfo)
	writeLogMethodStart("processReset", @ScriptLineNumber, $jAccountInfo)
	Local $oAccountInfo = extractAccountInfo($jAccountInfo)
	$charName = $oAccountInfo.Item("charName")
	$resetOnline = $oAccountInfo.Item("resetOnline")
	$timeInNight = $oAccountInfo.Item("time_in_night")
	$timeRs = $oAccountInfo.Item("time_rs")

	writeLogFile($logFile, "Begin handle process reset with account: " & $charName)
	$checkTimeInNight = checkTimeInNight($timeRs, $timeInNight)
	$isLoginSuccess = login($sSession, $oAccountInfo.Item("username"), $oAccountInfo.Item("password"))
	If $isLoginSuccess Then
		$timeNow = getTimeNow()
		$sLogReset = getLogReset($sSession, $oAccountInfo.Item("charName"))
		$lastTimeRs = getTimeReset($sLogReset, 0)
		$rsCount = getRsCount($sLogReset)
		$nLvl = getCurrentlvl($sLogReset)
		$nextTimeRs = addTimePerRs($lastTimeRs, Number($oAccountInfo.Item("hourPerRs")))

		If Not _ProcessRs_CheckTimeToReset($jAccountInfo, $checkTimeInNight, $timeNow, $lastTimeRs, $nextTimeRs, $charName) Then Return

		$lvlCanRs = calculateRequiredLevelForReset($rsCount)
		writeLogFile($logFile, @ScriptLineNumber & " : Rs hien tai: " & $rsCount & " - Lvl can thiet de RS la: " & $lvlCanRs)
		$mainNo = getMainNoByChar($charName)

		If $nLvl >= $lvlCanRs Then
			_ProcessRs_PrepareGameBeforeReset($resetOnline, $mainNo, $charName)
			resetInWeb($sSession, $oAccountInfo)
			$resetInDay = _ProcessRs_UpdateAccountInfo($sSession, $charName, $rsCount, $oAccountInfo.Item("isBuff"))
			If Not $resetOnline Then _ProcessRs_ReturnGameAfterReset($sSession, $oAccountInfo, $mainNo, $rsCount, $resetInDay)
		Else
			_ProcessRs_HandleNotEnoughLevel($oAccountInfo, $nLvl, $lvlCanRs, $rsCount, $charName, $resetOnline)
		EndIf

		If Not $resetOnline Then minisizeMain($mainNo)
	EndIf
	writeLogMethodEnd("processReset", @ScriptLineNumber, $jAccountInfo)
EndFunc   ;==>processReset

Func isMovableUnderLevel20($sSession, $charName, $lvlCheckInWeb, $rsCount, $lvlStopCheck)
	; 5.1 Truong hop ma khong thay tang lvl thi thuc hien di chuyen bang web
	If $lvlCheckInWeb < 20 Then
		writeLogFile($logFile, "Khong thay tang lvl! Lvl hien tai: " & $lvlCheckInWeb)
		writeLogFile($logFile, "Thuc hien chuyen map bang web !")
		$moveLorenX = 220
		$moveLorenY = 144
		moveToPostionInWeb($sSession, $charName, $moveLorenX, $moveLorenY)
		writeLogFile($logFile, "Da thuc hien move truoc khi reset den toa do X: " & $moveLorenX & " - Y: " & $moveLorenY)
		; Doi 50s
		minuteWait(2)
		; Thuc hien check lai lvl
		$lvlCheckInWeb = checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
	Else
		writeLogFile($logFile, "Lvl van tang theo dung quy trinh! Lvl hien tai: " & $lvlCheckInWeb)
	EndIf
EndFunc   ;==>isMovableUnderLevel20

#cs
	Tim sport de luyen lvl len 20
#ce
Func goToSportLvl1()
	; Khi bat dau se xuat hien tai 182 - 128
	writeLogFile($logFile, "Bat dau tim vi tri sport 1")
	; 533, 338
	_MU_MouseClick_Delay(getProperty("button.loren_sport1.x"), getProperty("button.loren_sport1.y"))
	secondWait(1)
EndFunc   ;==>goToSportLvl1

Func checkLvlInWeb($rsCount, $charName, $lvlStopCheck, $timeDelay)
	writeLogFile($logFile, "Bat dau check lvl tren web !" & " - Lvl stop check: " & $lvlStopCheck)
	; Vào nhân vật kiểm tra lvl
	navigateUrl($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
	$mainNo = getMainNoByChar($charName)

	; find lvl
	$sElement = findElement($sSession, "//span[@class='t-level']")
	$nLvl = Number(getTextElement($sSession, $sElement))
	$tmpLvl = 0
	$timeCheck = 0
	$timeCheckMax = 68
	If $lvlStopCheck == 20 Then $timeCheckMax = 8

	While ($nLvl < $lvlStopCheck) And ($timeCheck <= $timeCheckMax)
		; Neu > 200 thi moi thuc hien ghi log
		If ($nLvl > 200 Or $timeCheck > 10) Then writeLogFile($logFile, "Lvl hien tai: " & $nLvl & "- So lan da check: " & $timeCheck)

		$timeCheck += 1
		If $nLvl <> $tmpLvl Or $nLvl < 20 Then
			$tmpLvl = $nLvl
		Else
			; Truong hop lvl khong thay doi thi thuc hien move den stadium
			writeLogFile($logFile, "Lvl khong thay doi gi goMapArena. $nLvl = " & $nLvl & " - $tmpLvl = " & $tmpLvl)

			If activeAndMoveWin($mainNo) Then
				If Not checkActiveAutoHome() Then
					writeLogFile($logFile, "Auto Home not active !")
					goMapArena($rsCount)
				Else
					; Truong hop lvl < 100 thi van vao map arena
					If $nLvl < 120 Then
						writeLogFile($logFile, "Auto Home active ! LVL < 120 vao map arena")
						goMapArena($rsCount)
					Else
						writeLogFile($logFile, "Auto Home active ! Khong can lam gi nua")
					EndIf
				EndIf
			Else
				writeLogFile($logFile, "Main khong active ! Thuc hien swith main khac")
				switchOtherChar($charName)
			EndIf

		EndIf
		minisizeMain($mainNo)
		; Xu ly doi voi lvl check = 20; chi can doi 30s
		If $lvlStopCheck == 20 Then
			; Wait 30 sec then retry
			secondWait(30)
		Else
			; Wait 1 min then retry
			minuteWait($timeDelay)
		EndIf

		navigateUrl($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
		; find lvl
		$sElement = findElement($sSession, "//span[@class='t-level']")
		$tLvl = getTextElement($sSession, $sElement)
		$nLvl = Number($tLvl)

		; Truong hop $lvlStopCheck= 20 va so lan check ma = 10 thi thuc hien move = web
		If ($timeCheck == 10 Or $timeCheck == 20) And $lvlStopCheck == 20 Then
			writeLogFile($logFile, "So lan check = 10, thuc hien move = web")
			; Dien toa do X - vi tri cua sport 1
			;174, 65
			$positionX = 174
			$positionY = 65
			moveToPostionInWeb($sSession, $charName, $positionX, $positionY)
		EndIf
	WEnd

	writeLogFile($logFile, "Ket thuc check lvl tren web ! Lvl hien tai: " & $nLvl)

	Return $nLvl
EndFunc

Func checkLvl400WhenRs($rsCount, $charName, $timeDelay)
	$lvlStopCheck = 400
	$nLvl = 25
	writeLogFile($logFile, "Bat dau check lvl tren web !" & " - Lvl stop check: " & $lvlStopCheck)
	; Vào nhân vật kiểm tra lvl
	$mainNo = getMainNoByChar($charName)
	$nLvl = 25
	$tmpLvl = 0
	$timeCheck = 0
	$timeCheckMax = 30
	;~ If $lvlStopCheck == 20 Then $timeCheckMax = 8

	While ($nLvl < $lvlStopCheck) And ($timeCheck <= $timeCheckMax)
		; Neu > $timeCheck >10 thi moi thuc hien ghi log
		If ($timeCheck > 10) Then writeLogFile($logFile, "Lvl hien tai: " & $nLvl & "- So lan da check: " & $timeCheck)
		$timeCheck += 1
		If Not activeAndMoveWin($mainNo) Then 
			writeLogFile($logFile, "Main khong active ! Thuc hien swith main khac")
			switchOtherChar($charName)
		EndIf

		If activeAndMoveWin($mainNo) Then
			If check400LvlImage() Then
				writeLogFile($logFile, "Tim thay lvl 400 => Ket thuc check lvl !")
				$nLvl = 400
			Else
				writeLogFile($logFile, "Khong tim thay lvl 400 => Tiep tuc check lvl !")
				If Not checkActiveAutoHome() Then
					writeLogFile($logFile, "Auto Home not active !")
					; Send key enter de vao map arena
					sendEnterThenClickCenter()
					; Go map arena
					goMapArena($rsCount)
				EndIf
				minisizeMain($mainNo)
				minuteWait($timeDelay)
			EndIf
		EndIf
	WEnd

	writeLogFile($logFile, "Ket thuc check lvl tren web ! Lvl hien tai: " & $nLvl)

	Return $nLvl
EndFunc   ;==>checkLvlInWeb

; Method: _ValidRs_IsInvalidLastTime
; Description: Kiem tra thoi gian reset co hop le khong. Tra ve True neu khong hop le (can bo qua)
Func _ValidRs_IsInvalidLastTime($jAccount)
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $charName = getPropertyJson($jAccount, "char_name")
	If $lastTimeRs == 0 Or StringLen($lastTimeRs) == 1 Then
		writeLogFile($logFile, "Loi Thoi gian reset khong hop le !")
		updateLastTimeRs($charName, getTimeNow())
		Return True
	EndIf
	Return False
EndFunc   ;==>_ValidRs_IsInvalidLastTime

; Method: _ValidRs_IsNotTimeToReset
; Description: Kiem tra da den gio reset chua. Tra ve True neu chua den gio (can bo qua)
Func _ValidRs_IsNotTimeToReset($jAccount)
	Local $timeRs = getPropertyJson($jAccount, "time_rs")
	Local $timeInNight = getPropertyJson($jAccount, "time_in_night")
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $hourPerRs = getPropertyJson($jAccount, "hour_per_reset")
	Local $checkTimeInNight = checkTimeInNight($timeRs, $timeInNight)
	Local $currentTime = getTimeNow()
	Local $nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))

	If $checkTimeInNight Then
		writeLogFile($logFile, "Dang o trong khoang thoi gian dem => Bo qua viec kiem tra thoi gian reset !")
		Return False
	EndIf
	writeLogFile($logFile, "Khong o trong khoang thoi gian dem => Tiep tuc kiem tra thoi gian reset ! Thoi gian hien tai: " & $currentTime & " - Thoi gian co the reset: " & $nextTimeRs)
	If $currentTime < $nextTimeRs Then
		writeLogFile($logFile, "Chua den thoi gian reset. " & @CRLF & "Thoi gian gan nhat co the reset: " & $nextTimeRs)
		Return True
	EndIf
	Return False
EndFunc   ;==>_ValidRs_IsNotTimeToReset

; Method: _ValidRs_IsMaxResetReached
; Description: Kiem tra da dat so reset toi da chua (>= 2000 hoac >= max_rs). Tra ve True neu da dat (can bo qua)
Func _ValidRs_IsMaxResetReached($jAccount)
	Local $rs = getPropertyJson($jAccount, "rs")
	Local $max_rs = getPropertyJson($jAccount, "max_rs")
	If $rs >= 2000 Then
		writeLogFile($logFile, "Da dat so lan reset toi da: " & $rs & " => Khong duoc reset nua!")
		Return True
	EndIf
	If $rs >= $max_rs Then
		writeLogFile($logFile, "So lan rs da vuot qua: " & $max_rs & " => Khong duoc reset nua!")
		Return True
	EndIf
	Return False
EndFunc   ;==>_ValidRs_IsMaxResetReached

; Method: _ValidRs_IsTypeRsTimeNotReached
; Description: Kiem tra dieu kien thoi gian theo type RS (Zen=0 / VIP=1 / PO=2). Tra ve True neu chua du thoi gian (can bo qua)
Func _ValidRs_IsTypeRsTimeNotReached($jAccount, $timeWaitRsVip, $timeWaitRsZenRs50)
	Local $typeRs = getPropertyJson($jAccount, "type_rs")
	Local $rs = getPropertyJson($jAccount, "rs")
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $currentTime = getTimeNow()
	Local $lastTimeRsAdd30 = _DateAdd('n', 30, $lastTimeRs)
	Local $lastTimeRsAdd60 = _DateAdd('n', 60, $lastTimeRs)
	Local $lastTimeRsAddRsVip = _DateAdd('n', $timeWaitRsVip, $lastTimeRs)
	Local $lastTimeRsAddRsZenRs50 = _DateAdd('n', $timeWaitRsZenRs50, $lastTimeRs)

	If $typeRs == 0 Then
		If $currentTime < $lastTimeRsAdd30 And $rs >= 50 Then
			writeLogFile($logFile, "Chua toi thoi gian duoc rs voi type Zen: " & $typeRs & @CRLF & " - Thoi gian gan nhat co the reset voi type zen: " & $lastTimeRsAdd30)
			Return True
		ElseIf ($currentTime < $lastTimeRsAddRsZenRs50) And ($rs < 50) Then
			writeLogFile($logFile, "Rs < 50 - Chua toi thoi gian duoc rs voi type Zen: " & $typeRs & @CRLF & " - Thoi gian gan nhat co the reset voi type zen: " & $lastTimeRsAddRsZenRs50)
			Return True
		Else
			writeLogFile($logFile, "Tiep tuc kiem tra reset voi type Zen: " & $typeRs)
		EndIf
	EndIf
	If $typeRs == 1 And $currentTime < $lastTimeRsAddRsVip Then
		writeLogFile($logFile, "Chua toi thoi gian duoc rs voi type VIP: " & $typeRs & @CRLF & " - Thoi gian gan nhat co the reset voi type PO: " & $lastTimeRsAddRsVip)
		Return True
	EndIf
	If $typeRs == 2 And $currentTime < $lastTimeRsAdd60 Then
		writeLogFile($logFile, "Chua toi thoi gian duoc rs voi type PO: " & $typeRs & @CRLF & " - Thoi gian gan nhat co the reset voi type PO: " & $lastTimeRsAdd60)
		Return True
	EndIf
	Return False
EndFunc   ;==>_ValidRs_IsTypeRsTimeNotReached

; Method: _ValidRs_IsDailyLimitExceeded
; Description: Kiem tra da vuot qua so lan reset duoc phep trong ngay chua. Tra ve True neu da vuot (can bo qua)
Func _ValidRs_IsDailyLimitExceeded($jAccount)
	Local $timeRs = getPropertyJson($jAccount, "time_rs")
	Local $limit = getPropertyJson($jAccount, "limit")
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $sDateCheck = @YEAR & "/" & @MON & "/" & @MDAY
	If $timeRs >= $limit And StringLeft($lastTimeRs, 10) == $sDateCheck Then
		writeLogFile($logFile, "Vuot qua so lan rs duoc phep trong ngay: " & $timeRs & @CRLF & " - So lan duoc phep: " & $limit)
		Return True
	EndIf
	writeLogFile($logFile, "Time limit = " & $limit & " - Time rs = " & $timeRs & " - Last time rs = " & $lastTimeRs & "Date check = " & $sDateCheck)
	Return False
EndFunc   ;==>_ValidRs_IsDailyLimitExceeded

; Method: _ValidRs_AdjustTypeRsIfOverDailyLimit
; Description: Neu vuot qua gioi han RS VIP/PO trong ngay va hourPerRs = 0 thi chuyen type_rs ve 0 (Zen)
Func _ValidRs_AdjustTypeRsIfOverDailyLimit(ByRef $jAccount, $maxRsVip, $maxRsPo)
	Local $typeRs = getPropertyJson($jAccount, "type_rs")
	Local $timeRs = getPropertyJson($jAccount, "time_rs")
	Local $hourPerRs = getPropertyJson($jAccount, "hour_per_reset")
	Local $rs = getPropertyJson($jAccount, "rs")
	If (($typeRs == 1 And $timeRs > $maxRsVip) Or ($typeRs == 2 And $timeRs > $maxRsPo)) And ($hourPerRs == 0) Then
		writeLogFile($logFile, "Vuot qua so lan rs duoc phep trong ngay voi type rs: " & $typeRs & " va so lan rs: " & $rs & " => Thay doi type rs ve 0 (RS zen) va reset time rs ve 0")
		$typeRs = 0
		_JSONSet($typeRs, $jAccount, "type_rs")
		writeLogFile($logFile, "Thong tin tai khoan sau khi thay doi type rs: " & convertJsonToString($jAccount))
	EndIf
EndFunc   ;==>_ValidRs_AdjustTypeRsIfOverDailyLimit

Func validAccountRs($aAccountActiveRs)
	writeLogMethodStart("validAccountRs", @ScriptLineNumber, $aAccountActiveRs)
	Local $aAccValidate[0]
	$timeWaitRsVip = _JSONGet($jsonPositionConfig, "common.auto.time_wait_rs_vip")
	$timeWaitRsZenRs50 = _JSONGet($jsonPositionConfig, "common.auto.time_wait_rs_zen_rs_50")
	$maxRsVip = _JSONGet($jsonPositionConfig, "common.auto.max_rs_vip")
	$maxRsPo = _JSONGet($jsonPositionConfig, "common.auto.max_rs_po")
	; Them gia tri mac dinh neu khong co trong file config
	If $timeWaitRsVip == "" Then $timeWaitRsVip = 20
	If $timeWaitRsZenRs50 == "" Then $timeWaitRsZenRs50 = 30
	If $maxRsVip == "" Then $maxRsVip = 10
	If $maxRsPo == "" Then $maxRsPo = 10

	; Validate account reset
	For $i = 0 To UBound($aAccountActiveRs) - 1
		$username = getPropertyJson($aAccountActiveRs[$i], "user_name")
		$charName = getPropertyJson($aAccountActiveRs[$i], "char_name")
		writeLogFile($logFile, "validAccountRs => " & $username & " - " & $charName)

		If _ValidRs_IsInvalidLastTime($aAccountActiveRs[$i]) Then ContinueLoop
		If _ValidRs_IsNotTimeToReset($aAccountActiveRs[$i]) Then ContinueLoop
		If _ValidRs_IsMaxResetReached($aAccountActiveRs[$i]) Then ContinueLoop
		If _ValidRs_IsTypeRsTimeNotReached($aAccountActiveRs[$i], $timeWaitRsVip, $timeWaitRsZenRs50) Then ContinueLoop
		If _ValidRs_IsDailyLimitExceeded($aAccountActiveRs[$i]) Then ContinueLoop
		_ValidRs_AdjustTypeRsIfOverDailyLimit($aAccountActiveRs[$i], $maxRsVip, $maxRsPo)

		ReDim $aAccValidate[UBound($aAccValidate) + 1]
		$aAccValidate[UBound($aAccValidate) - 1] = $aAccountActiveRs[$i]
	Next

	Return $aAccValidate
EndFunc   ;==>validAccountRs

Func firstActionAfterRs()
	; Thuc hien send key home
	sendKeyHome()
	; Send tiep key tab de mo ban do
	sendKeyTab()
	; 4. Go to sport
	goToSportLvl1()
	; Send 1 lan key tab nua de tat ban do
	sendKeyTab()
EndFunc   ;==>firstActionAfterRs

Func processResetNomal($sSession, $oAccountInfo, $rsCount, $resetInDay)
	writeLogMethodStart("processResetNomal", @ScriptLineNumber)
	$charName = $oAccountInfo.Item("charName")
	$mainNo = getMainNoByChar($charName)
	$trainInGame = $oAccountInfo.Item("isTrainInGame")
	; 3.1. Check xem cua so enter co ton tai khong
	firstActionAfterRs()
	minisizeMain($mainNo)
	; 5. Doi 2phut de cho len lvl > 20
	minuteWait(1)

	; 6. Active main
	activeAndMoveWin($mainNo)
	; 7. Go map lvl
	If $resetInDay <= 3 Then
		writeLogFile($logFile, "So lan rs trong ngay: " & $resetInDay)
		goMapLvl()
	Else
		goMapArena($rsCount)
	EndIf

	; 8. Check lvl 400 trong game
	checkLvl400WhenRs($rsCount, $charName, 2)
	
	; Thuc hien chuyen map neu khong tim thay lvl 400
	moveOtherMap($charName)

	; 9. Follow leader
	$positionLeader = $oAccountInfo.Item("positionLeader")
	If Not IsNumber($positionLeader) Then $positionLeader = 1

	_MU_followLeader($positionLeader)

	; Truong hop can train in game thi thực hiện active button train in game
	If $oAccountInfo.Item("onAutoPlus") Then 
		startAutoPlus()
		secondWait(1)
		If $oAccountInfo.Item("switchServer") Then switchSvInGame($oAccountInfo)
	EndIf

	; 10. Truong hop khong phai la main_char moi can phai doi 1 phut de di chuyen
	If Not $oAccountInfo.Item("isMainCharacter") Then 
		minuteWait(1)
		handleIsNotMainChar($oAccountInfo)
	EndIf

	writeLogMethodEnd("processResetNomal", @ScriptLineNumber)
EndFunc

Func activeTrainInGame($oAccountInfo)
	; Dau tien kiem tra xem auto_plus da duoc active chua, neu chua thi mới thuc hien active auto_plus
	;~ $checkAutoPlus = checkActiveAutoHomePlus()
	;~ If Not $checkAutoPlus Then
	;~ 	writeLogFile($logFile, "Auto Home Plus chua duoc active ! Thuc hien active Auto Home Plus !")
	;~ 	startAutoPlus()
	;~ Else
	;~ 	writeLogFile($logFile, "Auto Home Plus da duoc active ! Tiep tuc xu ly train in game !")
	;~ EndIf
	; Thuc hien stop auto home plus truoc da
	stopAutoPlus()
	secondWait(2)
	; Thien hien active auto home plus
	startAutoPlus()
	secondWait(2)
	; 3. Thuc hien doi server trong game nhe
	switchSvInGame($oAccountInfo)

	Return True
EndFunc

; Xu ly khi lan tiep theo reset nhung khong du lvl de reset va reset online = false
Func actionNextResetNotEnoughLevel($oAccountInfo, $rsCount, $lvlStopCheck)
	$charName = $oAccountInfo.Item("charName")
	$resetOnline = $oAccountInfo.Item("resetOnline")
	$mainNo = getMainNoByChar($charName)
	$mainNoMinisize = $mainNo
	$timeCheck = 0
	writeLogFile($logFile, "Van chua du lvl de reset ! Thuc hien tiep viec reset theo quy trinh !")
	$activeWin = activeAndMoveWin($mainNo)
	If Not $activeWin Then $activeWin = switchOtherChar($charName)
	; Click bỏ hết các bảng thông báo
	If $activeWin Then
		sendKeyEnter()
		sendKeyEnter()
		goMapArena($rsCount)
		minuteWait(1)
		$lvlCheckInWeb = checkLvl400WhenRs($rsCount, $charName, 1)
		While $lvlCheckInWeb < $lvlStopCheck And $timeCheck <= 5
			writeLogFile($logFile, "Lvl tren web: " & $lvlCheckInWeb & " - Lvl stop check: " & $lvlStopCheck)
			$lvlCheckInWeb = checkLvl400WhenRs($rsCount, $charName, 1)
			$timeCheck += 1
			minuteWait(1)
		WEnd

		If $lvlCheckInWeb < $lvlStopCheck Then
			writeLogFile($logFile, "Khong du lvl de reset ! Thuc hien chuyen map ! Follow leader !")
			moveOtherMap($charName)
		Else
			writeLogFile($logFile, "Du lvl de reset ! Follow leader !")
		EndIf

		activeAndMoveWin($mainNo)
		_MU_followLeader(1)

		If Not $resetOnline Then
			; 10. minisize main
			minisizeMain($mainNoMinisize)
		EndIf

		; 11. Logout account
		logout($sSession)
	Else
		writeLogFile($logFile, "Main khong active ! Ket thuc xu ly !")
	EndIf
	Return True
EndFunc   ;==>actionNextResetNotEnoughLevel

#include-once
#include <Array.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"
#include "../../utils/game_utils.au3"
#RequireAdmin

$className = "auto_rs_v2.au3"

; Ma loi khi reset khong thanh cong (tra ve qua @error cua processResetV2)
Global Const $RS_ERR_NOT_ENOUGH_LVL = 1
Global Const $RS_ERR_WEB_RESET_FAILED = 2
Global Const $RS_ERR_LOGIN_FAILED = 3
Global Const $RS_ERR_NOT_TIME_YET = 4
Global Const $RS_ERR_ACTIVE_GAME_FAILED = 5
Global Const $RS_ERR_CHANGE_CHAR_FAILED = 6

;~ startAutoRsV2()
start()

Func start()
	writeLogMethodStart("start", @ScriptLineNumber)
	While True
		If Not checkProcessExists("mu_auction.exe") And ((@HOUR < 23) Or (@HOUR == 23 And @MIN <= 20)) Then
			startAutoRsV2()
			;~ startAutoBuff()
		EndIf

		Local $waitMinutes = calculateWaitMinutesV2()
		If $waitMinutes > 0 Then
			minuteWait($waitMinutes)
		Else
			Local $timeLoop = _JSONGet($jsonPositionConfig, "common.auto.time_loop_auto_rs")
			writeLog("Time loop for auto reset v2: " & $timeLoop)
			If (Number($timeLoop) = 0 Or Number($timeLoop) == 60) Then
				waitToNextHourMinutes(1, 07, 00)
			Else
				minuteWait($timeLoop)
			EndIf
		EndIf
	WEnd
EndFunc

; Method: calculateWaitMinutesV2
; Description: Tinh so phut cho dua tren next_reset (last_time_reset + hour_per_reset) som nhat
;              cua cac account active. Tra ve -1 khi khong co account de fallback ve time_loop.
Func calculateWaitMinutesV2()
	writeLogMethodStart("calculateWaitMinutesV2", @ScriptLineNumber)
	Local $jAccMerge = mergeInfoAccountRs()
	If UBound($jAccMerge) == 0 Then Return -1

	Local $timeNow = getTimeNow()
	Local $nMinWait = 0, $bFound = False

	For $i = 0 To UBound($jAccMerge) - 1
		Local $jAccount = _NormalizeAccountV2($jAccMerge[$i])
		Local $lastResetStatus = getPropertyJson($jAccount, "last_reset_status")
		If Not getPropertyJson($jAccount, "active") Then ContinueLoop
		If Not $lastResetStatus Then ContinueLoop

		Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
		Local $hourPerRs = Number(getPropertyJson($jAccount, "hour_per_reset"))
		Local $nextTimeRs = addTimePerRs($lastTimeRs, $hourPerRs)
		Local $minToNext = _DateDiff('n', $timeNow, $nextTimeRs)

		If Not $bFound Or $minToNext < $nMinWait Then
			$nMinWait = $minToNext
			$bFound = True
		EndIf
	Next

	If Not $bFound Then Return -1
	If $nMinWait < 5 Then $nMinWait = 5
	writeLog("Wait minutes tinh theo next_reset som nhat: " & $nMinWait)
	Return $nMinWait
EndFunc 

Func startAutoRsV2()
	Local $aResetAccounts[0], $aWithdrawAccounts[0], $aResetValidated[0], $aProcessAccounts[0]
	Local $sFilePath = $outputPathRoot & "File_Log_AutoRS_V2_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)

	writeLogMethodStart("startAutoRsV2", @ScriptLineNumber)
	writeLogFile($logFile, "Begin auto reset v2")

	Local $jAccMerge = mergeInfoAccountRs()
	If UBound($jAccMerge) == 0 Then
		writeLogFile($logFile, "Khong co account trong du lieu merge")
		FileClose($logFile)
		Return
	EndIf

	For $i = 0 To UBound($jAccMerge) - 1
		Local $jAccount = _NormalizeAccountV2($jAccMerge[$i])
		Local $active = getPropertyJson($jAccount, "active")
		If Not $active Then ContinueLoop

		Local $type = StringLower(String(getPropertyJson($jAccount, "type")))
		If $type == "withdraw" Then
			$aWithdrawAccounts = redimArray($aWithdrawAccounts, $jAccount)
		ElseIf $type == "reset" Then
			$aResetAccounts = redimArray($aResetAccounts, $jAccount)
		Else
			writeLogFile($logFile, "Bo qua type khong ho tro trong v2: " & $type)
		EndIf
	Next

	If UBound($aResetAccounts) > 0 Then
		$aResetValidated = validAccountRsV2($aResetAccounts)
	EndIf

	For $i = 0 To UBound($aResetValidated) - 1
		$aProcessAccounts = redimArray($aProcessAccounts, $aResetValidated[$i])
	Next
	For $i = 0 To UBound($aWithdrawAccounts) - 1
		$aProcessAccounts = redimArray($aProcessAccounts, $aWithdrawAccounts[$i])
	Next

	If UBound($aProcessAccounts) == 0 Then
		writeLogFile($logFile, "Khong co account nao du dieu kien xu ly")
		FileClose($logFile)
		Return
	EndIf

	$sSession = startChromeSession()
	If $sSession == "" Then
		writeLogFile($logFile, "Khong the khoi tao chrome session")
		FileClose($logFile)
		Return
	EndIf

	$aProcessAccounts = sortArrayByProperty($aProcessAccounts, "username", True)

	For $i = 0 To UBound($aProcessAccounts) - 1
		Local $jItem = $aProcessAccounts[$i]
		Local $type = StringLower(String(getPropertyJson($jItem, "type")))
		Local $charName = getPropertyJson($jItem, "char_name")
		writeLogFile($logFile, "Dang xu ly type=" & $type & " - char=" & $charName)

		If $type == "withdraw" Then
			withDrawRsV2($jItem)
		Else
			resetV2($jItem)
		EndIf

		Local $currentUser = getPropertyJson($jItem, "username")
		Local $nextUser = ""
		If $i + 1 < UBound($aProcessAccounts) Then
			$nextUser = getPropertyJson($aProcessAccounts[$i + 1], "username")
		EndIf
		If $currentUser <> $nextUser Then
			logout($sSession)
		EndIf
	Next

	writeLogMethodEnd("startAutoRsV2", @ScriptLineNumber)
	FileClose($logFile)
	closeChromeSession($sSession)
EndFunc

Func _NormalizeAccountV2($jAccount)
	writeLogMethodStart("_NormalizeAccountV2", @ScriptLineNumber)
	Local $username = getPropertyJson($jAccount, "username")
	If $username == "" Then $username = getPropertyJson($jAccount, "user_name")
	_JSONSet($username, $jAccount, "username")
	_JSONSet($username, $jAccount, "user_name")
	Local $typeRs = StringLower(String(getPropertyJson($jAccount, "type_rs")))
	If $typeRs == "1" Then $typeRs = "vip"
	If $typeRs == "0" Then $typeRs = "free"
	If $typeRs <> "vip" Then $typeRs = "free"
	_JSONSet($typeRs, $jAccount, "type_rs")

	If getPropertyJson($jAccount, "go_arena") == "" Then _JSONSet(False, $jAccount, "go_arena")
	If getPropertyJson($jAccount, "is_hide") == "" Then _JSONSet(False, $jAccount, "is_hide")
	If getPropertyJson($jAccount, "lvl_move") == "" Then _JSONSet(400, $jAccount, "lvl_move")
	If getPropertyJson($jAccount, "switch_other_main") == "" Then _JSONSet(False, $jAccount, "switch_other_main")
	If getPropertyJson($jAccount, "char_main_name") == "" Then _JSONSet("", $jAccount, "char_main_name")
	If getPropertyJson($jAccount, "hour_per_reset") == "" Then _JSONSet(1, $jAccount, "hour_per_reset")
	If getPropertyJson($jAccount, "max_hour_reset") == "" Then _JSONSet(24, $jAccount, "max_hour_reset")
	If getPropertyJson($jAccount, "time_rs") == "" Then _JSONSet(0, $jAccount, "time_rs")
	If getPropertyJson($jAccount, "limit") == "" Then _JSONSet(5, $jAccount, "limit")
	If getPropertyJson($jAccount, "arena_loop_count") == "" Then _JSONSet(5, $jAccount, "arena_loop_count")
	If getPropertyJson($jAccount, "last_time_reset") == "" Then _JSONSet(getTimeNow(), $jAccount, "last_time_reset")
	If getPropertyJson($jAccount, "rs") == "" Then _JSONSet(0, $jAccount, "rs")
	If getPropertyJson($jAccount, "max_rs") == "" Then _JSONSet(2000, $jAccount, "max_rs")
	If getPropertyJson($jAccount, "last_reset_status") == "" Then _JSONSet(True, $jAccount, "last_reset_status")

	Return $jAccount
EndFunc

Func resetV2($jAccountInfo)
	; B1: Lay thong tin co ban cua account reset
	Local $charName = getPropertyJson($jAccountInfo, "char_name")
	Local $resetOnline = getPropertyJson($jAccountInfo, "reset_online")
	Local $mainNo = getMainNoByChar($charName)

	writeLogMethodStart("resetV2", @ScriptLineNumber, $charName)
	; B2: Goi luong reset chinh va nhan ket qua + ma loi
	Local $isResetSuccess = processResetV2($jAccountInfo)
	Local $rsErrCode = @error
	Local $isCharChanged = @extended
	Local $needSwitchMainChar = ($rsErrCode = $RS_ERR_NOT_ENOUGH_LVL Or $rsErrCode = $RS_ERR_WEB_RESET_FAILED)
	If Not $isResetSuccess Then writeLogFile($logFile, "Reset khong thanh cong - ma loi: " & $rsErrCode & " - char: " & $charName)

	; B3: Xu ly nhanh cho case reset that bai (chi ap dung khi reset online = false)
	If Not $resetOnline And Not $isResetSuccess Then
		; B3.1: Neu da doi char truoc do thi tra lai char cu, dung auto plus tam thoi
		If $isCharChanged Then
			writeLogFile($logFile, "Reset khong thanh cong, thuc hien return char: " & $charName)
			returnChar($mainNo)
			stopAddPointStartAutoPlus()
			;~ sendKeyShiftF()
			secondWait(2)
		EndIf

		; B3.2: Chi thu switch sang main char voi nhom loi duoc chi dinh
		If $needSwitchMainChar And $jAccountInfo.Item("switchOtherMain") Then
			_TrySwitchToMainCharIfAutoHomeActive($charName, getPropertyJson($jAccountInfo, "charMainName"), getPropertyJson($jAccountInfo, "isHide"))
		EndIf

		; B3.3: Neu da can thiep vao flow game thi hide cua so theo config
		If $isCharChanged Or $needSwitchMainChar Then
			_HideMainIfNeededV2($mainNo, getPropertyJson($jAccountInfo, "is_hide"))
		EndIf
	EndIf
	writeLogMethodEnd("resetV2", @ScriptLineNumber, $charName)
EndFunc

Func processResetV2($jAccountInfo)
	; B1: Chuan hoa thong tin account
	Local $oAccountInfo = extractAccountInfoV2($jAccountInfo)
	Local $charName = $oAccountInfo.Item("charName")
	Local $resetOnline = $oAccountInfo.Item("resetOnline")
	Local $mainNo = getMainNoByChar($charName)
	Local $isCharChanged = 0

	writeLogMethodStart("processResetV2", @ScriptLineNumber, $charName)
	; B2: Dang nhap web
	If Not login($sSession, $oAccountInfo.Item("username"), $oAccountInfo.Item("password")) Then
		writeLogFile($logFile, "Dang nhap that bai: " & $charName)
		Return SetError($RS_ERR_LOGIN_FAILED, $isCharChanged, False)
	EndIf

	; B3: Lay log reset hien tai va tinh toan dieu kien reset
	Local $timeNow = getTimeNow()
	Local $sLogReset = getLogReset($sSession, $charName)
	Local $lastTimeRs = getTimeReset($sLogReset, 0)
	Local $rsCount = getRsCount($sLogReset)
	Local $nLvl = getCurrentlvl($sLogReset)
	Local $nextTimeRs = addTimePerRs($lastTimeRs, Number($oAccountInfo.Item("hourPerRs")))

	; B4: Check den gio reset chua
	If Not _CheckTimeToResetV2($timeNow, $lastTimeRs, $nextTimeRs, $charName) Then Return SetError($RS_ERR_NOT_TIME_YET, $isCharChanged, False)
	
	; B5: Check du level reset chua
	Local $lvlCanRs = calculateRequiredLevelForResetV2($rsCount)
	If $nLvl < $lvlCanRs Then
		writeLogFile($logFile, "Chua du level de reset. Lvl hien tai=" & $nLvl & " - lvl can=" & $lvlCanRs)
		updateLastTimeRs($charName, getTimeNow())
		_UpdateLastResetStatusV2($charName, False)
		Return SetError($RS_ERR_NOT_ENOUGH_LVL, $isCharChanged, False)
	EndIf

	; B6: Neu reset offline thi active cua so game + doi char truoc khi reset web
	If Not $resetOnline Then
		Local $activeMain = activeAndMoveWin($mainNo)
		If Not $activeMain Then $activeMain = switchOtherChar($charName)
		If Not $activeMain Then
			writeLogFile($logFile, "Khong active duoc cua so game de reset: " & $charName)
			Return SetError($RS_ERR_ACTIVE_GAME_FAILED, $isCharChanged, False)
		EndIf

		If Not changeChar($mainNo) Then
			writeLogFile($logFile, "Khong doi duoc nhan vat truoc reset: " & $charName)
			Return SetError($RS_ERR_CHANGE_CHAR_FAILED, $isCharChanged, False)
		EndIf
		$isCharChanged = 1
	EndIf

	; B7: Thuc hien reset tren web
	If Not resetInWeb($sSession, $oAccountInfo) Then
		writeLogFile($logFile, "Reset web that bai sau retry: " & $charName)
		_UpdateLastResetStatusV2($charName, False)
		Return SetError($RS_ERR_WEB_RESET_FAILED, $isCharChanged, False)
	EndIf
	; B8: Dong bo thong tin reset moi ve file json
	_ProcessRs_UpdateAccountInfoV2($charName)

	; B9: Hau xu ly phia game sau khi reset thanh cong
	If Not $resetOnline Then
		returnChar($mainNo)
        stopAddPointStartAutoPlus()
		minisizeMain($mainNo)

		Local $goArena = $oAccountInfo.Item("goArena")
		If $goArena Then
			processGoArenaV2($mainNo, $rsCount, Number($oAccountInfo.Item("arenaLoopCount")))
			moveOtherMap($charName)
			addPointStartAutoPlus()
		EndIf

		; B9.1: Neu dat nguong level va co bat switchOtherMain thi thu switch sang main char
		Local $sLogResetAfter = getLogReset($sSession, $charName)
		Local $currentLvl = getCurrentlvl($sLogResetAfter)
		Local $lvlMove = Number($oAccountInfo.Item("lvlMove"))
		writeLogFile($logFile, "Current level after reset: " & $currentLvl & " - Level to move: " & $lvlMove)
		writeLogFile($logFile, "Switch other main: " & $oAccountInfo.Item("switchOtherMain") & " - Char main name: " & $oAccountInfo.Item("charMainName"))
		If $currentLvl >= $lvlMove And $oAccountInfo.Item("switchOtherMain") Then
			_TrySwitchToMainCharIfAutoHomeActive($charName, $oAccountInfo.Item("charMainName"), $oAccountInfo.Item("isHide"))
		EndIf
		;~ sendKeyShiftF()
		secondWait(1)
		_HideMainIfNeededV2($mainNo, $oAccountInfo.Item("isHide"))
	EndIf

	; B10: Ket thuc thanh cong
	writeLogMethodEnd("processResetV2", @ScriptLineNumber, $charName)
	Return SetError(0, $isCharChanged, True)
EndFunc

Func _TrySwitchToMainCharIfAutoHomeActive($charName, $charMainName, $isHide, $maxAttempts = 2, $waitMinutes = 2)
	writeLogMethodStart("_TrySwitchToMainCharIfAutoHomeActive", @ScriptLineNumber, $charName)
	; B1: Neu main char da active san thi bo qua switch
	If activeAndMoveWinByChar($charMainName) Then
		writeLogFile($logFile, "Main char da active, bo qua switch: " & $charMainName)
		Return True
	EndIf

	; B2: Dam bao char hien tai dang duoc active de tiep tuc xu ly
	Local $isCharActive = activeAndMoveWinByChar($charName)
	If Not $isCharActive Then
		writeLogFile($logFile, "Khong active duoc char de xu ly switch main char cua: " & $charName)
		Return False
	EndIf

	; B3: Retry check auto home trong so lan gioi han
	Local $attempts = 0
	Local $isActive = False

	While $attempts < $maxAttempts
		activeAndMoveWinByChar($charName)
		secondWait(2)
		$isActive = checkActiveAutoHome()
		If $isActive Then
			ExitLoop
		Else
			minuteWait($waitMinutes)
		EndIf
		$attempts += 1
	WEnd

	; B4: Khi auto home active thi tien hanh switch sang main char
	If $isActive Or $isCharActive Then
		switchToMainCharItem($charName, $charMainName, $isHide)
		Return True
	EndIf

	; B5: Het retry nhung auto home van chua active
	Return False
EndFunc

Func processGoArenaV2($mainNo, $rsCount, $arenaLoopCount)
	writeLogMethodStart("processGoArenaV2", @ScriptLineNumber)
	If $arenaLoopCount < 1 Then $arenaLoopCount = 1
	writeLogFile($logFile, "go_arena=true => cho 2 phut va vao arena")
	writeLogFile($logFile, "So lan loop check arena: " & $arenaLoopCount)
	minuteWait(1)
	activeAndMoveWin($mainNo)
	goMapArena($rsCount)
	minisizeMain($mainNo)

	For $i = 1 To $arenaLoopCount
		minuteWait(1)
		activeAndMoveWin($mainNo)
		If Not checkActiveAutoHome() Then
			writeLogFile($logFile, "Lan " & $i & " auto home khong active, vao lai arena")
			goMapArena($rsCount)
			minisizeMain($mainNo)
		Else
			writeLogFile($logFile, "Lan " & $i & " auto home active")
		EndIf
		minisizeMain($mainNo)
	Next
EndFunc

Func withDrawRsV2($jAccountInfo)
	Local $oAccountInfo = extractAccountInfoV2($jAccountInfo)
	Local $charName = $oAccountInfo.Item("charName")
	Local $hourPerRs = $oAccountInfo.Item("hourPerRs")

	writeLogMethodStart("withDrawRsV2", @ScriptLineNumber, $charName)
	If Not login($sSession, $oAccountInfo.Item("username"), $oAccountInfo.Item("password")) Then
		writeLogFile($logFile, "Dang nhap that bai voi account withdraw: " & $charName)
		Return
	EndIf

	If Not checkIP($sSession) Then
		writeLogFile($logFile, "Khong co IP hop le khi withdraw")
		updateLastTimeRs($charName, _DateAdd('h', 24, getTimeNow()))
		Return
	EndIf

	Local $timeNow = getTimeNow()
	Local $sLogReset = getLogReset($sSession, $charName)
	Local $lastTimeRs = getTimeReset($sLogReset, 0)
	Local $nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))

	If $timeNow < $nextTimeRs Then
		writeLogFile($logFile, "Chua den gio withdraw reset")
		updateLastTimeRs($charName, $lastTimeRs)
		Return
	EndIf

	navigateUrl($sSession, combineUrl("web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char=" & $charName))
	secondWait(3)
	submitButton($sSession)
	closeDiaglogConfim($sSession)

	Local $withdrawTimeRs = getWithdrawTimeRs($sSession, $charName)
	Local $newLogReset = getLogReset($sSession, $charName)
	Local $newLastTimeRs = getTimeReset($newLogReset, 0)
	If $withdrawTimeRs < 0 Then $withdrawTimeRs = getRsInDay($newLogReset)

	If Not $oAccountInfo.Item("resetOnline") Then
		Local $mainNo = getMainNoByChar($charName)
		Local $canProcessCharFlow = activeAndMoveWin($mainNo)
		If Not $canProcessCharFlow Then
			Local $switchedOtherChar = switchOtherChar($charName)
			writeLogFile($logFile, "Main khong active, ket qua switchOtherChar: " & $switchedOtherChar)
			$canProcessCharFlow = $switchedOtherChar
		EndIf

		If $canProcessCharFlow Then
			changeThenReturnChar($charName)
			secondWait(2)
			returnChar($mainNo)
			minisizeMain($mainNo)
		Else
			writeLogFile($logFile, "Bo qua flow doi/vao lai nhan vat vi khong active duoc main va switchOtherChar that bai")
		EndIf
	EndIf

	_UpdateWithdrawInfoV2($charName, $withdrawTimeRs, $newLastTimeRs)
	writeLogMethodEnd("withDrawRsV2", @ScriptLineNumber, $charName)
EndFunc

Func _UpdateWithdrawInfoV2($charName, $timeRs, $lastTimeReset)
	writeLogMethodStart("_UpdateWithdrawInfoV2", @ScriptLineNumber, $charName)
	Local $jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
	For $i = 0 To UBound($jsonRsGame) - 1
		If getPropertyJson($jsonRsGame[$i], "char_name") == $charName Then
			Local $jItem = $jsonRsGame[$i]
			_JSONSet($timeRs, $jItem, "time_rs")
			_JSONSet($lastTimeReset, $jItem, "last_time_reset")
			$jsonRsGame[$i] = $jItem
			setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
			ExitLoop
		EndIf
	Next
EndFunc

Func extractAccountInfoV2($jAccountInfo)
	writeLogMethodStart("extractAccountInfoV2", @ScriptLineNumber)
	Local $oAccountInfo = ObjCreate("Scripting.Dictionary")
	Local $username = getPropertyJson($jAccountInfo, "username")
	If $username == "" Then $username = getPropertyJson($jAccountInfo, "user_name")

	$oAccountInfo.Item("username") = $username
	$oAccountInfo.Item("password") = getPropertyJson($jAccountInfo, "password")
	$oAccountInfo.Item("charName") = getPropertyJson($jAccountInfo, "char_name")
	$oAccountInfo.Item("typeRs") = getPropertyJson($jAccountInfo, "type_rs")
	$oAccountInfo.Item("hourPerRs") = getPropertyJson($jAccountInfo, "hour_per_reset")
	$oAccountInfo.Item("resetOnline") = getPropertyJson($jAccountInfo, "reset_online")
	$oAccountInfo.Item("timeRs") = getPropertyJson($jAccountInfo, "time_rs")
	$oAccountInfo.Item("arenaLoopCount") = getPropertyJson($jAccountInfo, "arena_loop_count")
	$oAccountInfo.Item("goArena") = getPropertyJson($jAccountInfo, "go_arena")
	$oAccountInfo.Item("isHide") = getPropertyJson($jAccountInfo, "is_hide")
	$oAccountInfo.Item("lvlMove") = getPropertyJson($jAccountInfo, "lvl_move")
	$oAccountInfo.Item("switchOtherMain") = getPropertyJson($jAccountInfo, "switch_other_main")
	$oAccountInfo.Item("charMainName") = getPropertyJson($jAccountInfo, "char_main_name")
	Return $oAccountInfo
EndFunc

Func calculateRequiredLevelForResetV2($rsCount)
	writeLogMethodStart("calculateRequiredLevelForResetV2", @ScriptLineNumber)
	Local $lvlCanRs = 400
	If $rsCount < 50 Then
		$lvlCanRs = 200 + ($rsCount * 5)
		If $lvlCanRs > 400 Then $lvlCanRs = 400
	EndIf
	Return $lvlCanRs
EndFunc

Func _CheckTimeToResetV2($timeNow, $lastTimeRs, $nextTimeRs, $charName)
	writeLogMethodStart("_CheckTimeToResetV2", @ScriptLineNumber, $charName)
	If ($timeNow < $nextTimeRs) Then
		writeLogFile($logFile, "Chua den thoi gian reset: " & $charName)
		updateLastTimeRs($charName, $lastTimeRs)
		Return False
	EndIf
	Return True
EndFunc

Func _ProcessRs_UpdateAccountInfoV2($charName)
	writeLogMethodStart("_ProcessRs_UpdateAccountInfoV2", @ScriptLineNumber, $charName)
	Local $jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
	Local $sLogReset = getLogReset($sSession, $charName)
	Local $resetInDay = getRsInDay($sLogReset)
	Local $currentRs = getCurrentReset($sLogReset)
	Local $sTimeReset = getTimeReset($sLogReset, 0)

	For $i = 0 To UBound($jsonRsGame) - 1
		If getPropertyJson($jsonRsGame[$i], "char_name") == $charName Then
			Local $jItem = $jsonRsGame[$i]
			_JSONSet($currentRs, $jItem, "rs")
			_JSONSet($resetInDay, $jItem, "time_rs")
			_JSONSet($sTimeReset, $jItem, "last_time_reset")
			_JSONSet(True, $jItem, "last_reset_status")
			$jsonRsGame[$i] = $jItem
			setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
			ExitLoop
		EndIf
	Next
EndFunc

; Method: _UpdateLastResetStatusV2
; Description: Cap nhat trang thai lan reset truoc (true/false) vao file config theo char_name.
Func _UpdateLastResetStatusV2($charName, $status)
	writeLogMethodStart("_UpdateLastResetStatusV2", @ScriptLineNumber, $charName)
	Local $jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
	For $i = 0 To UBound($jsonRsGame) - 1
		If getPropertyJson($jsonRsGame[$i], "char_name") == $charName Then
			Local $jItem = $jsonRsGame[$i]
			_JSONSet($status, $jItem, "last_reset_status")
			$jsonRsGame[$i] = $jItem
			setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
			ExitLoop
		EndIf
	Next
EndFunc

Func validAccountRsV2($aAccountActiveRs)
	writeLogMethodStart("validAccountRsV2", @ScriptLineNumber)
	Local $aAccValidate[0]
	Local $timeWaitRsVip = _JSONGet($jsonPositionConfig, "common.auto.time_wait_rs_vip")
	Local $timeWaitRsZenRs50 = _JSONGet($jsonPositionConfig, "common.auto.time_wait_rs_zen_rs_50")
	Local $maxRsVip = _JSONGet($jsonPositionConfig, "common.auto.max_rs_vip")

	If $timeWaitRsVip == "" Then $timeWaitRsVip = 20
	If $timeWaitRsZenRs50 == "" Then $timeWaitRsZenRs50 = 30
	If $maxRsVip == "" Then $maxRsVip = 10

	For $i = 0 To UBound($aAccountActiveRs) - 1
		Local $jAccount = _NormalizeAccountV2($aAccountActiveRs[$i])
		If _ValidRs_IsInvalidLastTimeV2($jAccount) Then ContinueLoop
		If _ValidRs_IsOverMaxHourResetV2($jAccount) Then ContinueLoop
		If _ValidRs_IsNotTimeToResetV2($jAccount) Then ContinueLoop
		If _ValidRs_IsMaxResetReachedV2($jAccount) Then ContinueLoop
		If _ValidRs_IsTypeRsTimeNotReachedV2($jAccount, $timeWaitRsVip, $timeWaitRsZenRs50) Then ContinueLoop
		If _ValidRs_IsDailyLimitExceededV2($jAccount) Then ContinueLoop
		_ValidRs_AdjustTypeRsIfOverDailyLimitV2($jAccount, $maxRsVip)
		$aAccValidate = redimArray($aAccValidate, $jAccount)
	Next
	Return $aAccValidate
EndFunc

Func _ValidRs_IsInvalidLastTimeV2($jAccount)
	writeLogMethodStart("_ValidRs_IsInvalidLastTimeV2", @ScriptLineNumber)
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $charName = getPropertyJson($jAccount, "char_name")
	If $lastTimeRs == 0 Or StringLen($lastTimeRs) <= 1 Then
		updateLastTimeRs($charName, getTimeNow())
		Return True
	EndIf
	Return False
EndFunc

Func _ValidRs_IsOverMaxHourResetV2($jAccount)
	writeLogMethodStart("_ValidRs_IsOverMaxHourResetV2", @ScriptLineNumber)
	Local $maxHourReset = Number(getPropertyJson($jAccount, "max_hour_reset"))
	If $maxHourReset <= 0 Then $maxHourReset = 24
	If Number(@HOUR) >= $maxHourReset Then Return True
	Return False
EndFunc

Func _ValidRs_IsNotTimeToResetV2($jAccount)
	writeLogMethodStart("_ValidRs_IsNotTimeToResetV2", @ScriptLineNumber)
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $hourPerRs = getPropertyJson($jAccount, "hour_per_reset")
	Local $currentTime = getTimeNow()
	Local $nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))

	If $currentTime < $nextTimeRs Then Return True
	Return False
EndFunc

Func _ValidRs_IsMaxResetReachedV2($jAccount)
	writeLogMethodStart("_ValidRs_IsMaxResetReachedV2", @ScriptLineNumber)
	Local $rs = Number(getPropertyJson($jAccount, "rs"))
	Local $maxRs = Number(getPropertyJson($jAccount, "max_rs"))
	If $maxRs <= 0 Then $maxRs = 2000
	If $rs >= 2000 Then Return True
	If $rs >= $maxRs Then Return True
	Return False
EndFunc

Func _ValidRs_IsTypeRsTimeNotReachedV2($jAccount, $timeWaitRsVip, $timeWaitRsZenRs50)
	writeLogMethodStart("_ValidRs_IsTypeRsTimeNotReachedV2", @ScriptLineNumber)
	Local $typeRs = StringLower(String(getPropertyJson($jAccount, "type_rs")))
	Local $rs = Number(getPropertyJson($jAccount, "rs"))
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $currentTime = getTimeNow()
	Local $lastTimeRsAdd30 = _DateAdd('n', 30, $lastTimeRs)
	Local $lastTimeRsAddRsVip = _DateAdd('n', $timeWaitRsVip, $lastTimeRs)
	Local $timeWaitRsUnder50 = $rs + 6
	Local $lastTimeRsAddRsUnder50 = _DateAdd('n', $timeWaitRsUnder50, $lastTimeRs)

	If $typeRs == "free" Then
		If $currentTime < $lastTimeRsAdd30 And $rs >= 50 Then Return True
		If $currentTime < $lastTimeRsAddRsUnder50 And $rs < 50 Then Return True
	EndIf
	If $typeRs == "vip" And $currentTime < $lastTimeRsAddRsVip Then Return True
	Return False
EndFunc

Func _ValidRs_IsDailyLimitExceededV2($jAccount)
	writeLogMethodStart("_ValidRs_IsDailyLimitExceededV2", @ScriptLineNumber)
	Local $timeRs = Number(getPropertyJson($jAccount, "time_rs"))
	Local $limit = Number(getPropertyJson($jAccount, "limit"))
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $sDateCheck = @YEAR & "/" & @MON & "/" & @MDAY
	If $limit > 0 And $timeRs >= $limit And StringLeft($lastTimeRs, 10) == $sDateCheck Then Return True
	Return False
EndFunc

Func _ValidRs_AdjustTypeRsIfOverDailyLimitV2(ByRef $jAccount, $maxRsVip)
	writeLogMethodStart("_ValidRs_AdjustTypeRsIfOverDailyLimitV2", @ScriptLineNumber)
	Local $typeRs = StringLower(String(getPropertyJson($jAccount, "type_rs")))
	Local $timeRs = Number(getPropertyJson($jAccount, "time_rs"))
	Local $hourPerRs = Number(getPropertyJson($jAccount, "hour_per_reset"))
	If ($typeRs == "vip" And $timeRs > $maxRsVip) And ($hourPerRs == 0) Then
		_JSONSet("free", $jAccount, "type_rs")
	EndIf
EndFunc

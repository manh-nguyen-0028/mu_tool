#include-once
#include <Array.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"
#include "../../utils/game_utils.au3"
#RequireAdmin

$className = "auto_rs_v2.au3"

;~ startAutoRsV2()

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
	Local $username = getPropertyJson($jAccount, "username")
	If $username == "" Then $username = getPropertyJson($jAccount, "user_name")
	_JSONSet($username, $jAccount, "username")
	_JSONSet($username, $jAccount, "user_name")

	If getPropertyJson($jAccount, "go_arena") == "" Then _JSONSet(False, $jAccount, "go_arena")
	If getPropertyJson($jAccount, "hour_per_reset") == "" Then _JSONSet(1, $jAccount, "hour_per_reset")
	If getPropertyJson($jAccount, "time_rs") == "" Then _JSONSet(0, $jAccount, "time_rs")
	If getPropertyJson($jAccount, "limit") == "" Then _JSONSet(5, $jAccount, "limit")
	If getPropertyJson($jAccount, "arena_loop_count") == "" Then _JSONSet(5, $jAccount, "arena_loop_count")
	If getPropertyJson($jAccount, "last_time_reset") == "" Then _JSONSet(getTimeNow(), $jAccount, "last_time_reset")
	If getPropertyJson($jAccount, "rs") == "" Then _JSONSet(0, $jAccount, "rs")
	If getPropertyJson($jAccount, "max_rs") == "" Then _JSONSet(2000, $jAccount, "max_rs")

	Return $jAccount
EndFunc

Func resetV2($jAccountInfo)
	Local $charName = getPropertyJson($jAccountInfo, "char_name")
	Local $resetOnline = getPropertyJson($jAccountInfo, "reset_online")
	Local $mainNo = getMainNoByChar($charName)

	writeLogMethodStart("resetV2", @ScriptLineNumber, $charName)
	If Not $resetOnline Then
		Local $activeMain = activeAndMoveWin($mainNo)
		If Not $activeMain Then $activeMain = switchOtherChar($charName)
		If Not $activeMain Then
			writeLogFile($logFile, "Khong active duoc cua so game de reset: " & $charName)
			Return
		EndIf

		If Not changeChar($mainNo) Then
			writeLogFile($logFile, "Khong doi duoc nhan vat truoc reset: " & $charName)
			Return
		EndIf
	EndIf

	processResetV2($jAccountInfo)
	writeLogMethodEnd("resetV2", @ScriptLineNumber, $charName)
EndFunc

Func processResetV2($jAccountInfo)
	Local $oAccountInfo = extractAccountInfoV2($jAccountInfo)
	Local $charName = $oAccountInfo.Item("charName")
	Local $resetOnline = $oAccountInfo.Item("resetOnline")

	writeLogMethodStart("processResetV2", @ScriptLineNumber, $charName)
	If Not login($sSession, $oAccountInfo.Item("username"), $oAccountInfo.Item("password")) Then
		writeLogFile($logFile, "Dang nhap that bai: " & $charName)
		Return
	EndIf

	Local $timeNow = getTimeNow()
	Local $sLogReset = getLogReset($sSession, $charName)
	Local $lastTimeRs = getTimeReset($sLogReset, 0)
	Local $rsCount = getRsCount($sLogReset)
	Local $nLvl = getCurrentlvl($sLogReset)
	Local $nextTimeRs = addTimePerRs($lastTimeRs, Number($oAccountInfo.Item("hourPerRs")))

	If Not _CheckTimeToResetV2($timeNow, $lastTimeRs, $nextTimeRs, $charName) Then Return

	Local $lvlCanRs = calculateRequiredLevelForResetV2($rsCount)
	If $nLvl < $lvlCanRs Then
		writeLogFile($logFile, "Chua du level de reset. Lvl hien tai=" & $nLvl & " - lvl can=" & $lvlCanRs)
		updateLastTimeRs($charName, getTimeNow())
		If Not $resetOnline Then minisizeMain(getMainNoByChar($charName))
		Return
	EndIf

	resetInWeb($sSession, $oAccountInfo)
	_ProcessRs_UpdateAccountInfoV2($charName)

	If Not $resetOnline Then
		Local $mainNo = getMainNoByChar($charName)
		returnChar($mainNo)
        secondWait(2)
		stopAutoPlus()
		secondWait(2)
		addPointInGameV2()
        secondWait(2)
        startAutoPlus()
		minisizeMain($mainNo)

		Local $goArena = $oAccountInfo.Item("goArena")
		If $goArena Then
			processGoArenaV2($mainNo, $rsCount, Number($oAccountInfo.Item("arenaLoopCount")))
			moveOtherMap($charName)
			addPointInGameV2()
            startAutoPlus()
		EndIf
		minisizeMain($mainNo)
	EndIf

	writeLogMethodEnd("processResetV2", @ScriptLineNumber, $charName)
EndFunc

Func processGoArenaV2($mainNo, $rsCount, $arenaLoopCount)
	If $arenaLoopCount < 1 Then $arenaLoopCount = 1
	writeLogFile($logFile, "go_arena=true => cho 2 phut va vao arena")
	writeLogFile($logFile, "So lan loop check arena: " & $arenaLoopCount)
	minuteWait(2)
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
	Return $oAccountInfo
EndFunc

Func calculateRequiredLevelForResetV2($rsCount)
	Local $lvlCanRs = 400
	If $rsCount < 50 Then
		$lvlCanRs = 200 + ($rsCount * 5)
		If $lvlCanRs > 400 Then $lvlCanRs = 400
	EndIf
	Return $lvlCanRs
EndFunc

Func _CheckTimeToResetV2($timeNow, $lastTimeRs, $nextTimeRs, $charName)
	If ($timeNow < $nextTimeRs) Then
		writeLogFile($logFile, "Chua den thoi gian reset: " & $charName)
		updateLastTimeRs($charName, $lastTimeRs)
		Return False
	EndIf
	Return True
EndFunc

Func _ProcessRs_UpdateAccountInfoV2($charName)
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
			$jsonRsGame[$i] = $jItem
			setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
			ExitLoop
		EndIf
	Next
EndFunc

Func addPointInGameV2()
	sendKeyC()
	secondWait(1)
	For $i = 0 To 1
		clickButtonAddPointV2()
	Next
	sendKeyC()
EndFunc

Func clickButtonAddPointV2()
	_MU_MouseClick_Delay(getProperty("button.bang_c.add_point_x"), getProperty("button.bang_c.add_point_y"))
	_MU_MouseClick_Delay(getProperty("button.bang_c.add_point_confirm_x"), getProperty("button.bang_c.add_point_confirm_y"))
	_MU_MouseClick_Delay(getProperty("button.bang_c.add_point_confirm_dl_x"), getProperty("button.bang_c.add_point_confirm_dl_y"))
	secondWait(1)
EndFunc

Func validAccountRsV2($aAccountActiveRs)
	Local $aAccValidate[0]
	Local $timeWaitRsVip = _JSONGet($jsonPositionConfig, "common.auto.time_wait_rs_vip")
	Local $timeWaitRsZenRs50 = _JSONGet($jsonPositionConfig, "common.auto.time_wait_rs_zen_rs_50")
	Local $maxRsVip = _JSONGet($jsonPositionConfig, "common.auto.max_rs_vip")
	Local $maxRsPo = _JSONGet($jsonPositionConfig, "common.auto.max_rs_po")

	If $timeWaitRsVip == "" Then $timeWaitRsVip = 20
	If $timeWaitRsZenRs50 == "" Then $timeWaitRsZenRs50 = 30
	If $maxRsVip == "" Then $maxRsVip = 10
	If $maxRsPo == "" Then $maxRsPo = 10

	For $i = 0 To UBound($aAccountActiveRs) - 1
		Local $jAccount = _NormalizeAccountV2($aAccountActiveRs[$i])
		If _ValidRs_IsInvalidLastTimeV2($jAccount) Then ContinueLoop
		If _ValidRs_IsNotTimeToResetV2($jAccount) Then ContinueLoop
		If _ValidRs_IsMaxResetReachedV2($jAccount) Then ContinueLoop
		If _ValidRs_IsTypeRsTimeNotReachedV2($jAccount, $timeWaitRsVip, $timeWaitRsZenRs50) Then ContinueLoop
		If _ValidRs_IsDailyLimitExceededV2($jAccount) Then ContinueLoop
		_ValidRs_AdjustTypeRsIfOverDailyLimitV2($jAccount, $maxRsVip, $maxRsPo)
		$aAccValidate = redimArray($aAccValidate, $jAccount)
	Next
	Return $aAccValidate
EndFunc

Func _ValidRs_IsInvalidLastTimeV2($jAccount)
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $charName = getPropertyJson($jAccount, "char_name")
	If $lastTimeRs == 0 Or StringLen($lastTimeRs) <= 1 Then
		updateLastTimeRs($charName, getTimeNow())
		Return True
	EndIf
	Return False
EndFunc

Func _ValidRs_IsNotTimeToResetV2($jAccount)
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $hourPerRs = getPropertyJson($jAccount, "hour_per_reset")
	Local $currentTime = getTimeNow()
	Local $nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))

	If $currentTime < $nextTimeRs Then Return True
	Return False
EndFunc

Func _ValidRs_IsMaxResetReachedV2($jAccount)
	Local $rs = Number(getPropertyJson($jAccount, "rs"))
	Local $maxRs = Number(getPropertyJson($jAccount, "max_rs"))
	If $maxRs <= 0 Then $maxRs = 2000
	If $rs >= 2000 Then Return True
	If $rs >= $maxRs Then Return True
	Return False
EndFunc

Func _ValidRs_IsTypeRsTimeNotReachedV2($jAccount, $timeWaitRsVip, $timeWaitRsZenRs50)
	Local $typeRs = Number(getPropertyJson($jAccount, "type_rs"))
	Local $rs = Number(getPropertyJson($jAccount, "rs"))
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $currentTime = getTimeNow()
	Local $lastTimeRsAdd30 = _DateAdd('n', 30, $lastTimeRs)
	Local $lastTimeRsAdd60 = _DateAdd('n', 60, $lastTimeRs)
	Local $lastTimeRsAddRsVip = _DateAdd('n', $timeWaitRsVip, $lastTimeRs)
	Local $lastTimeRsAddRsZenRs50 = _DateAdd('n', $timeWaitRsZenRs50, $lastTimeRs)

	If $typeRs == 0 Then
		If $currentTime < $lastTimeRsAdd30 And $rs >= 50 Then Return True
		If $currentTime < $lastTimeRsAddRsZenRs50 And $rs < 50 Then Return True
	EndIf
	If $typeRs == 1 And $currentTime < $lastTimeRsAddRsVip Then Return True
	If $typeRs == 2 And $currentTime < $lastTimeRsAdd60 Then Return True
	Return False
EndFunc

Func _ValidRs_IsDailyLimitExceededV2($jAccount)
	Local $timeRs = Number(getPropertyJson($jAccount, "time_rs"))
	Local $limit = Number(getPropertyJson($jAccount, "limit"))
	Local $lastTimeRs = getPropertyJson($jAccount, "last_time_reset")
	Local $sDateCheck = @YEAR & "/" & @MON & "/" & @MDAY
	If $limit > 0 And $timeRs >= $limit And StringLeft($lastTimeRs, 10) == $sDateCheck Then Return True
	Return False
EndFunc

Func _ValidRs_AdjustTypeRsIfOverDailyLimitV2(ByRef $jAccount, $maxRsVip, $maxRsPo)
	Local $typeRs = Number(getPropertyJson($jAccount, "type_rs"))
	Local $timeRs = Number(getPropertyJson($jAccount, "time_rs"))
	Local $hourPerRs = Number(getPropertyJson($jAccount, "hour_per_reset"))
	If (($typeRs == 1 And $timeRs > $maxRsVip) Or ($typeRs == 2 And $timeRs > $maxRsPo)) And ($hourPerRs == 0) Then
		_JSONSet(0, $jAccount, "type_rs")
	EndIf
EndFunc

#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"

Local $aAccountActiveWithrawRs[0]
Local $sSession,$sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC

;~ startWithDrawRs()

Func startWithDrawRs()
	Local $sFilePath = $outputPathRoot & "File_" & $sDateTime & ".txt"
	$logFile = FileOpen($sFilePath, $FO_OVERWRITE)
	; get array account need withdraw reset
	writeLogFile($logFile, "Begin start withdraw reset !")
	ReDim $aAccountActiveWithrawRs[0]
	$jAccountWithdrawRs = getJsonFromFile($jsonPathRoot & "account_reset.json")
	For $i =0 To UBound($jAccountWithdrawRs) - 1
		$active = getPropertyJson($jAccountWithdrawRs[$i], "active")
		$type = getPropertyJson($jAccountWithdrawRs[$i], "type")
		If $active == True And "withdraw" == $type Then
			Redim $aAccountActiveWithrawRs[UBound($aAccountActiveWithrawRs) + 1]
			$aAccountActiveWithrawRs[UBound($aAccountActiveWithrawRs) - 1] = $jAccountWithdrawRs[$i]
		EndIf
	Next
	If UBound($aAccountActiveWithrawRs) == 0 Then Exit
	; close all chrome browser
	checkThenCloseChrome()
	; open sesssion chrome 
	$sSession = SetupChrome()
	For $i = 0 To UBound($aAccountActiveWithrawRs) - 1
		$username = getPropertyJson($aAccountActiveWithrawRs[$i],"user_name")
		$password = getPropertyJson($aAccountActiveWithrawRs[$i],"password")
		$charName = getPropertyJson($aAccountActiveWithrawRs[$i],"char_name")
		$lastTimeRs = getPropertyJson($aAccountActiveWithrawRs[$i],"last_time_reset")
		$limit = getPropertyJson($aAccountActiveWithrawRs[$i],"limit")
		$timeRs = getPropertyJson($aAccountActiveWithrawRs[$i],"time_rs")
		$hourPerRs = getPropertyJson($aAccountActiveWithrawRs[$i],"hour_per_reset")
		;~ $mainNo = getMainNoByChar($charName)
		$nextTimeRs = addHour($lastTimeRs, Number($hourPerRs))
		writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
		If getTimeNow() < $nextTimeRs Then 
			writeLogFile($logFile, "Chua den thoi gian reset. getTimeNow() < $nextTimeRs = " & getTimeNow() < $nextTimeRs)
			writeLogFile($logFile, "Thoi gian hien tai: " & getTimeNow())
			writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
			ContinueLoop
		EndIf
		If $timeRs >= $limit Then 
			writeLogFile($logFile, "$timeRs >= $limit : " & $timeRs >= $limit)
			ContinueLoop
		EndIf
		; Begin withdraw reset
		withdrawRs($username, $password, $charName,$hourPerRs)
		; Logout account
		_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
		secondWait(5)
		; check last reset
	Next

	FileClose($logFile)
	
	; Close webdriver neu thuc hien xong 
	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
EndFunc

Func withdrawRs($username, $password, $charName,$hourPerRs)
	$isLoginSuccess = login($sSession, $username, $password, $charName)
	secondWait(5)
	If $isLoginSuccess == True Then
		$isHaveIP = checkIp($sSession, $_WD_LOCATOR_ByXPath)
		If $isHaveIP == True Then
			$timeNow = getTimeNow()
			$sLogReset = getLogReset($sSession, $charName)
			$lastTimeRs = getTimeReset($sLogReset,0)
			$nextTimeRs = addHour($lastTimeRs, Number($hourPerRs))
			If $timeNow < $nextTimeRs Then 
				writeLogFile($logFile, "Chua den thoi gian reset. getTimeNow() < $nextTimeRs = " & $timeNow < $nextTimeRs)
				writeLogFile($logFile, "Thoi gian hien tai: " & $timeNow)
				writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
				$jsonRsGame = getJsonFromFile($jsonPathRoot & "account_reset.json")
					For $i =0 To UBound($jsonRsGame) - 1
						$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
						If $charNameTmp == $charName Then
							_JSONSet($lastTimeRs, $jsonRsGame[$i], "last_time_reset")
							setJsonToFileFormat($jsonPathRoot & "account_reset.json", $jsonRsGame)
						EndIf
					Next
				Return
			EndIf

			; withraw reset
			$errorIp = _Demo_NavigateCheckBanner($sSession,combineUrl("web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char=" & $charName))
			secondWait(5)
			writeLogFile($logFile, "$errorIp: " & $errorIp)

			If $errorIp == $_WD_ERROR_Timeout Then
				; Thuc hien set lai vao file de khong thuc hien rs nua
				;~ setRsLogByAccountProperty($accountInfo,"is_have_ip", False)
				$sElement = findElement($sSession, "//button[@type='submit']") 
				clickElement($sSession, $sElement)
				secondWait(5)
				$sElement = findElement($sSession, "//button[@class='swal2-confirm swal2-styled']") 
				clickElement($sSession, $sElement)
				writeLogFile($logFile, "IP khong chinh chu khong the RS")
				secondWait(5)
			Else
				$sElement = findElement($sSession, "//button[@type='submit']") 
				clickElement($sSession, $sElement)
				secondWait(5)
				$sElement = findElement($sSession, "//button[@class='swal2-confirm swal2-styled']") 
				clickElement($sSession, $sElement)
				writeLogFile($logFile, "Rut reset thanh cong !")
				secondWait(5)
				$jsonRsGame = getJsonFromFile($jsonPathRoot & "account_reset.json")
				For $i =0 To UBound($jsonRsGame) - 1
					$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
					If $charNameTmp == $charName Then
						;~ _JSONSet(getTimeNow(), $jsonRsGame[$i],"last_time_reset")
						; reset in day
						$sLogReset = getLogReset($sSession, $charName)
						$resetInDay = getRsInDay($sLogReset)
						_JSONSet($resetInDay, $jsonRsGame[$i], "time_rs")
						; last time rs
						$sTimeReset = getTimeReset($sLogReset,0)
						_JSONSet($sTimeReset, $jsonRsGame[$i], "last_time_reset")
						setJsonToFileFormat($jsonPathRoot & "account_reset.json", $jsonRsGame)
					EndIf
				Next
			EndIf
		EndIf
	EndIf
	
EndFunc
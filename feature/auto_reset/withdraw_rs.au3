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
Local $sSession

start()

Func start()
	; get array account need withdraw reset
	$jAccountWithdrawRs = getJsonFromFile($jsonPathRoot & "account_withdraw_config.json")
	For $i =0 To UBound($jAccountWithdrawRs) - 1
		$active = getPropertyJson($jAccountWithdrawRs[$i], "active")
		If $active == True Then
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
		$lastDateReset = getPropertyJson($aAccountActiveWithrawRs[$i],"last_date_reset")
		$currentDate = @YEAR & "-" & @MON & "-" & @MDAY
		If $currentDate <> $lastDateReset Then $timeRs = 0
		If $timeRs == $limit Then ContinueLoop
		; Begin withdraw reset
		withdrawRs($username, $password, $charName)
		; Logout account
		_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
		secondWait(5)
		; check last reset
	Next

	; Close webdriver neu thuc hien xong 
	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
EndFunc

Func withdrawRs($username, $password, $charName)
	$isLoginSuccess = login($sSession, $username, $password, $charName)
	secondWait(5)
	If $isLoginSuccess == True Then
		$isHaveIP = checkIp($sSession, $_WD_LOCATOR_ByXPath)
		If $isHaveIP == True Then
			; withraw reset
			$errorIp = _Demo_NavigateCheckBanner($sSession,combineUrl("web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char=" & $charName))
			secondWait(5)
			writeLog("$errorIp: " & $errorIp)

			If $errorIp == $_WD_ERROR_Timeout Then
				; Thuc hien set lai vao file de khong thuc hien rs nua
				;~ setRsLogByAccountProperty($accountInfo,"is_have_ip", False)
				$sElement = findElement($sSession, "//button[@type='submit']") 
				clickElement($sSession, $sElement)
				secondWait(5)
				$sElement = findElement($sSession, "//button[@class='swal2-confirm swal2-styled']") 
				clickElement($sSession, $sElement)
				writeLog("IP khong chinh chu khong the RS")
				secondWait(5)
			Else
				$sElement = findElement($sSession, "//button[@type='submit']") 
				clickElement($sSession, $sElement)
				secondWait(5)
				$sElement = findElement($sSession, "//button[@class='swal2-confirm swal2-styled']") 
				clickElement($sSession, $sElement)
				writeLog("Rut reset thanh cong !")
				secondWait(5)
			EndIf
		EndIf
	EndIf
	
EndFunc
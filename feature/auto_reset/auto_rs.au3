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

; First time run => check log then write to file
;~ checkLogRsFirstTime()

Local $aAccountActiveWithrawRs[0]
Local $sSession

;~ $sSession = SetupChrome()
;~ login($sSession,"vinci7","manhva02","Victozia")
;~ $lvlStopCheck = 20
;~ checkLvlInWeb("Victozia", $lvlStopCheck, 1)

start()

Func start()
	; get array account need withdraw reset
	$jAccountWithdrawRs = getJsonFromFile($jsonPathRoot & "account_reset.json")
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
		processReset($username, $password, $charName)
		; Logout account
		_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
		secondWait(5)
		; check last reset
	Next

	; Close webdriver neu thuc hien xong 
	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
EndFunc

Func processReset($username, $password, $charName)
	$isLoginSuccess = login($sSession, $username, $password, $charName)
	secondWait(5)
	If $isLoginSuccess == True Then
		; Vào nhân vật kiểm tra lvl
		_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
		secondWait(5)
		; find lvl
		$sElement = findElement($sSession, "//span[@class='t-level']") 
		$tLvl = getTextElement($sSession, $sElement)
		$nLvl = Number($tLvl)
		If $nLvl == 400 Then 
			$mainNo = getMainNoByChar($charName)
			; Active main no 
			$activeWin = activeAndMoveWin($mainNo)
			If $activeWin == True Then
				; Click bỏ hết các bảng thông báo
				handelWhenFinshDevilEvent()
				; 1. Change Char
				changeChar()
				; 2. Reset in web
				_WD_Navigate($sSession, $baseMuUrl & "web/char/reset.shtml?char=" & $charName)
				secondWait(5)
				; Click radio rs vip
				$typeRs = 1
				_WD_ExecuteScript($sSession, "$(""input[name='rstype']"")["&$typeRs&"].click()")
				secondWait(2)
				; Click submit
				_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
				secondWait(2)
				; Submit add point
				_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
				secondWait(2)
				; 3. Return game
				returnChar(getMainNo($mainNo))
				; 4. Go to sport
				goToSportLvl1($mainNo)
				; 5. Check lvl in web
				$lvlStopCheck = 20
				checkLvlInWeb($charName, $lvlStopCheck, 1)
				; 6. Active main
				activeAndMoveWin($mainNo)
				; 7. Go map lvl
				goMapLvl()
				; 8. Check lvl in web
				$lvlStopCheck = 400
				checkLvlInWeb($charName, $lvlStopCheck, 1)
				; 9. Follow leader
				_MU_followLeader()
				; 10. minisize main 
				minisizeMain($mainNo)
				; 11. Logout account
				_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
				secondWait(5)
			EndIf
		EndIf
	EndIf
EndFunc

#cs
Thay đổi nhân vật để reset.
Trước khi thay đổi nhân vật cần check xem đã đủ lvl reset hay chưa ( 400 ).
Nếu không đủ lvl rs thì thực hiện follow leader ( mục đích nếu bị bắn về thành ) và chờ 15p để check lại lvl
Nếu đủ thì thực hiện thay đổi nhân vật
#ce
Func changeChar()
	writeLog("Begin change char !")
	sendKeyDelay("+h")
	secondWait(1)
	sendKeyDelay("{ESC}")
	secondWait(1)
	; Bam chon nhat vat khac
	_MU_MouseClick_Delay(518, 456)
	secondWait(7)
	If PixelGetColor(47,764) <> 0xC06A1A Then
		sendKeyDelay("{ESC}")
		; Bam chon nhat vat khac
		_MU_MouseClick_Delay(518, 456)
		secondWait(7)
	EndIf
EndFunc 

#cs
	Dang nhap lai vao nhan vat
#ce
Func returnChar($mainNo) 
	activeAndMoveWin($mainNo)
	secondWait(1)
	writeLog("Bat dau chon nhan vat vao lai game ! Main No: " & $mainNo)
	_MU_Rs_MouseClick_Delay(924, 771)
	secondWait(12)
EndFunc 

#cs
	Tim sport de luyen lvl len 20
#ce
Func goToSportLvl1($mainNo) 
	writeLog("Bat ban do !")
	Send("{Tab}")
	secondWait(2)
	; An nhan vat
	sendKeyDelay("+h")
	secondWait(1)
	writeLog("Bat dau tim vi tri sport 1")
	_MU_MouseClick_Delay(501, 423)
	secondWait(1)
	Send("{Tab}")
	writeLog("Tat ban do !")
	secondWait(2)
	WinSetState($mainNo,"",@SW_MINIMIZE)
EndFunc

Func checkLvlInWeb($charName, $lvlStopCheck, $timeDelay)
	; Vào nhân vật kiểm tra lvl
	_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
	secondWait(5)
	
	; find lvl
	$sElement = findElement($sSession, "//span[@class='t-level']") 
	$tLvl = getTextElement($sSession, $sElement)
	$nLvl = Number($tLvl)
	writeLog("Current level: " & $nLvl)
	While $nLvl < $lvlStopCheck
		; Wait 1 min then retry
		minuteWait($timeDelay)
		_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
		secondWait(5)
		; find lvl
		$sElement = findElement($sSession, "//span[@class='t-level']") 
		$tLvl = getTextElement($sSession, $sElement)
		$nLvl = Number($tLvl)
	WEnd
	
	Return True
EndFunc

#cs
	Kiem tra xem da du lvl de len stadium hay chua ( 20 lvl )
#ce
Func checkGoMapStadium() 
	clickEventIconThenGoStadium()
	Return True
EndFunc


#cs
	Vao event Lvl 
#ce
Func goMapLvl()
	writeLog("Bat dau map event lvl ! ")
	_MU_Rs_MouseClick_Delay(134, 100)
	_MU_Rs_MouseClick_Delay(383, 237)
	secondWait(3)
	; Go to center
	_MU_Rs_MouseClick_Delay(399, 183)
	secondWait(2)
	; Enable Auto Home
	Opt("SendKeyDownDelay", 1000)  ;5 second delay
	Send("{HOME}")
	Opt("SendKeyDownDelay", 5)  ;reset to default when done
	; Doi 16p cho het event
	minuteWait(16)
EndFunc
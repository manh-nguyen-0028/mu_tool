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

Local $aAccountActiveWithrawRs[0]
Local $sSession,$logFile
Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC

Func testAa()
	Local $pTime = "2023/10/02 18:34:58"
	Local $amount = 7

	Local $addedTime = _DateAdd('h', $amount, $pTime)
	Local $addedTime1 = _DateAdd('n', -20, $addedTime)

	MsgBox($MB_OK, "Output Time", "Input Time: " & $pTime & @CRLF & "Output Time: " & $addedTime)
	MsgBox($MB_OK, "Output Time", "Input Time: " & $pTime & @CRLF & "Output Time: " & $addedTime1)
EndFunc

Func startAutoRs()
	; get array account need withdraw reset
	Local $sFilePath = $outputPathRoot & "File_" & $sDateTime & ".txt"
	$logFile = FileOpen($sFilePath, $FO_OVERWRITE)
	writeLogFile($logFile, "Begin start auto reset !")
	ReDim $aAccountActiveWithrawRs[0]
	$jAccountWithdrawRs = getJsonFromFile($jsonPathRoot & "account_reset.json")
	For $i =0 To UBound($jAccountWithdrawRs) - 1
		$active = getPropertyJson($jAccountWithdrawRs[$i], "active")
		$type = getPropertyJson($jAccountWithdrawRs[$i], "type")
		If $active == True And "reset" == $type Then
			Redim $aAccountActiveWithrawRs[UBound($aAccountActiveWithrawRs) + 1]
			$aAccountActiveWithrawRs[UBound($aAccountActiveWithrawRs) - 1] = $jAccountWithdrawRs[$i]
		EndIf
	Next
	If UBound($aAccountActiveWithrawRs) == 0 Then Exit
	; close all chrome browser
	checkThenCloseChrome()
	; open sesssion chrome
	For $i = 0 To UBound($aAccountActiveWithrawRs) - 1
		$username = getPropertyJson($aAccountActiveWithrawRs[$i],"user_name")
		$password = getPropertyJson($aAccountActiveWithrawRs[$i],"password")
		$charName = getPropertyJson($aAccountActiveWithrawRs[$i],"char_name")
		$lastTimeRs = getPropertyJson($aAccountActiveWithrawRs[$i],"last_time_reset")
		$limit = getPropertyJson($aAccountActiveWithrawRs[$i],"limit")
		$timeRs = getPropertyJson($aAccountActiveWithrawRs[$i],"time_rs")
		$hourPerRs = getPropertyJson($aAccountActiveWithrawRs[$i],"hour_per_reset")
		
		$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
		$mainNo = getMainNoByChar($charName)
		
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
		; Begin reset
		$activeMain = activeAndMoveWin($mainNo)

		; Truong hop main hien tai khong duoc active, active main khac
		If $activeMain == False Then $activeMain = switchOtherChar($charName)

		If $activeMain == True Then 
			If $sSession Then 
				writeLog("Da ton tai session. Khong can khoi tao lai")
			Else
				$sSession = SetupChrome()
			EndIf
			processReset($aAccountActiveWithrawRs[$i])
			; Logout account
			_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
			secondWait(5)
		EndIf
	Next

	FileClose($logFile)

	; Close webdriver neu thuc hien xong 
	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
EndFunc

Func processReset($jAccountInfo)
	$username = getPropertyJson($jAccountInfo,"user_name")
	$password = getPropertyJson($jAccountInfo,"password")
	$charName = getPropertyJson($jAccountInfo,"char_name")
	$typeRs = getPropertyJson($jAccountInfo,"type_rs")
	$lvlMove = getPropertyJson($jAccountInfo,"lvl_move")
	$hourPerRs = getPropertyJson($jAccountInfo,"hour_per_reset")
	$resetOnline = getPropertyJson($jAccountInfo,"reset_online")

	writeLogFile($logFile, "Begin handle process reset with account: " & $charName)
	$isLoginSuccess = login($sSession, $username, $password)
	secondWait(5)
	If $isLoginSuccess == True Then
		$timeNow = getTimeNow()
		$sLogReset = getLogReset($sSession, $charName)
		$lastTimeRs = getTimeReset($sLogReset, 0)
		$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
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
				secondWait(3)
				; 1. Change Char
				changeChar($mainNo)
				; 2. Reset in web
				_WD_Navigate($sSession, $baseMuUrl & "web/char/reset.shtml?char=" & $charName)
				secondWait(5)
				; Click radio rs vip
				_WD_ExecuteScript($sSession, "$(""input[name='rstype']"")["&$typeRs&"].click()")
				secondWait(2)
				; Click submit
				_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
				secondWait(2)
				; Submit add point
				_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
				secondWait(2)
				; close diaglog confirm
				closeDiaglogConfim($sSession)
				; Update info account json config
				$jsonRsGame = getJsonFromFile($jsonPathRoot & "account_reset.json")
				For $i =0 To UBound($jsonRsGame) - 1
					$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
					If $charNameTmp == $charName Then
						$sLogReset = getLogReset($sSession, $charName)
						$resetInDay = getRsInDay($sLogReset)
						_JSONSet($resetInDay, $jsonRsGame[$i], "time_rs")
						; last time rs
						$sTimeReset = getTimeReset($sLogReset,0)
						_JSONSet($sTimeReset, $jsonRsGame[$i], "last_time_reset")
						setJsonToFileFormat($jsonPathRoot & "account_reset.json", $jsonRsGame)
					EndIf
				Next
				; If reset online = true => withow handle in game
				If $resetOnline == False Then
					; 3. Return game
					returnChar($mainNo)
					; 4. Go to sport
					goToSportLvl1($mainNo)
					; 5. Check lvl in web
					$lvlStopCheck = 20
					checkLvlInWeb($charName, $lvlStopCheck, 1)
					; 6. Active main
					activeAndMoveWin($mainNo)
					; 7. Go map lvl
					If $resetInDay <=3 Then 
						goMapLvl()
					Else
						goMapArena()
					EndIf
					; 8. Check lvl in web
					$lvlStopCheck = Number($lvlMove)
					checkLvlInWeb($charName, $lvlStopCheck, 1)
					activeAndMoveWin($mainNo)
					; Move other map
					moveOtherMap()
					secondWait(8)
					; 9. Follow leader
					_MU_followLeader(1)
					; 10. minisize main 
					minisizeMain($mainNo)
				EndIf
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
Func changeChar($mainNo)
	writeLogFile($logFile, "Begin change char !")
	sendKeyDelay("+h")
	secondWait(1)
	sendKeyDelay("{ESC}")
	secondWait(1)
	; Bam chon nhat vat khac
	_MU_MouseClick_Delay(518, 456)
	secondWait(7)
	; Check title 
	$checkActive = activeAndMoveWin($mainNo)
	if $checkActive == True Then
	;~ If PixelGetColor(47,764) <> 0xC06A1A Then
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
	writeLogFile($logFile, "Bat dau chon nhan vat vao lai game ! Main No: " & $mainNo)
	_MU_Rs_MouseClick_Delay(924, 771)
	secondWait(12)
EndFunc 

#cs
	Tim sport de luyen lvl len 20
#ce
Func goToSportLvl1($mainNo) 
	writeLogFile($logFile, "Bat ban do !")
	Send("{Tab}")
	secondWait(2)
	; An nhan vat
	sendKeyDelay("+h")
	secondWait(1)
	writeLogFile($logFile, "Bat dau tim vi tri sport 1")
	_MU_MouseClick_Delay(501, 423)
	secondWait(1)
	Send("{Tab}")
	writeLogFile($logFile, "Tat ban do !")
	secondWait(2)
	WinSetState($mainNo,"",@SW_MINIMIZE)
EndFunc

Func checkLvlInWeb($charName, $lvlStopCheck, $timeDelay)
	; Vào nhân vật kiểm tra lvl
	_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
	secondWait(5)
	$mainNo = getMainNoByChar($charName)
	; find lvl
	$sElement = findElement($sSession, "//span[@class='t-level']") 
	$tLvl = getTextElement($sSession, $sElement)
	$nLvl = Number($tLvl)
	writeLogFile($logFile, "Current level: " & $nLvl)
	$tmpLvl = 0
	While $nLvl < $lvlStopCheck
		If $nLvl <> $tmpLvl Or $nLvl < 20 Then 
			$tmpLvl = $nLvl
		Else
			activeAndMoveWin($mainNo)
			$checkAutoHome = checkActiveAutoHome()
			If $checkAutoHome == False Then
				$activeMain = activeAndMoveWin($mainNo)
				If $activeMain == True Then goMapArena()
			EndIf
		EndIf
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
	writeLogFile($logFile, "Bat dau map event lvl ! ")
	; Click event icon
	_MU_Rs_MouseClick_Delay(155, 119)
	; Click map lvl
	_MU_Rs_MouseClick_Delay(484, 326)
	secondWait(3)
	; Go to center
	_MU_Rs_MouseClick_Delay(399, 183)
	secondWait(2)
	; Enable Auto Home
	Opt("SendKeyDownDelay", 1000)  ;5 second delay
	Send("{HOME}")
	Opt("SendKeyDownDelay", 5)  ;reset to default when done
	; Doi 16p cho het event
	;~ minuteWait(16)
EndFunc

Func goMapArena()
	sendKeyDelay("{Enter}")
	sendKeyDelay("{Enter}")
	writeLogFile($logFile, "Bat dau map arena ! ")
	; Click event icon then go arena map
	clickEventIconThenGoStadium()
	; Go to sport
	goSportStadium()
EndFunc

Func goSportStadium() 
	Send("{Tab}")
	secondWait(2)
	_MU_Rs_MouseClick_Delay(269, 329)
	Send("{Tab}")
	secondWait(2)
EndFunc
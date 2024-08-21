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

Local $aAccountActiveRs[0]
Local $sSession,$logFile
Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
Local $sDate = @YEAR & @MON & @MDAY
Local $className = @ScriptName

testAa()

Func testAa($abc="x", $abc1="x1", $abc2="x2")
	;~ Local $pTime = "2023/10/02 18:34:58"
	;~ Local $amount = 7

	;~ Local $addedTime = _DateAdd('h', $amount, $pTime)
	;~ Local $addedTime1 = _DateAdd('n', -20, $addedTime)

	;~ MsgBox($MB_OK, "Output Time", "Input Time: " & $pTime & @CRLF & "Output Time: " & $addedTime)
	;~ MsgBox($MB_OK, "Output Time", "Input Time: " & $pTime & @CRLF & "Output Time: " & $addedTime1)
	$charInfoText = "Reset 889 lần xxmrgreo xxvxv"
	
	$sResetCount = StringMid($charInfoText, 7, 10)
	$charRsCount =StringSplit($sResetCount, ' ', 0)
	$nRs = Number($charRsCount[1])

	writeLog("XXX: " & $nRs)
	writeLogMethodStart("testAa",@ScriptLineNumber & $charRsCount[0])
EndFunc

Func startAutoRs()
	; get array account need withdraw reset
	Local $sFilePath = $outputPathRoot & "File_Log_AutoRS_.txt"
	$logFile = FileOpen($sFilePath, $FO_APPEND)
	writeLogMethodStart("startAutoRs",@ScriptLineNumber)
	writeLogFile($logFile, "Begin start auto reset !")
	ReDim $aAccountActiveRs[0]
	$jAccountWithdrawRs = getJsonFromFile($jsonPathRoot & $accountRsFileName)
	For $i =0 To UBound($jAccountWithdrawRs) - 1
		$active = getPropertyJson($jAccountWithdrawRs[$i], "active")
		$type = getPropertyJson($jAccountWithdrawRs[$i], "type")
		If $active == True And "reset" == $type Then
			Redim $aAccountActiveRs[UBound($aAccountActiveRs) + 1]
			$aAccountActiveRs[UBound($aAccountActiveRs) - 1] = $jAccountWithdrawRs[$i]
		EndIf
	Next
	If UBound($aAccountActiveRs) == 0 Then 
		writeLogFile($logFile, "Khong co account nao active => Ket thuc chuong trinh !")
		FileClose($logFile)
		Return
	Else
		; close all chrome browser
		checkThenCloseChrome()
		$sSession = SetupChrome()
	EndIf

	For $i = 0 To UBound($aAccountActiveRs) - 1
		writeLogFile($logFile, "Dang xu ly voi account => " & convertJsonToString($aAccountActiveRs[$i]))
		$username = getPropertyJson($aAccountActiveRs[$i],"user_name")
		$password = getPropertyJson($aAccountActiveRs[$i],"password")
		$charName = getPropertyJson($aAccountActiveRs[$i],"char_name")
		$lastTimeRs = getPropertyJson($aAccountActiveRs[$i],"last_time_reset")
		$limit = getPropertyJson($aAccountActiveRs[$i],"limit")
		$timeRs = getPropertyJson($aAccountActiveRs[$i],"time_rs")
		$hourPerRs = getPropertyJson($aAccountActiveRs[$i],"hour_per_reset")
		$resetOnline = getPropertyJson($aAccountActiveRs,"reset_online")
		
		$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
		$mainNo = getMainNoByChar($charName)
		
		If getTimeNow() < $nextTimeRs Then 
			writeLogFile($logFile, "Chua den thoi gian reset. Thoi gian gan nhat co the reset" & $nextTimeRs)
			;~ writeLogFile($logFile, "Thoi gian hien tai: " & getTimeNow())
			;~ writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
			ContinueLoop
		EndIf
		If $timeRs >= $limit Then 
			writeLogFile($logFile, "Vuot qua so lan rs cho phep trong ngay. So lan RS hien tai => " & $timeRs)
			ContinueLoop
		EndIf

		; Neu la rs online thi can thuc hien active main
		If $resetOnline == False Then
			; Begin reset
			$activeMain = activeAndMoveWin($mainNo)

			; Truong hop main hien tai khong duoc active, active main khac
			If $activeMain == False Then $activeMain = switchOtherChar($charName)
			If $activeMain == True Then 
				processReset($aAccountActiveRs[$i])
			EndIf
		Else
			processReset($aAccountActiveRs[$i])
		EndIf

		; Logout account
		_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
		secondWait(5)
	Next

	writeLogMethodEnd("startAutoRs",@ScriptLineNumber)

	FileClose($logFile)

	; Close webdriver neu thuc hien xong 
	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
EndFunc

Func processReset($jAccountInfo)
	writeLogMethodStart("processReset",@ScriptLineNumber,$jAccountInfo)
	$username = getPropertyJson($jAccountInfo,"user_name")
	$password = getPropertyJson($jAccountInfo,"password")
	$charName = getPropertyJson($jAccountInfo,"char_name")
	$typeRs = getPropertyJson($jAccountInfo,"type_rs")
	$lvlMove = getPropertyJson($jAccountInfo,"lvl_move")
	$hourPerRs = getPropertyJson($jAccountInfo,"hour_per_reset")
	$resetOnline = getPropertyJson($jAccountInfo,"reset_online")
	$isBuff = getPropertyJson($jAccountInfo,"is_buff")
	$isMainCharacter = getPropertyJson($jAccountInfo,"is_main_character")

	writeLogFile($logFile, "Begin handle process reset with account: " & $charName)
	$isLoginSuccess = login($sSession, $username, $password)
	secondWait(5)
	If $isLoginSuccess == True Then
		$timeNow = getTimeNow()
		$sLogReset = getLogReset($sSession, $charName)
		$lastTimeRs = getTimeReset($sLogReset, 0)
		$rsCount = getRsCount($sLogReset)
		$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
		If $timeNow < $nextTimeRs Then 
			writeLogFile($logFile, "Chua den thoi gian reset. getTimeNow() < $nextTimeRs = " & $timeNow < $nextTimeRs)
			writeLogFile($logFile, "Thoi gian hien tai: " & $timeNow)
			writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
			$jsonRsGame = getJsonFromFile($jsonPathRoot & $accountRsFileName)
				For $i =0 To UBound($jsonRsGame) - 1
					$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
					If $charNameTmp == $charName Then
						_JSONSet($lastTimeRs, $jsonRsGame[$i], "last_time_reset")
						setJsonToFileFormat($jsonPathRoot & $accountRsFileName, $jsonRsGame)
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
		; implement them viec check lvl rs theo rs 
		$lvlCanRs = 400
		If $rsCount < 50 Then
			$lvlCanRs = 200 + ($rsCount * 4)
			If $lvlCanRs > 400 Then $lvlCanRs = 400
		EndIf
		writeLogFile($logFile, @ScriptLineNumber & "Rs hien tai: " & $rsCount & " - Lvl can thiet de RS la: " & $lvlCanRs)

		If $nLvl >= $lvlCanRs Then 
			$mainNo = getMainNoByChar($charName)
			; Active main no 
			$activeWin = activeAndMoveWin($mainNo)
			; tìm thấy lvl la coi nhu da online roi, khong can check lai $activeWin vi da thuc hien o buoc truoc
			;~ If $activeWin == True Then
			If $resetOnline == False Then
				; Click bỏ hết các bảng thông báo
				handelWhenFinshDevilEvent()
				secondWait(3)
				; 1. Change Char
				changeChar($mainNo)
			EndIf
			; 2. Reset in web
			_WD_Navigate($sSession, $baseMuUrl & "web/char/reset.shtml?char=" & $charName)
			secondWait(5)
			; Click radio rs vip
			_WD_ExecuteScript($sSession, "$(""input[name='rstype']"")["&$typeRs&"].click()")
			secondWait(2)
			If $resetOnline == True Then
				; Click radio online
				_WD_ExecuteScript($sSession, "$(""input[name='rsonline']"").click()")
				secondWait(2)
			EndIf
			; Click submit
			_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
			secondWait(2)
			; Submit add point
			_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
			secondWait(2)
			; close diaglog confirm
			closeDiaglogConfim($sSession)
			; Update info account json config
			$jsonRsGame = getJsonFromFile($jsonPathRoot & $accountRsFileName)
			For $i =0 To UBound($jsonRsGame) - 1
				$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
				If $charNameTmp == $charName Then
					$sLogReset = getLogReset($sSession, $charName)
					$resetInDay = getRsInDay($sLogReset)
					_JSONSet($resetInDay, $jsonRsGame[$i], "time_rs")
					; last time rs
					$sTimeReset = getTimeReset($sLogReset,0)
					_JSONSet($sTimeReset, $jsonRsGame[$i], "last_time_reset")
					setJsonToFileFormat($jsonPathRoot & $accountRsFileName, $jsonRsGame)
					If $resetInDay == 1 And $isBuff == True Then
					;~ If $isBuff == True Then
						; https://hn.mugamethuvn.info/web/char/charbuff.shtml
						writeLogFile($logFile, "Begin buff char: " & $charName)
						_WD_Navigate($sSession, $baseMuUrl & "web/char/charbuff.shtml")
						secondWait(5)
						_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
						secondWait(2)
						; close diaglog confirm
						closeDiaglogConfim($sSession)
					EndIf
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
				writeLogFile($logFile, @ScriptLineNumber & " Bat dau check lvl tren web !")
				$lvlStopCheck = Number($lvlMove)
				checkLvlInWeb($charName, $lvlStopCheck, 1)
				activeAndMoveWin($mainNo)
				writeLogFile($logFile, @ScriptLineNumber & " Ket thuc check lvl tren web !")
				; Move other map
				moveOtherMap()
				secondWait(8)
				; 9. Follow leader
				_MU_followLeader(1)
				; 10. Wait in 1 min
				minuteWait(1)
			EndIf

			$mainNoMinisize = $mainNo

			If $isMainCharacter == False Then
				writeLogFile($logFile, "Xu ly truong hop main khong phai la main chinh")
				$otherChar = getOtherChar($charName)
				If $otherChar <> "" Then 
					$resultWwithChar = switchOtherChar($otherChar)
					If $resultWwithChar == True Then $mainNoMinisize = getMainNoByChar($otherChar)
				EndIf
				writeLogFile($logFile, "mainNoMinisize: " & $mainNoMinisize)
			EndIf

			; 10. minisize main 
			minisizeMain($mainNoMinisize)
			; 11. Logout account
			_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
			secondWait(5)
			;~ EndIf
		EndIf
	EndIf
	writeLogMethodEnd("processReset",@ScriptLineNumber,$jAccountInfo)
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
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.change_char.x"), _JSONGet($jsonPositionConfig,"button.change_char.y"))
	secondWait(7)
	; Check title 
	$checkActive = activeAndMoveWin($mainNo)
	if $checkActive == True Then
	;~ If PixelGetColor(47,764) <> 0xC06A1A Then
		sendKeyDelay("{ESC}")
		; Bam chon nhat vat khac
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.change_char.x"), _JSONGet($jsonPositionConfig,"button.change_char.y"))
		secondWait(7)
	EndIf
EndFunc 

#cs
	Dang nhap lai vao nhan vat
#ce
Func returnChar($mainNo) 
	$checkActive = activeAndMoveWin($mainNo)
	secondWait(1)
	writeLogFile($logFile, "Bat dau chon nhan vat vao lai game ! Main No: " & $mainNo)
	While $checkActive == False
		_MU_Rs_MouseClick_Delay(924, 771)
		$checkActive = activeAndMoveWin($mainNo)
	WEnd
	writeLogFile($logFile, "Vao lai game thanh cong ! Main No: " & $mainNo)
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
	;~ writeLogFile($logFile, "Current level: " & $nLvl)
	$tmpLvl = 0
	While $nLvl < $lvlStopCheck
		If $nLvl <> $tmpLvl Or $nLvl < 20 Then 
			$tmpLvl = $nLvl
		Else
			activeAndMoveWin($mainNo)
			$checkAutoHome = checkActiveAutoHome()
			writeLogFile($logFile, @ScriptLineNumber & " $checkAutoHome = " &$checkAutoHome)
			If $checkAutoHome == False Then
				$activeMain = activeAndMoveWin($mainNo)
				If $activeMain == True Then 
					writeLogFile($logFile, @ScriptLineNumber & " Vao map stadium ")
					goMapArena()
				EndIf
			EndIf
		EndIf
		;~ writeLogFile($logFile, "Current level: " & $nLvl)
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
	;~ _MU_Rs_MouseClick_Delay(155, 119)
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.x"), _JSONGet($jsonPositionConfig,"button.event_icon.y"))
	; Click map lvl
	;~ _MU_Rs_MouseClick_Delay(484, 326)
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_x"), _JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_y"))
	secondWait(3)
	; Go to center
	;~ _MU_Rs_MouseClick_Delay(399, 183)
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_center_x"), _JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_center_y"))
	secondWait(2)
	; Enable Auto Home
	sendKeyDelay("{HOME}");
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
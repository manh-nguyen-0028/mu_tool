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

Func testAa()
	$checkAbc = False
	If Not $checkAbc Then
		writeLog("Check abc = " & $checkAbc) 
	EndIf

	$count = 0
	While Not $checkAbc
		writeLog("Check abc = " & $checkAbc)
		writeLog("Count = " & $count)
		$count += 1
		If $count == 5 Then $checkAbc = True
	WEnd
	;~ $charName = "GiamDocSo"
	;~ $charName = "xTramAnh"
	;~ $mainNo = getMainNoByChar($charName)
	;~ activeAndMoveWin($mainNo)
	;~ checkLvl400($mainNo)
	;~ Local $pTime = "2023/10/02 18:34:58"
	;~ Local $amount = 7

	;~ Local $addedTime = _DateAdd('h', $amount, $pTime)
	;~ Local $addedTime1 = _DateAdd('n', -20, $addedTime)

	;~ MsgBox($MB_OK, "Output Time", "Input Time: " & $pTime & @CRLF & "Output Time: " & $addedTime)
	;~ MsgBox($MB_OK, "Output Time", "Input Time: " & $pTime & @CRLF & "Output Time: " & $addedTime1)
	;~ $charInfoText = "Reset 889 lần xxmrgreo xxvxv"
	
	;~ $sResetCount = StringMid($charInfoText, 7, 10)
	;~ $charRsCount =StringSplit($sResetCount, ' ', 0)

	;~ writeLogMethodStart("testAa",@ScriptLineNumber & $charRsCount[0])
EndFunc

Func startAutoRs()
	; get array account need withdraw reset
	writeLogFile($logFile, "Start method: startAutoRs")

	Local $sFilePath = $outputPathRoot & "File_Log_AutoRS_.txt"
	$logFile = FileOpen($sFilePath, $FO_APPEND)
	writeLogMethodStart("startAutoRs",@ScriptLineNumber)
	writeLogFile($logFile, "Begin start auto reset !")

	$aAccountActiveRs = getActiveResetAccounts()
    
    If UBound($aAccountActiveRs) == 0 Then
        writeLogFile($logFile, "Khong co account nao active => Ket thuc chuong trinh!")
        FileClose($logFile)
        Return
    EndIf
    
	; Thuc hien close chorme neu co
    checkThenCloseChrome()
	; Thuc hien khoi tao webdriver
    $sSession = SetupChrome()
	; Dau tien, thuc hien logout account de tranh cache
    _WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
    secondWait(3)

	For $i = 0 To UBound($aAccountActiveRs) - 1
        processAccountReset($sSession, $aAccountActiveRs[$i], $logFile)
		; Sau khi check xong thi thuc hien logout account
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
	writeLogFile($logFile, "Start method: processReset with account: " & convertJsonToString($jAccountInfo))

	$username = getPropertyJson($jAccountInfo,"user_name")
	$password = getPropertyJson($jAccountInfo,"password")
	$charName = getPropertyJson($jAccountInfo,"char_name")
	$typeRs = getPropertyJson($jAccountInfo,"type_rs")
	$lvlMove = getPropertyJson($jAccountInfo,"lvl_move")
	$hourPerRs = getPropertyJson($jAccountInfo,"hour_per_reset")
	$resetOnline = getPropertyJson($jAccountInfo,"reset_online")
	$isBuff = getPropertyJson($jAccountInfo,"is_buff")
	$isMainCharacter = getPropertyJson($jAccountInfo,"is_main_character")
	$positionLeader = getPropertyJson($jAccountInfo,"position_leader")

	writeLogFile($logFile, "Begin handle process reset with account: " & $charName)

	; Login and check success
    If Not login($sSession, $username, $password) Then
        writeLogMethodEnd("Login fail. Terminate process reset", @ScriptLineNumber, $jAccountInfo)
        Return
    EndIf

	secondWait(5)

	Local $timeNow = getTimeNow()
	Local $sLogReset = getLogReset($sSession, $charName)
	Local $lastTimeRs = getTimeReset($sLogReset, 0)
	Local $rsCount = getRsCount($sLogReset)
	Local $nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
	If $timeNow < $nextTimeRs Then 
		logResetTime($timeNow, $nextTimeRs, $charName)
        updateJsonConfig($jsonPathRoot & $accountRsFileName, $charName, "last_time_reset", $lastTimeRs)
        writeLogMethodEnd("processReset", @ScriptLineNumber, $jAccountInfo)
        Return
	EndIf

	; Vào nhân vật kiểm tra lvl
	_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
	secondWait(5)

	; find lvl
	Local $nLvl = Number(getTextElement($sSession, findElement($sSession, "//span[@class='t-level']")))
    Local $lvlCanRs = calculateRequiredLevel($rsCount)

	writeLogFile($logFile, @ScriptLineNumber & " - Rs hien tai: " & $rsCount & " - Lvl can thiet de RS la: " & $lvlCanRs)
    
    If $nLvl < $lvlCanRs Then
        writeLogMethodEnd("Chua du lvl de rs: ", @ScriptLineNumber, $jAccountInfo)
        Return
    EndIf

	; Handle reset process
    handleResetProcess($sSession, $charName, $typeRs, $resetOnline, $isBuff, $jsonPathRoot, $accountRsFileName, $rsCount, $lvlMove, $positionLeader, $isMainCharacter)

	writeLogMethodEnd("End processReset",@ScriptLineNumber,$jAccountInfo)
EndFunc

#cs
Thay đổi nhân vật để reset.
Trước khi thay đổi nhân vật cần check xem đã đủ lvl reset hay chưa ( 400 ).
Nếu không đủ lvl rs thì thực hiện follow leader ( mục đích nếu bị bắn về thành ) và chờ 15p để check lại lvl
Nếu đủ thì thực hiện thay đổi nhân vật
#ce
Func changeChar($mainNo)
	writeLogFile($logFile, "Start method: changeChar with mainNo: " & $mainNo)

	sendKeyDelay("+h")
	secondWait(1)
	sendKeyDelay("{ESC}")
	secondWait(1)
	; Bam chon nhat vat khac
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.change_char.x"), _JSONGet($jsonPositionConfig,"button.change_char.y"))
	secondWait(7)
	; Check title 
	if activeAndMoveWin($mainNo) Then
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
	writeLogFile($logFile, "Start method: returnChar with mainNo: " & $mainNo)
	$checkActive = activeAndMoveWin($mainNo)
	secondWait(1)
	writeLogFile($logFile, "Bat dau chon nhan vat vao lai game ! Main No: " & $mainNo)
	While Not $checkActive
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.screen_mouse_move.x"), _JSONGet($jsonPositionConfig,"button.screen_mouse_move.y"))
		sendKeyDelay("{Enter}")
		$checkActive = activeAndMoveWin($mainNo)
	WEnd
	writeLogFile($logFile, "Vao lai game thanh cong ! Main No: " & $mainNo)
	secondWait(12)
EndFunc 

#cs
	Tim sport de luyen lvl len 20
#ce
Func goToSportLvl1($mainNo) 
	writeLogFile($logFile, "Start method: goToSportLvl1 with mainNo: " & $mainNo)
	; Enable Auto Home in 3s
	sendKeyDelay("{HOME}");
	secondWait(3)
	; Send Tab button
	writeLogFile($logFile, "Bat ban do !")
	Send("{Tab}")
	secondWait(2)
	; An nhan vat
	sendKeyDelay("+h")
	secondWait(1)
	writeLogFile($logFile, "Bat dau tim vi tri sport 1")
	; 392, 334
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.loren_sport1.x"), _JSONGet($jsonPositionConfig,"button.loren_sport1.y"))
	secondWait(1)
	Send("{Tab}")
	writeLogFile($logFile, "Tat ban do !")
	secondWait(2)
	WinSetState($mainNo,"",@SW_MINIMIZE)
EndFunc

Func checkLvlInWeb($rsCount,$charName, $lvlStopCheck, $timeDelay)
	writeLogFile($logFile, "Start method: checkLvlInWeb with charName: " & $charName & ", lvlStopCheck: " & $lvlStopCheck)
	; Vào nhân vật kiểm tra lvl
	_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
	secondWait(5)
	$mainNo = getMainNoByChar($charName)
	; find lvl
	$sElement = findElement($sSession, "//span[@class='t-level']") 
	$tLvl = getTextElement($sSession, $sElement)
	$nLvl = Number($tLvl)
	$tmpLvl = 0
	$timeCheck = 0

	While $nLvl < $lvlStopCheck
		$timeCheck += 1
		If $nLvl <> $tmpLvl Or $nLvl < 20 Then 
			$tmpLvl = $nLvl
		Else
			activeAndMoveWin($mainNo)
			$checkAutoHome = checkActiveAutoHome()
			writeLogFile($logFile, @ScriptLineNumber & " $checkAutoHome = " &$checkAutoHome)
			If Not $checkAutoHome Then
				If activeAndMoveWin($mainNo) Then 
					writeLogFile($logFile, @ScriptLineNumber & " Vao map stadium ")
					goMapArena($rsCount)
				EndIf
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
		
		_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
		secondWait(5)
		; find lvl
		$sElement = findElement($sSession, "//span[@class='t-level']") 
		$tLvl = getTextElement($sSession, $sElement)
		$nLvl = Number($tLvl)
		
		; Truong hop $lvlStopCheck= 20 va so lan check ma = 5 thi thuc hien move = web
		If $timeCheck == 5 And $lvlStopCheck == 20 Then
			; Dien toa do X
			$sElement = _WD_GetElementByName($sSession,"tx")
			_WD_ElementAction($sSession, $sElement, 'value','xxx')
			_WD_ElementAction($sSession, $sElement, 'CLEAR')
			secondWait(2)
			_WD_ElementAction($sSession, $sElement, 'value',"23")
			; Dien toa do Y
			$sElement = _WD_GetElementByName($sSession,"ty")
			_WD_ElementAction($sSession, $sElement, 'value','xxx')
			_WD_ElementAction($sSession, $sElement, 'CLEAR')
			secondWait(2)
			_WD_ElementAction($sSession, $sElement, 'value',"23")
			; Bam button chay ( submit )
			$sElement = findElement($sSession, "//input[@type='submit']")
			clickElement($sSession, $sElement)
		EndIf

		; Neu check qua 15 lan thi thoat loop la bat buoc
		If $timeCheck >= 15 Then
			writeLogFile($logFile, "Da qua so lan duoc phep check lvl: " & $timeCheck)
			;~ MsgBox(0, "Thông báo", "Thoát khỏi vòng lặp khi i = 5")
			ExitLoop
		EndIf
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
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.x"), _JSONGet($jsonPositionConfig,"button.event_icon.y"))
	; Click map lvl
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_x"), _JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_y"))
	secondWait(3)
	; Go to center
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_center_x"), _JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_center_y"))
	secondWait(2)
	; Enable Auto Home
	sendKeyDelay("{HOME}");
	; Doi 16p cho het event
	;~ minuteWait(16)
EndFunc

Func goMapArena($rsCount)
	sendKeyDelay("{Enter}")
	sendKeyDelay("{Enter}")
	writeLogFile($logFile, "Bat dau map arena ! ")
	; Click event icon then go arena map
	clickEventIconThenGoStadium()
	; Trong truong hop rs count < 30 thi chi toi sport 1 thoi, <50 thi ra port 2, nguoc lai thi ra sport 3
	$sportArenaNo = 3
	If ($rsCount < 30) Then
		$sportArenaNo = 1
	ElseIf ($rsCount < 50) Then
		$sportArenaNo = 2
	EndIf
	; Go to sport
	goSportStadium($sportArenaNo)
EndFunc

Func goSportStadium($sportNo = 1) 
	Send("{Tab}")
	secondWait(2)
	; sport chia lam tung cap do tu de toi kho, tuy muc dich su dung
	$sportArenaX = 269 
	$sportArenaY = 329
	If ($sportNo == 1) Then
		$sportArenaX = _JSONGet($jsonPositionConfig,"button.sport_arena_1.x")
		$sportArenaY = _JSONGet($jsonPositionConfig,"button.sport_arena_1.y")
	ElseIf ($sportNo == 2) Then
		$sportArenaX = _JSONGet($jsonPositionConfig,"button.sport_arena_2.x")
		$sportArenaY = _JSONGet($jsonPositionConfig,"button.sport_arena_2.y")
	ElseIf ($sportNo == 3) Then
		$sportArenaX = _JSONGet($jsonPositionConfig,"button.sport_arena_3.x")
		$sportArenaY = _JSONGet($jsonPositionConfig,"button.sport_arena_3.y")
	EndIf
	_MU_MouseClick_Delay($sportArenaX, $sportArenaY)
	Send("{Tab}")
	secondWait(2)
EndFunc

Func getActiveResetAccounts()
    Local $jAccountWithdrawRs = getJsonFromFile($jsonPathRoot & $accountRsFileName)
    Local $aActiveAccounts[0]
    
    For $i = 0 To UBound($jAccountWithdrawRs) - 1
        If getPropertyJson($jAccountWithdrawRs[$i], "active") And getPropertyJson($jAccountWithdrawRs[$i], "type") == "reset" Then
            ReDim $aActiveAccounts[UBound($aActiveAccounts) + 1]
            $aActiveAccounts[UBound($aActiveAccounts) - 1] = $jAccountWithdrawRs[$i]
        EndIf
    Next
	writeLogFile($logFile, "Tổng số account active: " & UBound($aActiveAccounts))
    
    Return $aActiveAccounts
EndFunc

Func processAccountReset($sSession, $account, $logFile)
    writeLogFile($logFile, "Dang xu ly voi account => " & convertJsonToString($account))
    
    Local $username = getPropertyJson($account, "user_name")
    Local $password = getPropertyJson($account, "password")
    Local $charName = getPropertyJson($account, "char_name")
    Local $lastTimeRs = getPropertyJson($account, "last_time_reset")
    Local $limit = getPropertyJson($account, "limit")
    Local $timeRs = getPropertyJson($account, "time_rs")
    Local $hourPerRs = getPropertyJson($account, "hour_per_reset")
    Local $resetOnline = getPropertyJson($account, "reset_online")
    
    Local $nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
    Local $mainNo = getMainNoByChar($charName)
    
    If getTimeNow() < $nextTimeRs Then
        writeLogFile($logFile, "Chua den thoi gian reset. Thoi gian gan nhat co the reset: " & $nextTimeRs)
        Return
    EndIf
    
    If $timeRs >= $limit Then
        writeLogFile($logFile, "Vuot qua so lan rs cho phep trong ngay. So lan RS hien tai => " & $timeRs)
        Return
    EndIf
    
    ; Neu la rs online thi can thuc hien active main
	If Not $resetOnline Then
        If Not activeAndMoveWin($mainNo) And Not switchOtherChar($charName) Then
            Return
        EndIf
    EndIf
    
    processReset($account)
EndFunc

Func logResetTime($timeNow, $nextTimeRs, $charName)
	writeLogFile($logFile, "Start method: logResetTime with timeNow: " & $timeNow & ", nextTimeRs: " & $nextTimeRs & ", charName: " & $charName)
    writeLogFile($logFile, "Chua den thoi gian reset. getTimeNow() < $nextTimeRs = " & $timeNow < $nextTimeRs)
    writeLogFile($logFile, "Thoi gian hien tai: " & $timeNow)
    writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
EndFunc

Func updateJsonConfig($filePath, $charName, $property, $value)
	writeLogFile($logFile, "Start method: updateJsonConfig with filePath: " & $filePath & ", charName: " & $charName & ", property: " & $property & ", value: " & $value)
    Local $jsonRsGame = getJsonFromFile($filePath)
    For $i = 0 To UBound($jsonRsGame) - 1
        If getPropertyJson($jsonRsGame[$i], "char_name") == $charName Then
            _JSONSet($value, $jsonRsGame[$i], $property)
            setJsonToFileFormat($filePath, $jsonRsGame)
            Return
        EndIf
    Next
EndFunc

Func calculateRequiredLevel($rsCount)
	writeLogFile($logFile, "Start method: calculateRequiredLevel with rsCount: " & $rsCount)
    If $rsCount < 50 Then
        Local $lvlCanRs = 200 + ($rsCount * 5)
        If $lvlCanRs > 400 Then $lvlCanRs = 400
        Return $lvlCanRs
    EndIf
    Return 400
EndFunc

Func handleResetProcess($sSession, $charName, $typeRs, $resetOnline, $isBuff, $jsonPathRoot, $accountRsFileName, $rsCount, $lvlMove, $positionLeader, $isMainCharacter)
	writeLogFile($logFile, "Start method: handleResetProcess with charName: " & $charName & ", typeRs: " & $typeRs & ", resetOnline: " & $resetOnline & ", isBuff: " & $isBuff & ", rsCount: " & $rsCount & ", lvlMove: " & $lvlMove & ", positionLeader: " & $positionLeader & ", isMainCharacter: " & $isMainCharacter)
	Local $mainNo = getMainNoByChar($charName)
	; tìm thấy lvl la coi nhu da online roi, khong can check lai $activeWin vi da thuc hien o buoc truoc
	If Not $resetOnline Then
		activeAndMoveWin($mainNo)
		; Click bỏ hết các bảng thông báo
		handelWhenFinshDevilEvent()
		changeChar($mainNo)
	EndIf
	; 2. Reset in web
	_WD_Navigate($sSession, $baseMuUrl & "web/char/reset.shtml?char=" & $charName)
	secondWait(3)
	; Click radio rs vip
	_WD_ExecuteScript($sSession, "$(""input[name='rstype']"")["&$typeRs&"].click()")
	secondWait(2)
	If $resetOnline Then
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
			If $resetInDay == 1 And $isBuff Then
				handleBuff($sSession, $charName, $logFile)
			EndIf
		EndIf
	Next

	; If reset online = true => withow handle in game
	If $resetOnline Then
        Return
    EndIf
	
	; 3. Return game
	returnChar($mainNo)
	; 4. Go to sport
	goToSportLvl1($mainNo)
	; 5. Check lvl in web
	$lvlStopCheck = 20
	checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
	; 6. Active main
	activeAndMoveWin($mainNo)
	; 7. Go map lvl
	If $resetInDay <=3 Then 
		goMapLvl()
	Else
		goMapArena($rsCount)
	EndIf
	; 8. Check lvl in web
	writeLogFile($logFile, @ScriptLineNumber & " Bat dau check lvl tren web !")
	$lvlStopCheck = Number($lvlMove)
	checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
	activeAndMoveWin($mainNo)
	writeLogFile($logFile, @ScriptLineNumber & " Ket thuc check lvl tren web !")
	; Move other map
	moveOtherMap()
	secondWait(8)
	; 9. Follow leader
	If IsNumber($positionLeader) Then 
		$positionLeader = Number($positionLeader)
	Else
		$positionLeader = 1
	EndIf
	_MU_followLeader($positionLeader)
	; 10. Wait in 1 min
	minuteWait(1)

	If Not $isMainCharacter Then
        handleNonMainCharacter($charName, $mainNo)
    EndIf

	writeLogFile($logFile, "mainNoMinisize: " & $mainNo)
	minisizeMain($mainNo)
EndFunc

Func handleBuff($sSession, $charName, $logFile)
	writeLogFile($logFile, "Start method: handleBuff with charName: " & $charName)
    writeLogFile($logFile, "Begin buff char: " & $charName)
    _WD_Navigate($sSession, $baseMuUrl & "web/char/charbuff.shtml")
    secondWait(5)
    _WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
    secondWait(2)
    closeDiaglogConfim($sSession)
EndFunc

Func handleNonMainCharacter($charName, ByRef $mainNo)
	writeLogFile($logFile, "Start method: handleNonMainCharacter with charName: " & $charName & ", mainNo: " & $mainNo)
    writeLogFile($logFile, "Xu ly truong hop main khong phai la main chinh")
    Local $otherChar = getOtherChar($charName)
    If $otherChar <> "" Then
        If switchOtherChar($otherChar) Then
            $mainNo = getMainNoByChar($otherChar)
        EndIf
    EndIf
EndFunc
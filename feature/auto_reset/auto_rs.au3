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
Local $haveIP = False

;~ testAa()

Func testAa()
	;~ $charName = "GiamDocSo"
	$charName = "xTramAnh"
	$mainNo = getMainNoByChar($charName)
	activeAndMoveWin($mainNo)
	checkLvl400($mainNo)
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
	$aRsConfig = getJsonFromFile($jsonPathRoot & $accountRsFileName)
	;~ writeLogFile($logFile, "aRsConfig: " & convertJsonToString($aRsConfig))
	$aRsUpdateInfo = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
	;~ writeLogFile($logFile, "aRsUpdateInfo: " & convertJsonToString($aRsUpdateInfo))
	$jAccountWithdrawRs = mergeInfoAccountRs($aRsConfig, $aRsUpdateInfo)

	For $i = 0 To UBound($jAccountWithdrawRs) - 1
		writeLogFile($logFile, "jAccountWithdrawRs - " & $i & " : " & convertJsonToString($jAccountWithdrawRs[$i]))
		$charName = getPropertyJson($jAccountWithdrawRs[$i],"char_name")
		writeLogFile($logFile, "jAccountWithdrawRs - charName: " & $charName)
	Next
	
EndFunc

Func startAutoRs()
	; get array account need withdraw reset
	Local $sFilePath = $outputPathRoot & "File_Log_AutoRS_.txt"
	$logFile = FileOpen($sFilePath, $FO_APPEND)
	writeLogMethodStart("startAutoRs",@ScriptLineNumber)
	writeLogFile($logFile, "Begin start auto reset !")
	ReDim $aAccountActiveRs[0]
	$aRsConfig = getJsonFromFile($jsonPathRoot & $accountRsFileName)
	$aRsUpdateInfo = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
	$jAccountWithdrawRs = mergeInfoAccountRs($aRsConfig, $aRsUpdateInfo)
	For $i =0 To UBound($jAccountWithdrawRs) - 1
		$active = getPropertyJson($jAccountWithdrawRs[$i], "active")
		$type = getPropertyJson($jAccountWithdrawRs[$i], "type")
		If $active And "reset" == $type Then
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
		; Logout account cho chac, nhieu luc se bi cache account cu
		_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
		secondWait(5)
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
		$resetOnline = getPropertyJson($aAccountActiveRs[$i],"reset_online")
		$typeRs = getPropertyJson($aAccountActiveRs[$i],"type_rs")
		
		$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
		$mainNo = getMainNoByChar($charName)
		$currentTime = getTimeNow()
		$lastTimeRsAdd30 = _DateAdd('n', 30, $lastTimeRs)
		$lastTimeRsAdd60 = _DateAdd('n', 60, $lastTimeRs)
		
		If getTimeNow() < $nextTimeRs Then 
			writeLogFile($logFile, "Chua den thoi gian reset. " & @CRLF & "Thoi gian gan nhat co the reset: " & $nextTimeRs)
			ContinueLoop
		EndIf

		; Truong hop type rs = 0 (Rs zen) thi thoi gian rs phai > 30
		If $typeRs == 0 And $currentTime < $lastTimeRsAdd30 Then 
			writeLogFile($logFile, "Chua toi thoi gian duoc rs voi type Zen: " & $typeRs & @CRLF & " - Thoi gian gan nhat co the reset voi type zen: " & $lastTimeRsAdd30)
			ContinueLoop
		EndIf

		; Truong hop type rs = 2 (RS PO) thi thoi gian rs phai > 60
		If $typeRs == 2 And $currentTime < $lastTimeRsAdd60 Then 
			writeLogFile($logFile, "Chua toi thoi gian duoc rs voi type PO: " & $typeRs  & @CRLF & " - Thoi gian gan nhat co the reset voi type PO: " & $lastTimeRsAdd60)
			ContinueLoop
		EndIf

		; Neu vuot qua so lan rs duoc phep trong ngay
		If $timeRs >= $limit Then 
			writeLogFile($logFile, "Vuot qua so lan rs duoc phep trong ngay: " & $timeRs & @CRLF & " - So lan duoc phep: " & $limit)
			ContinueLoop
		EndIf

		; Neu la rs online thi can thuc hien active main
		If Not $resetOnline Then
			; Begin reset
			$activeMain = activeAndMoveWin($mainNo)

			; Truong hop main hien tai khong duoc active, active main khac
			If Not $activeMain Then $activeMain = switchOtherChar($charName)
			If $activeMain Then 
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
	$positionLeader = getPropertyJson($jAccountInfo,"position_leader")
	$activeMoveBeforRs = getPropertyJson($jAccountInfo,"active_move_rs")
	$postionMoveX = getPropertyJson($jAccountInfo,"postion_move_x")
	$postionMoveY = getPropertyJson($jAccountInfo,"postion_move_y")

	writeLogFile($logFile, "Begin handle process reset with account: " & $charName)
	$isLoginSuccess = login($sSession, $username, $password)
	secondWait(5)
	If $isLoginSuccess Then
		; Check IP
		$haveIP = checkIP($sSession)
		$timeNow = getTimeNow()
		$sLogReset = getLogReset($sSession, $charName)
		$lastTimeRs = getTimeReset($sLogReset, 0)
		$rsCount = getRsCount($sLogReset)
		$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
		If $timeNow < $nextTimeRs Then 
			writeLogFile($logFile, "Chua den thoi gian reset.")
			writeLogFile($logFile, "Thoi gian gan nhat co the reset: " & $nextTimeRs)
			$jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
				For $i =0 To UBound($jsonRsGame) - 1
					$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
					If $charNameTmp == $charName Then
						_JSONSet($lastTimeRs, $jsonRsGame[$i], "last_time_reset")
						setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
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
			$lvlCanRs = 200 + ($rsCount * 5)
			If $lvlCanRs > 400 Then $lvlCanRs = 400
		EndIf
		writeLogFile($logFile, @ScriptLineNumber & " : Rs hien tai: " & $rsCount & " - Lvl can thiet de RS la: " & $lvlCanRs)
		$mainNo = getMainNoByChar($charName)
		If $nLvl >= $lvlCanRs Then 
			; tìm thấy lvl la coi nhu da online roi, khong can check lai $activeWin vi da thuc hien o buoc truoc
			If Not $resetOnline Then
				; Active main no 
				$activeWin = activeAndMoveWin($mainNo)
				If Not $activeWin Then $activeWin = switchOtherChar($charName)
				; Click bỏ hết các bảng thông báo
				If $activeWin Then
					handelWhenFinshDevilEvent()
					secondWait(3)
					; 1. Change Char
					changeChar($mainNo)
				EndIf
			Else
				; Neu co active move va co toa do thi thuc hien move
				If $activeMoveBeforRs And $postionMoveX <> "" And $postionMoveY <> "" Then
					moveToPostionInWeb($sSession, $charName, $postionMoveX, $postionMoveY)
					writeLogFile($logFile, "Da thuc hien move truoc khi reset den toa do X: " & $postionMoveX & " - Y: " & $postionMoveY)
				EndIf
			EndIf
			; 2. Reset in web
			_WD_Navigate($sSession, $baseMuUrl & "web/char/reset.shtml?char=" & $charName)
			secondWait(5)
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
			$jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
			For $i = 0 To UBound($jsonRsGame) - 1
				$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
				If $charNameTmp == $charName Then
					$sLogReset = getLogReset($sSession, $charName)
					$resetInDay = getRsInDay($sLogReset)
					_JSONSet($resetInDay, $jsonRsGame[$i], "time_rs")
					; last time rs
					$sTimeReset = getTimeReset($sLogReset,0)
					_JSONSet($sTimeReset, $jsonRsGame[$i], "last_time_reset")
					setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
					If $resetInDay == 1 And $isBuff Then
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
			If Not $resetOnline Then
				; 3. Return game
				returnChar($mainNo)
				; 4. Go to sport
				goToSportLvl1($mainNo)
				; 5. Check lvl in web
				$lvlStopCheck = 20
				$lvlCheckInWeb = checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
				; 6. Active main
				activeAndMoveWin($mainNo)
				If $lvlCheckInWeb >= 20 Then
					; 7. Go map lvl
					If $resetInDay <= 3 Then 
						writeLogFile($logFile, "So lan rs trong ngay: " & $resetInDay)
						goMapLvl()
					Else
						goMapArena($rsCount)
					EndIf

					; 8. Check lvl in web
					$lvlStopCheck = Number($lvlMove)
					checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
					activeAndMoveWin($mainNo)

					; Move other map
					moveOtherMap()
					secondWait(6)

					; 9. Follow leader
					If IsNumber($positionLeader) Then 
						$positionLeader = Number($positionLeader)
					Else
						$positionLeader = 1
					EndIf
					_MU_followLeader($positionLeader)
					; 10. Wait in 1 min
					minuteWait(1)
				EndIf
			EndIf

			$mainNoMinisize = $mainNo

			If Not $isMainCharacter Then
				writeLogFile($logFile, "Xu ly truong hop main khong phai la main chinh")
				$otherChar = getOtherChar($charName)
				If $otherChar <> "" Then 
					$resultWwithChar = switchOtherChar($otherChar)
					If $resultWwithChar Then $mainNoMinisize = getMainNoByChar($otherChar)
				EndIf
				writeLogFile($logFile, "mainNoMinisize: " & $mainNoMinisize)
			EndIf

			If Not $resetOnline Then
				; 10. minisize main 
				minisizeMain($mainNoMinisize)
			EndIf
			
			; 11. Logout account
			_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
			secondWait(5)
			;~ EndIf
		EndIf
		If Not $resetOnline Then minisizeMain($mainNo)
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
	if $checkActive Then
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
	While Not $checkActive
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.screen_mouse_move.x"), _JSONGet($jsonPositionConfig,"button.screen_mouse_move.y"))
		sendKeyEnter()
		$checkActive = activeAndMoveWin($mainNo)
	WEnd
	writeLogFile($logFile, "Vao lai game thanh cong ! Main No: " & $mainNo)
	secondWait(12)
EndFunc 

#cs
	Tim sport de luyen lvl len 20
#ce
Func goToSportLvl1($mainNo) 
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
	; Khi bat dau se xuat hien tai 182 - 128
	writeLogFile($logFile, "Bat dau tim vi tri sport 1")
	; 533, 338
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.loren_sport1.x"), _JSONGet($jsonPositionConfig,"button.loren_sport1.y"))
	secondWait(1)
	Send("{Tab}")
	writeLogFile($logFile, "Tat ban do !")
	secondWait(1)
	WinSetState($mainNo,"",@SW_MINIMIZE)
EndFunc

Func checkLvlInWeb($rsCount,$charName, $lvlStopCheck, $timeDelay)
	writeLogFile($logFile, "Bat dau check lvl tren web !" & " - Lvl stop check: " & $lvlStopCheck)
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

	While $nLvl < $lvlStopCheck And $timeCheck <= 50
		; Neu > 200 thi moi thuc hien ghi log
		If $nLvl > 200 Then writeLogFile($logFile, "Lvl hien tai: " & $nLvl & "- So lan da check: " & $timeCheck)

		$timeCheck += 1
		If $nLvl <> $tmpLvl Or $nLvl < 20 Then 
			$tmpLvl = $nLvl
		Else
			If activeAndMoveWin($mainNo) And Not checkActiveAutoHome() Then
				writeLogFile($logFile, "Auto Home not active !")
				goMapArena($rsCount)
			EndIf
		EndIf
		minisizeMain($mainNo)
		; Xu ly doi voi lvl check = 20; chi can doi 30s
		If $lvlStopCheck == 20 Then
			; Wait 30 sec then retry
			secondWait(35)
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
		If $timeCheck == 15 And $lvlStopCheck == 20 Then
			; Dien toa do X - vi tri cua sport 1 
			;~ 174, 65
			$positionX = 174
			$positionY = 65
			moveToPostionInWeb($sSession, $charName, $positionX, $positionY)
		EndIf

		; Neu check qua 15 lan thi thoat loop la bat buoc
		;~ If $timeCheck >= 30 Then
		;~ 	writeLogFile($logFile, "Da qua so lan duoc phep check lvl: " & $timeCheck)
		;~ 	;~ MsgBox(0, "Thông báo", "Thoát khỏi vòng lặp khi i = 5")
		;~ 	ExitLoop
		;~ EndIf
	WEnd
	
	Return $nLvl
EndFunc

#cs
	Vao event Lvl 
#ce
Func goMapLvl()
	writeLogFile($logFile, "Bat dau map event lvl ! ")
	; Click event icon
	$eventIconX = _JSONGet($jsonPositionConfig,"button.event_icon.x")
	$eventIconY = _JSONGet($jsonPositionConfig,"button.event_icon.y")
	_MU_MouseClick_Delay($eventIconX, $eventIconY)
	
	; Click map lvl
	$mapLvlX = _JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_x")
	$mapLvlY = _JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_y")
	_MU_MouseClick_Delay($mapLvlX, $mapLvlY)
	secondWait(3)

	; Go to center
	$mapLvlCenterX = _JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_center_x")
	$mapLvlCenterY = _JSONGet($jsonPositionConfig,"button.event_icon.map_lvl_center_y")
	_MU_MouseClick_Delay($mapLvlCenterX, $mapLvlCenterY)
	secondWait(2)

	; Enable Auto Home
	sendKeyDelay("{HOME}");
	; Doi 16p cho het event
	;~ minuteWait(16)
EndFunc

Func goMapArena($rsCount)
	sendKeyEnter()
	sendKeyEnter()
	writeLogFile($logFile, "Bat dau map event arena ! ")
	; Click event icon then go arena map
	clickEventIcon()
	clickEventStadium()
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
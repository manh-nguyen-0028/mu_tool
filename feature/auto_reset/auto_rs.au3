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

Func startAutoRs()
	Local $aAccountActive[0], $aAccountWithDraw[0], $aAccountActiveRs[0]
	; get array account need withdraw reset
	Local $sFilePath = $outputPathRoot & "File_Log_AutoRS_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	writeLogMethodStart("startAutoRs",@ScriptLineNumber)
	writeLogFile($logFile, "Begin start auto reset !", @ScriptLineNumber)
	$aRsConfig = getJsonFromFile($jsonPathRoot & $accountRsFileName)
	$aRsUpdateInfo = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
	$jAccMerge = mergeInfoAccountRs($aRsConfig, $aRsUpdateInfo)

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
		; Logout account cho chac, nhieu luc se bi cache account cu
		logout($sSession)
	EndIf

	For $i = 0 To UBound($aAccValidate) - 1
		$type = getPropertyJson($aAccValidate[$i], "type")
		writeLogFile($logFile, "type rs = " & $type & "---" & "Dang xu ly voi account => " & convertJsonToString($aAccValidate[$i]))

		If "withdraw" == $type Then
			withDrawRs($aAccValidate[$i])
		Else
			reset($aAccValidate[$i])
		EndIf

		logout($sSession)
	Next

	writeLogMethodEnd("startAutoRs",@ScriptLineNumber)

	FileClose($logFile)

	; Close webdriver neu thuc hien xong 
	If $sSession Then 
		_WD_DeleteSession($sSession)
		_WD_Shutdown()
	EndIf
	
EndFunc

Func reset($jAccountInfo)
	writeLogMethodStart("resetRs",@ScriptLineNumber,$jAccountInfo)
	$charName = getPropertyJson($jAccountInfo,"char_name")
	$resetOnline = getPropertyJson($jAccountInfo,"reset_online")
	$mainNo = getMainNoByChar($charName)
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
	writeLogMethodEnd("resetRs",@ScriptLineNumber,$jAccountInfo)
EndFunc

Func withDrawRs($jAccountInfo)
	writeLogMethodStart("processWithDrawReset",@ScriptLineNumber,$jAccountInfo)
	$username = getPropertyJson($jAccountInfo,"user_name")
	$password = getPropertyJson($jAccountInfo,"password")
	$charName = getPropertyJson($jAccountInfo,"char_name")
	$hourPerRs = getPropertyJson($jAccountInfo,"hour_per_reset")
	$resetOnline = getPropertyJson($jAccountInfo,"reset_online")
	$isMainCharacter = getPropertyJson($jAccountInfo,"is_main_character")
	$mainCharName = getPropertyJson($jAccountInfo,"main_char_name")

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
			$jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
			For $i =0 To UBound($jsonRsGame) - 1
				$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
				If $charNameTmp == $charName Then
					_JSONSet($lastTimeRs, $jsonRsGame[$i], "last_time_reset")
					setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
				EndIf
			Next
			Return False
		Else
			writeLogFile($logFile, "Co IP hop le, tiep tuc xu ly !")
			$timeNow = getTimeNow()
			$sLogReset = getLogReset($sSession, $charName)
			$lastTimeRs = getTimeReset($sLogReset,0)
			$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
			If $timeNow < $nextTimeRs Then 
				writeLogFile($logFile, "Chua den thoi gian reset. getTimeNow() < $nextTimeRs = " & $timeNow < $nextTimeRs)
				writeLogFile($logFile, "Thoi gian hien tai: " & $timeNow)
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

			; withraw reset
			$errorIp = _Demo_NavigateCheckBanner($sSession,combineUrl("web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char=" & $charName))
			secondWait(5)
			writeLogFile($logFile, "$errorIp: " & $errorIp)

			If $errorIp == $_WD_ERROR_Timeout Then
				; Thuc hien set lai vao file de khong thuc hien rs nua
				;~ setRsLogByAccountProperty($accountInfo,"is_have_ip", False)
				findAndClick($sSession, "//button[@type='submit']") 
				findAndClick($sSession, "//button[@class='swal2-confirm swal2-styled']") 
				writeLogFile($logFile, "IP khong chinh chu khong the RS")
			Else
				findAndClick($sSession, "//button[@type='submit']") 
				findAndClick($sSession, "//button[@class='swal2-confirm swal2-styled']") 
				writeLogFile($logFile, "Rut reset thanh cong !")
				$jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
				For $i = 0 To UBound($jsonRsGame) - 1
					$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
					If $charNameTmp == $charName Then
						$sLogReset = getLogReset($sSession, $charName)
						$resetInDay = getRsInDay($sLogReset)
						_JSONSet($resetInDay, $jsonRsGame[$i], "time_rs")
						; last time rs
						$sTimeReset = getTimeReset($sLogReset,0)
						; Trong truong hop reset khong thanh cong ($sTimeReset == $lastTimeRs) thi thuc hien set thoi gian thanh thoi gian hien tai
						If $sTimeReset == $lastTimeRs Then
							$timeNow = getTimeNow()
							$sTimeReset = _DateAdd('n', 30, $timeNow)
							writeLogFile($logFile, "$sTimeReset == $lastTimeRs, set thanh thoi gian hien tai: " & $sTimeReset)
						EndIf
						_JSONSet($sTimeReset, $jsonRsGame[$i], "last_time_reset")
						setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
					EndIf
				Next
				; deu da rs thanh cong thu thuc hien xem co phai rs online khong, neu ko thi phai thuc hien thay doi nhan vat
				If Not $resetOnline Then
					$mainNo = getMainNoByChar($charName)
					$activeWin = activeAndMoveWin($mainNo)
					If Not $activeWin Then $activeWin = switchOtherChar($charName)
					; Click bỏ hết các bảng thông báo
					If $activeWin Then
						handelWhenFinshDevilEvent()
						secondWait(3)
						; 1. Change Char Tu v1.0.15 bo change vi khong cong dc diem nv
						changeChar($mainNo)
						; Thuc hien change server
						secondWait(3)
						returnChar($mainNo)
						secondWait(3)
						; Neu khong phải main chinh thi thuc hien switch ve main chinh
						$mainNoMinisize = $mainNo
						If Not $isMainCharacter Then
							writeLogFile($logFile, "Xu ly truong hop main khong phai la main chinh")
							$otherChar = $mainCharName
							If $otherChar <> "" Then 
								$resultWwithChar = switchOtherChar($otherChar)
								If $resultWwithChar Then $mainNoMinisize = getMainNoByChar($otherChar)
							EndIf
							writeLogFile($logFile, "mainNoMinisize: " & $mainNoMinisize)
						EndIf
						minisizeMain($mainNoMinisize)
					EndIf
				EndIf
			EndIf
		EndIf
	Else
		writeLogFile($logFile, "Dang nhap that bai voi account: " & $charName)
		Return False
	EndIf
	writeLogMethodEnd("processWithDrawReset",@ScriptLineNumber,$jAccountInfo)
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
	$mainCharName = getPropertyJson($jAccountInfo,"main_char_name")
	$positionLeader = getPropertyJson($jAccountInfo,"position_leader")
	$activeEndKey = getPropertyJson($jAccountInfo,"active_end_key")
	$needCheckAutoZ = getPropertyJson($jAccountInfo,"need_check_auto_z")
	$activeMoveBeforRs = getPropertyJson($jAccountInfo,"active_move_rs")
	$postionMoveX = getPropertyJson($jAccountInfo,"postion_move_x")
	$postionMoveY = getPropertyJson($jAccountInfo,"postion_move_y")

	writeLogFile($logFile, "Begin handle process reset with account: " & $charName)
	$isLoginSuccess = login($sSession, $username, $password)
	secondWait(5)
	If $isLoginSuccess Then
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
			$moveInWebSuccess = True
			; tìm thấy lvl la coi nhu da online roi, khong can check lai $activeWin vi da thuc hien o buoc truoc
			If Not $resetOnline Then
				; Active main no 
				$activeWin = activeAndMoveWin($mainNo)
				If Not $activeWin Then $activeWin = switchOtherChar($charName)
				; Click bỏ hết các bảng thông báo
				If $activeWin Then
					handelWhenFinshDevilEvent()
					secondWait(3)
					; 1. Change Char Tu v1.0.15 bo change vi khong cong dc diem nv
					;~ changeChar($mainNo)
					; Thuc hien change server
					changeServer($mainNo)
				EndIf
			Else
				; Thuc hien check autoZ tren web
				If $needCheckAutoZ Then
					$resultCheck = checkAutoZInWeb($sSession)
					If Not $resultCheck Then
						writeLogFile($logFile, "Auto Z khong duoc kich hoat tren web, kich hoat lai !")
						; Thuc hien activate auto Z
						; Neu co toa do thi thuc hien move
						If $postionMoveX <> "" And $postionMoveY <> "" Then
							$checkMove = moveToPostionInWeb($sSession, $charName, $postionMoveX, $postionMoveY)
							If $checkMove Then 
								writeLogFile($logFile, "Da thuc hien move truoc khi reset den toa do X: " & $postionMoveX & " - Y: " & $postionMoveY)
								minuteWait(2)
							Else
								$moveInWebSuccess = False
								writeLogFile($logFile, "Khong the thuc hien move den toa do X: " & $postionMoveX & " - Y: " & $postionMoveY)
								; Neu khong the move thi thuc hien activate auto Z luon
							EndIf
						EndIf
					Else
						writeLogFile($logFile, "Auto Z da duoc kich hoat tren web. Khong can thuc hien move nua!")
					EndIf
				EndIf
			EndIf
			; 2. Reset in web
			_WD_Navigate($sSession, $baseMuUrl & "web/char/reset.shtml?char=" & $charName)
			secondWait(5)
			If $resetOnline Then
				; Click radio online
				_WD_ExecuteScript($sSession, "$(""input[name='rsonline']"").click()")
				secondWait(2)
			EndIf
			; Click radio rs vip
			_WD_ExecuteScript($sSession, "$(""input[name='rstype']"")["&$typeRs&"].click()")
			secondWait(2)
			; Neu khong move dc tren web thi bo qua buoc nay
			If $moveInWebSuccess Then
				; Click submit
				writeLogFile($logFile, "$moveInWebSuccess = True. Thuc hien click submit reset")
				_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
				secondWait(2)
			EndIf

			; Trong truong hop khong phai rs online = true thi moi thuc hien check add point
			If Not $resetOnline Then
				; Click submit
				_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
				secondWait(2)
				; Vao trang add point thuc hien lai 1 lan nua cho chac
				;~ https://hn.mugamethuvn.info/web/char/addpoint.shtml
				_WD_Navigate($sSession, $baseMuUrl & "web/char/char/addpoint.shtml")
				secondWait(5)
				; Click submit add point
				_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
				secondWait(2)
				; Thuc hien vao lao game
				; 3. Return game. Bay gio phai thuc hien 2 buoc. 1 chon lai sv, 2 -> chon lai nhan vat
				returnServer()
				returnChar($mainNo)
				; 3.1. Check xem cua so enter co ton tai khong
				firstActionAfterRs()
				; Sau do thuc hien send key end de kep chuot, neu $activeEndKey = true
				If $activeEndKey Then sendKeyEnd()
				; minisize main
				minisizeMain($mainNo)
			EndIf

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
					; Truong hop $sTimeReset = 0 thi set thanh ngay gio hien tai
					If $sTimeReset = 0 Then
						$sTimeReset = getTimeNow()
						writeLogFile($logFile, "Khong tim thay last time reset, set thanh thoi gian hien tai: " & $sTimeReset)
					EndIf
					
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
				; 5. Check lvl in web
				$lvlStopCheck = 20
				secondWait(30)
				; Kiem tra viec tang lvl tren web, neu van bang 1 thi thuc hien activate game va thuc hien laij firstActionAfterRs
				$lvlCheckInWeb = checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
				If $lvlCheckInWeb == 1 Then 
					; Activate game
					activeAndMoveWin($mainNo)
					secondWait(2)
					; Bam enter 1 lan nua de thoat bang thong bao
					sendKeyEnter()
					; Thuc hien first action
					firstActionAfterRs()
					; Cho tiep 30s
					secondWait(30)
				EndIf
				; Neu van bang 1 thi thuc hien di chuyen bang web
				$lvlCheckInWeb = checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
				; 5.1 Truong hop ma khong thay tang lvl thi thuc hien di chuyen bang web
				If $lvlCheckInWeb < 20 Then
					writeLogFile($logFile, "Khong thay tang lvl! Lvl hien tai: " & $lvlCheckInWeb)
					writeLogFile($logFile, "Thuc hien chuyen map bang web !")
					$moveLorenX = 220
					$moveLorenY = 144
					moveToPostionInWeb($sSession, $charName, $moveLorenX, $moveLorenY)
					writeLogFile($logFile, "Da thuc hien move truoc khi reset den toa do X: " & $postionMoveX & " - Y: " & $postionMoveY)
					; Doi 50s
					minuteWait(2)
					; Thuc hien check lai lvl
					$lvlCheckInWeb = checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
				Else
					writeLogFile($logFile, "Lvl van tang theo dung quy trinh! Lvl hien tai: " & $lvlCheckInWeb)
				EndIf
				
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
					moveOtherMap($charName)

					; 9. Follow leader
					If IsNumber($positionLeader) Then 
						$positionLeader = Number($positionLeader)
					Else
						$positionLeader = 1
					EndIf

					_MU_followLeader($positionLeader)
					; Neu co active move va co toa do thi thuc hien move
					If $activeMoveBeforRs And $postionMoveX <> "" And $postionMoveY <> "" Then
						moveToPostionInWeb($sSession, $charName, $postionMoveX, $postionMoveY)
						writeLogFile($logFile, "Da thuc hien move truoc khi reset den toa do X: " & $postionMoveX & " - Y: " & $postionMoveY)
					EndIf
					; 10. Wait in 1 min
					minuteWait(1)
				EndIf
			EndIf

			$mainNoMinisize = $mainNo

			If Not $isMainCharacter Then
				writeLogFile($logFile, "Xu ly truong hop main khong phai la main chinh")
				$otherChar = $mainCharName
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
			logout($sSession)
			;~ EndIf
		Else
			writeLogFile($logFile, "Khong du lvl de reset !")
			writeLogFile($logFile, "Lvl hien tai: " & $nLvl & " - Lvl can de reset: " & $lvlCanRs)
			writeLogFile($logFile, "Thuc hien update time reset ")
			; Cap nhat lai thoi gian reset de thuc hien check lai lan nua
			; Thuc hien add them 30p nua
			$timeNow = getTimeNow()
			$timeUpdateInFile = _DateAdd('n', 30, $timeNow)
			writeTimeRs($charName, $timeUpdateInFile)
			If Not $resetOnline Then
				;~ minisizeMain($mainNo)
				$mainNoMinisize = $mainNo
				$lvlStopCheck = $lvlCanRs
				$timeCheck = 0
				$activeWin = activeAndMoveWin($mainNo)
				If Not $activeWin Then $activeWin = switchOtherChar($charName)
				; Click bỏ hết các bảng thông báo
				If $activeWin Then
					sendKeyEnter()
					sendKeyEnter()
					goMapArena($rsCount)
					minuteWait(1)
					$lvlCheckInWeb = checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
					While $lvlCheckInWeb < $lvlStopCheck And $timeCheck <= 5
						writeLogFile($logFile, "Lvl tren web: " & $lvlCheckInWeb & " - Lvl stop check: " & $lvlStopCheck)
						$lvlCheckInWeb = checkLvlInWeb($rsCount, $charName, $lvlStopCheck, 1)
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
			EndIf
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
	sendKeyH()
	secondWait(1)
	sendKeyEsc()
	; Bam chon nhat vat khac
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.change_char.x"), _JSONGet($jsonPositionConfig,"button.change_char.y"))
	secondWait(3)
	; Check title 
	$checkActive = activeAndMoveWin($mainNo)
	if $checkActive Then
		sendKeyEsc()
		; Bam chon nhat vat khac
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.change_char.x"), _JSONGet($jsonPositionConfig,"button.change_char.y"))
		secondWait(3)
	EndIf
EndFunc 

#cs
	Dang nhap lai vao nhan vat
#ce
Func returnChar($mainNo) 
	$checkActive = activeAndMoveWin($mainNo)
	secondWait(1)
	writeLogFile($logFile, "Bat dau chon nhan vat vao lai game ! Main No: " & $mainNo)
	$timeCheck = 0
	While Not $checkActive And $timeCheck <= 5
		;~ _MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.screen_mouse_move.x"), _JSONGet($jsonPositionConfig,"button.screen_mouse_move.y"))
		; Active title game main
		If activeAndMoveWin($titleGameMain) Then
			; Bam chon nhat vat khac
			secondWait(1)
			sendKeyEnter()
			secondWait(2)
			$checkActive = activeAndMoveWin($mainNo)
			If $checkActive Then secondWait(3)
		EndIf
		$timeCheck += 1
	WEnd

	If $checkActive Then 
		writeLogFile($logFile, "Vao lai game thanh cong ! Main No: " & $mainNo)
	Else
		writeLogFile($logFile, "Vao lai game that bai ! Sau " & $timeCheck & " lan thu ! ")
	EndIf

EndFunc 

Func returnServer() 
	; thuc hien active title game main
	$checkActive = activeAndMoveWin($titleGameMain)
	If $checkActive Then
		writeLogFile($logFile, "Bat dau chon server vao lai game ! ")
		secondWait(1)
		; Click button chon server
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.change_server.choise_sv_x"), _JSONGet($jsonPositionConfig,"button.change_server.choise_sv_y"))
		secondWait(2)
		; Click vao chon sv 1
		_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.change_server.choise_sv_1_x"), _JSONGet($jsonPositionConfig,"button.change_server.choise_sv_1_y"))
		secondWait(2)
	Else
		writeLogFile($logFile, "Khong the active title game main de vao server !")
	EndIf
EndFunc

#cs
	Tim sport de luyen lvl len 20
#ce
Func goToSportLvl1() 
	; Khi bat dau se xuat hien tai 182 - 128
	writeLogFile($logFile, "Bat dau tim vi tri sport 1")
	; 533, 338
	_MU_MouseClick_Delay(_JSONGet($jsonPositionConfig,"button.loren_sport1.x"), _JSONGet($jsonPositionConfig,"button.loren_sport1.y"))
	secondWait(1)
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
			writeLogFile($logFile, "Lvl khong thay doi gi goMapArena. $nLvl = "  & $nLvl & " - $tmpLvl = " & $tmpLvl)
			
			If activeAndMoveWin($mainNo) Then
				If Not checkActiveAutoHome() Then
					writeLogFile($logFile, "Auto Home not active !")
					goMapArena($rsCount)
				Else
					; Truong hop lvl < 100 thi van vao map arena
					;~ writeLogFile($logFile, "Auto Home active ! Khong can lam gi nua")
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
		
		_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
		secondWait(5)
		; find lvl
		$sElement = findElement($sSession, "//span[@class='t-level']") 
		$tLvl = getTextElement($sSession, $sElement)
		$nLvl = Number($tLvl)
		
		; Truong hop $lvlStopCheck= 20 va so lan check ma = 10 thi thuc hien move = web
		If ($timeCheck == 10 Or $timeCheck == 20) And $lvlStopCheck == 20 Then
			writeLogFile($logFile, "So lan check = 10, thuc hien move = web")
			; Dien toa do X - vi tri cua sport 1 
			;~ 174, 65
			$positionX = 174
			$positionY = 65
			moveToPostionInWeb($sSession, $charName, $positionX, $positionY)
		EndIf
	WEnd

	writeLogFile($logFile, "Ket thuc check lvl tren web ! Lvl hien tai: " & $nLvl)
	
	Return $nLvl
EndFunc

#cs
	Vao event Lvl 
#ce
Func goMapLvl()
	writeLogFile($logFile, "Bat dau map event lvl ! ")
	; Chuyen sang bam S
	sendKeyS()
	
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
	sendKeyHome()
EndFunc

Func goMapArena($rsCount)
	; neu thoi gian tu phut 0 -5, 30 - 35 thi se cho cho toi khi thoi gian nay qua, sau do moi vao sport arena
	If (@MIN >= 0 And @MIN < 5) Or (@MIN >= 30 And @MIN < 35) Then
		writeLogFile($logFile, "Thoi gian hien tai: " & @HOUR & ":" & @MIN & " - Chua den thoi gian vao arena, cho toi 5 phut nua !")
		If (@MIN >= 0 And @MIN < 5) Then
			; Neu thoi gian tu 0 - 5 thi cho toi den 5 phut
			; Wait 5 minute
			minuteWait(5 - @MIN)
		Else
			; Neu thoi gian tu 30 - 35 thi cho toi den 35 phut
			; Wait 5 minute
			minuteWait(35 - @MIN)
		EndIf
	EndIf
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

Func validAccountRs($aAccountActiveRs)
	writeLogMethodStart("validAccountRs",@ScriptLineNumber,$aAccountActiveRs)
	Local $aAccValidate[0]
	; Validate account reset
	For $i = 0 To UBound($aAccountActiveRs) - 1
		$username = getPropertyJson($aAccountActiveRs[$i],"user_name")
		$charName = getPropertyJson($aAccountActiveRs[$i],"char_name")
		$lastTimeRs = getPropertyJson($aAccountActiveRs[$i],"last_time_reset")
		$limit = getPropertyJson($aAccountActiveRs[$i],"limit")
		$timeRs = getPropertyJson($aAccountActiveRs[$i],"time_rs")
		$hourPerRs = getPropertyJson($aAccountActiveRs[$i],"hour_per_reset")
		$typeRs = getPropertyJson($aAccountActiveRs[$i],"type_rs")
		
		$nextTimeRs = addTimePerRs($lastTimeRs, Number($hourPerRs))
		$currentTime = getTimeNow()
		$lastTimeRsAdd30 = _DateAdd('n', 30, $lastTimeRs)
		$lastTimeRsAdd60 = _DateAdd('n', 60, $lastTimeRs)

		writeLogFile($logFile, "Dang xu ly voi account => " & $username & " - " & $charName)
		
		; Truong hop $lastTimeRs = 0 hoac la co length = 1 thi thuc hien messageBox
		If $lastTimeRs == 0 Or StringLen($lastTimeRs) == 1 Then 
			MsgBox(16, "Lỗi", "Thời gian reset không hợp lệ !")
			ContinueLoop 
		EndIf

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

		; Neu vuot qua so lan rs duoc phep trong ngay $lastTimeRs khac voi ngay hien tai thi khong duoc coi la loi. dang cua $lastTimeRs la "2024/08/06 06:40:00"
		$sDateCheck = @YEAR & "/" & @MON & "/" & @MDAY
		If $timeRs >= $limit And StringLeft($lastTimeRs, 10) ==  $sDateCheck Then 
			writeLogFile($logFile, "Vuot qua so lan rs duoc phep trong ngay: " & $timeRs & @CRLF & " - So lan duoc phep: " & $limit)
			ContinueLoop
		Else
			; Truong hop la reset vip thi limit khong duoc qua = 10
			If ($typeRs == 1 And $timeRs >= 10 And StringLeft($lastTimeRs, 10) ==  $sDateCheck) Then
				writeLogFile($logFile, "Vuot qua so lan rs vip duoc phep trong ngay: " & $timeRs & @CRLF & " - So lan duoc phep: 10")
				ContinueLoop
			EndIf
			writeLogFile($logFile, "Time limit = " & $limit & " - Time rs = " & $timeRs & " - Last time rs = " & $lastTimeRs & "Date check = " & $sDateCheck)
		EndIf

		Redim $aAccValidate[UBound($aAccValidate) + 1]
		$aAccValidate[UBound($aAccValidate) - 1] = $aAccountActiveRs[$i]
	Next
	
	Return $aAccValidate
EndFunc

Func firstActionAfterRs()
	; Thuc hien send key home
	sendKeyHome()
	; Send tiep key tab de mo ban do
	sendKeyTab()
	; 4. Go to sport
	goToSportLvl1()
	; Sau khi vao sport thi thuc hien send key H
	sendKeyH()
	; Send 1 lan key tab nua de tat ban do
	sendKeyTab()
EndFunc

Func checkAutoZInWeb($sSession)
	; Giả sử bạn đã có $sSession là session hiện tại

	; 1️⃣ Tìm thẻ có class "t-auto_helper"
	;~ Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByCSSSelector, ".t-auto_helper")
	Local $sElement = findElement($sSession, "//div[@class='t-auto_helper']") 

	If @error Then
		writeLogFile($logFile, "Lỗi khi tìm thẻ t-auto_helper: " & @error)
		;~ ConsoleWrite("Không tìm thấy thẻ t-auto_helper" & @CRLF)
		Return False
	EndIf

	; 2️⃣ Lấy giá trị thuộc tính "style"
	Local $sStyle = _WD_ElementAction($sSession, $sElement, "attribute", "style")

	writeLogFile($logFile, "Style: " & $sStyle & @CRLF)

	; 3️⃣ Kiểm tra xem có 'display: none' không
	If StringInStr($sStyle, "display: none") Then
		writeLogFile($logFile, "❌ Thẻ đang bị ẩn (display: none)" & @CRLF)
		Return False
	Else
		writeLogFile($logFile, "✅ Thẻ đang hiển thị" & @CRLF)
		Return True
	EndIf
EndFunc

Func writeTimeRs($charName, $sTimeReset)
	$jsonRsGame = getJsonFromFile($jsonPathRoot & $autoRsUpdateInfoFileName)
	For $i = 0 To UBound($jsonRsGame) - 1
		$charNameTmp = getPropertyJson($jsonRsGame[$i],"char_name")
		If $charNameTmp == $charName Then
			_JSONSet($sTimeReset, $jsonRsGame[$i], "last_time_reset")
			setJsonToFileFormat($jsonPathRoot & $autoRsUpdateInfoFileName, $jsonRsGame)
		EndIf
	Next
EndFunc
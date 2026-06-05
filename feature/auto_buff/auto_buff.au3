#include-once
#include <Array.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"

$className = "auto_buff.au3"

;~ startAutoBuff()

; Method: startAutoBuff
; Description: Tự động buff tất cả account active trong config, kiểm tra ngày buff trước khi thực hiện
Func startAutoBuff()
	Local $aAccountActive[0]
	Local $sFilePath = $outputPathRoot & "File_Log_AutoBuff_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	writeLogMethodStart("startAutoBuff", @ScriptLineNumber)
	writeLogFile($logFile, "Begin start auto buff !", @ScriptLineNumber)

	; Đọc config
	Local $jAccountBuff = getJsonFromFile($jsonPathRoot & $autoBuffFileName)

	; Lọc account active
	For $i = 0 To UBound($jAccountBuff) - 1
		$active = getPropertyJson($jAccountBuff[$i], "active")
		If $active Then
			$aAccountActive = redimArray($aAccountActive, $jAccountBuff[$i])
		EndIf
	Next

	If UBound($aAccountActive) == 0 Then
		writeLogFile($logFile, "Khong co account nao active => Ket thuc chuong trinh !")
		FileClose($logFile)
		Return
	EndIf

	; Close chrome va setup session moi
	checkThenCloseChrome()
	$sSession = SetupChrome()

	; Sort theo user_name de gom nhom cung account
	$aAccountActive = sortArrayByProperty($aAccountActive, "user_name", True)

	For $i = 0 To UBound($aAccountActive) - 1
		; Kiểm tra đã buff hôm nay chưa
		Local $lastTimeBuff = getPropertyJson($aAccountActive[$i], "last_time_buff")
		Local $todayStr = @YEAR & "/" & @MON & "/" & @MDAY
		Local $userName = getPropertyJson($aAccountActive[$i], "user_name")

		If $lastTimeBuff == $todayStr Then
			writeLogFile($logFile, "Account " & $userName & " da buff hom nay => Bo qua !")
			ContinueLoop
		EndIf

		writeLogFile($logFile, "Dang xu ly buff voi account => " & $userName)
		processBuffAccount($aAccountActive[$i], $i)

		; Kiểm tra logout: nếu user kế tiếp khác user hiện tại thì logout
		Local $currentUser = getPropertyJson($aAccountActive[$i], "user_name")
		Local $nextUser = ""
		If $i + 1 < UBound($aAccountActive) Then
			$nextUser = getPropertyJson($aAccountActive[$i + 1], "user_name")
		EndIf
		writeLogFile($logFile, " $currentUser: " & $currentUser & " - $nextUser: " & $nextUser)
		If $currentUser <> $nextUser Then
			writeLogFile($logFile, " $currentUser <> $nextUser => Thuc hien logout")
			logout($sSession)
		EndIf
	Next

	writeLogMethodEnd("startAutoBuff", @ScriptLineNumber)
	FileClose($logFile)

	; Close webdriver
	If $sSession Then
		_WD_DeleteSession($sSession)
		_WD_Shutdown()
	EndIf
EndFunc   ;==>startAutoBuff

; Method: processBuffAccount
; Description: Xử lý buff cho 1 account: login → goPageBuffChar → cập nhật last_time_buff
Func processBuffAccount($jAccountInfo, $index)
	writeLogMethodStart("processBuffAccount", @ScriptLineNumber, $jAccountInfo)

	Local $username = getPropertyJson($jAccountInfo, "user_name")
	Local $password = getPropertyJson($jAccountInfo, "password")

	Local $isLoginSuccess = login($sSession, $username, $password)
	secondWait(5)

	If $isLoginSuccess Then
		goPageBuffChar($sSession)

		; Cập nhật last_time_buff vào config file
		Local $todayStr = @YEAR & "/" & @MON & "/" & @MDAY
		Local $jsonBuff = getJsonFromFile($jsonPathRoot & $autoBuffFileName)
		For $j = 0 To UBound($jsonBuff) - 1
			Local $uName = getPropertyJson($jsonBuff[$j], "user_name")
			If $uName == $username Then
				_JSONSet($todayStr, $jsonBuff[$j], "last_time_buff")
			EndIf
		Next
		setJsonToFileFormat($jsonPathRoot & $autoBuffFileName, $jsonBuff)

		writeLogFile($logFile, "Buff thanh cong voi account: " & $username)
	Else
		writeLogFile($logFile, "Dang nhap that bai voi account: " & $username)
		writeLogMethodEnd("processBuffAccount", @ScriptLineNumber, $jAccountInfo)
		Return False
	EndIf

	writeLogMethodEnd("processBuffAccount", @ScriptLineNumber, $jAccountInfo)
EndFunc   ;==>processBuffAccount

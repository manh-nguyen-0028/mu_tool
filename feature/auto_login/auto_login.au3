#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include <Date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#RequireAdmin

; ===========================================================================
; AUTO LOGIN GAME - XUAT PHAT TU DAU
; 12 BUOC LOGIN:
; 1. Mo chuong trinh theo common.game.exe_path
; 2. Click vao vi tri button.login.button_start_x/y
; 3. Active va move cua so launcher/game
; 4. Click vao button them tai khoan
; 5. Nhap username / password
; 6. Click vao vi tri tai khoan dau tien hoac button confirm
; 7. Cho man hinh load user theo button.login.wait_load_user_sec
; 8. Thuc hien chon server su dung returnServer($serverNumber)
; 9. Su dung returnChar de chon nhan vat vao game
; 10. Kiem tra xem nhan vat dang nhap co la nhan vat chinh hoac nhan vat trong tai khoan hay khong
; 11. Neu co window cung tai khoan va character SAI -> sendKeyF8()
; 12. Ghi update status user da login vao output/report_user_login.txt
; ===========================================================================

; Global variables
Global $sFilePathAutoLogin
Global $sUserLoginReportPath
Global $logFile
Global $jAccountLoginConfig
Global $iRetryCount = 0
Global Const $MAX_RETRY = 1

start()

; ============ PHASE 1: HELPER FUNCTIONS (4 HAM) ============

; Method: init_auto_login
; Description: Khoi tao va load cac config can thiet cho auto login
Func init_auto_login()
	writeLogFile($logFile, "=== init_auto_login() - Khoi tao Auto Login ===")

	$jAccountLoginConfig = getJsonFromFile($jsonPathRoot & $autoLoginFileName)
	If UBound($autoLoginFileName) = 0 Then
		writeLogFile($logFile, "LỖI: Không tìm thấy account config hoặc config trống")
		Return False
	EndIf

	writeLogFile($logFile, "Đã load " & UBound($jAccountLoginConfig) & " account từ file config")
	Return True
EndFunc   ;==>init_auto_login

; Method: getLoginProperty
; Description: Lay toa do hoac cac property tu button.login section trong position_config
Func getLoginProperty($propertyName)
	Local $value = getProperty("common.login." & $propertyName)
	If $value = "" Then
		$value = getProperty($propertyName)
	EndIf
	writeLogFile($logFile, "getLoginProperty(" & $propertyName & ") = " & $value)
	Return $value
EndFunc   ;==>getLoginProperty

; Method: getServerNumber
; Description: Lay so server tu account config, neu khong co thi dung default 1
Func getServerNumber($accountConfig)
	Local $serverNo = getPropertyJson($accountConfig, "server_no")
	If $serverNo = "" Or Number($serverNo) <= 0 Then
		$serverNo = 1
	EndIf
	Return Number($serverNo)
EndFunc   ;==>getServerNumber

; Method: getChannelNumber
; Description: Lay so channel tu account config, neu khong co thi dung default 1
Func getChannelNumber($accountConfig)
	Local $channelNo = getPropertyJson($accountConfig, "channel_no")
	If $channelNo = "" Or Number($channelNo) <= 0 Then
		$channelNo = 1
	EndIf
	Return Number($channelNo)
EndFunc   ;==>getChannelNumber

; Method: getCharInAccount
; Description: Doc file char_in_account.txt, tim danh sach character cung tai khoan voi charName
Func getCharInAccount($charName)
	writeLogFile($logFile, "getCharInAccount($charName) = " & $charName)

	Local $aCharInAccount = getArrayInFileTxt($textPathRoot & $charInAccountFileName)
	Local $aResult[0]

	If UBound($aCharInAccount) = 0 Then
		writeLogFile($logFile, "CẢNH BÁO: File char_in_account.txt không tồn tại hoặc trống")
		Return $aResult
	EndIf

	For $i = 0 To UBound($aCharInAccount) - 1
		Local $lineContent = $aCharInAccount[$i]
		Local $resultCheck = StringInStr($lineContent, $charName)

		If $resultCheck Then
			Local $aCharLine = StringSplit($lineContent, "|")
			If Not @error And $aCharLine[0] > 0 Then
				Local $aResult[$aCharLine[0]]
				For $j = 0 To $aCharLine[0] - 1
					$aResult[$j] = $aCharLine[$j + 1]
				Next
				writeLogFile($logFile, "Tìm thấy " & UBound($aResult) & " character cùng tài khoản")
				Return $aResult
			EndIf
		EndIf
	Next

	writeLogFile($logFile, "CẢNH BÁO: Không tìm thấy " & $charName & " trong file char_in_account.txt")
	Return $aResult
EndFunc   ;==>getCharInAccount

; ============ PHASE 2: MAIN LOOP & ORCHESTRATION (2 HAM) ============

; Method: processAutoLogin
; Description: Duyet qua tung account, goi processLogin cho moi account active
Func processAutoLogin()
	writeLogFile($logFile, "=== processAutoLogin() - Bat dau loop duyệt account ===")

	$jAccountLoginConfig = getJsonFromFile($jsonPathRoot & $autoLoginFileName)

	If UBound($jAccountLoginConfig) = 0 Then
		writeLogFile($logFile, "LỖI: Không có account nào để login")
		Return False
	EndIf

	writeLogFile($logFile, "Tổng account: " & UBound($jAccountLoginConfig))

	Local $iSuccess = 0, $iFailed = 0

	For $i = 0 To UBound($jAccountLoginConfig) - 1
		Local $accountConfig = $jAccountLoginConfig[$i]
		Local $bActive = getPropertyJson($accountConfig, "active")

		If Not $bActive Then
			writeLogFile($logFile, "Account " & ($i + 1) & " bị vô hiệu hóa (active=false), bỏ qua")
			ContinueLoop
		EndIf

		Local $sUsername = getPropertyJson($accountConfig, "username")
		Local $sPassword = getPropertyJson($accountConfig, "password")
		Local $sCharName = getPropertyJson($accountConfig, "char_name")
		Local $iServerNo = getServerNumber($accountConfig)

		writeLogFile($logFile, "")
		writeLogFile($logFile, "--- XỬ LÝ ACCOUNT " & ($i + 1) & ": " & $sCharName & " ---")

		$iRetryCount = 0
		Local $bLoginSuccess = processLogin($sUsername, $sPassword, $sCharName, $iServerNo, $accountConfig)

		If $bLoginSuccess Then
			$iSuccess += 1
			writeLogFile($logFile, "✓ Account " & $sCharName & " login THÀNH CÔNG")
		Else
			$iFailed += 1
			writeLogFile($logFile, "✗ Account " & $sCharName & " login THẤT BẠI")
		EndIf
	Next

	writeLogFile($logFile, "")
	writeLogFile($logFile, "=== TỔNG KẾT ===")
	writeLogFile($logFile, "Thành công: " & $iSuccess & " | Thất bại: " & $iFailed)
	Return True
EndFunc   ;==>processAutoLogin

; Method: processLogin
; Description: Orchestrate 12 steps login
Func processLogin($sUsername, $sPassword, $sCharName, $iServerNo, $accountConfig)
	writeLogFile($logFile, ">>> processLogin(" & $sCharName & ", server=" & $iServerNo & ")")

	If Not runGameExe() Then
		writeLoginReport($sUsername, $sCharName, "failed_game_not_open", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf

	If Not clickButtonStart() Then
		writeLoginReport($sUsername, $sCharName, "failed_button_start", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf
	
	If Not activeAndMoveWin("MU GamethuVN - Season 21") Then
		writeLoginReport($sUsername, $sCharName, "failed_window_active", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf

	If Not clickChangeAccount() Then
		writeLoginReport($sUsername, $sCharName, "failed_clickChangeAccount()_start", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf

	If Not clickAddAccount() Then
		writeLoginReport($sUsername, $sCharName, "failed_add_account", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf

	If Not inputCredentials($sUsername, $sPassword) Then
		writeLoginReport($sUsername, $sCharName, "failed_input_credentials", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf

	If Not confirmLogin() Then
		writeLoginReport($sUsername, $sCharName, "failed_confirm_login", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf

	waitLoadUser()

	If Not selectServer($iServerNo) Then
		writeLoginReport($sUsername, $sCharName, "failed_select_server", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf

	If Not selectCharacter($sCharName) Then
		writeLoginReport($sUsername, $sCharName, "failed_select_character", $iServerNo, getChannelNumber($accountConfig))
		Return False
	EndIf

	Local $iChannelNo = getChannelNumber($accountConfig)
	Local $bCharVerified = verifyCharacterLoaded($sCharName)

	If $bCharVerified Then
		writeLogFile($logFile, "✓ Character " & $sCharName & " login ĐÚNG")
		writeLoginReport($sUsername, $sCharName, "success", $iServerNo, $iChannelNo)
		Return True
	Else
		writeLogFile($logFile, "✗ Character SAI - Cần F8 và retry")
		If Not handleWrongCharacter($sUsername, $sPassword, $sCharName, $iServerNo) Then
			writeLoginReport($sUsername, $sCharName, "failed", $iServerNo, $iChannelNo)
			Return False
		Else
			writeLoginReport($sUsername, $sCharName, "retry_success", $iServerNo, $iChannelNo)
			Return True
		EndIf
	EndIf
EndFunc   ;==>processLogin

; ============ PHASE 3: LOGIN STEPS (6 HAM) ============

Func runGameExe()
	writeLogFile($logFile, "Step 1: runGameExe() - Mở game")

	Local $sGameExePath = getProperty("common.game.exe_path")
	If $sGameExePath = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy common.game.exe_path trong config")
		Return False
	EndIf

	If Not FileExists($sGameExePath) Then
		writeLogFile($logFile, "LỖI: File game exe không tồn tại: " & $sGameExePath)
		Return False
	EndIf

	Local $iPID = Run('"D:\MUGameThuVN_Full_MB\MU.exe"', "D:\MUGameThuVN_Full_MB")
	WinWait("MU GamethuVN")
	WinActivate("MU GamethuVN")
	If $iPID = 0 Then
		writeLogFile($logFile, "LỖI: Không thể mở game exe: " & $sGameExePath)
		Return False
	EndIf

	writeLogFile($logFile, "✓ Đã mở game exe, PID: " & $iPID)
	secondWait(6)
	Return True
EndFunc   ;==>runGameExe

Func clickButtonStart()
	writeLogFile($logFile, "Step 2: clickButtonStart() - Click button Start")

	Local $iButtonStartX = getLoginProperty("button_start_x")
	Local $iButtonStartY = getLoginProperty("button_start_y")

	If $iButtonStartX = "" Or $iButtonStartY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy button_start_x hoặc button_start_y")
		Return False
	EndIf

	$iButtonStartX = Number($iButtonStartX)
	$iButtonStartY = Number($iButtonStartY)

	writeLogFile($logFile, "Click tại X=" & $iButtonStartX & ", Y=" & $iButtonStartY)
	_MU_MouseClick_Delay($iButtonStartX, $iButtonStartY)

	secondWait(10)
	Return True
EndFunc   ;==>clickButtonStart

Func clickChangeAccount()
	writeLogFile($logFile, "Step 4: ClickChangeAccount() - Click button 'ClickChangeAccount'")

	Local $iChangeAccountX = getLoginProperty("button_change_account_x")
	Local $iChangeAccountY = getLoginProperty("button_change_account_y")
	
	If $iChangeAccountX = "" Or $iChangeAccountY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy button_change_account_x hoặc button_change_account_y")
		Return False
	EndIf

	writeLogFile($logFile, "Click change Account tại X=" & $iChangeAccountX & ", Y=" & $iChangeAccountY)
	_MU_MouseClick_Delay($iChangeAccountX, $iChangeAccountY)

	secondWait(5)
	Return True
EndFunc

Func clickAddAccount()
	writeLogFile($logFile, "Step 4: clickAddAccount() - Click button 'Add Account'")

	Local $iAddAccountX = getLoginProperty("button_add_account_x")
	Local $iAddAccountY = getLoginProperty("button_add_account_y")

	If $iAddAccountX = "" Or $iAddAccountY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy button_add_account_x hoặc button_add_account_y")
		Return False
	EndIf

	$iAddAccountX = Number($iAddAccountX)
	$iAddAccountY = Number($iAddAccountY)

	writeLogFile($logFile, "Click Add Account tại X=" & $iAddAccountX & ", Y=" & $iAddAccountY)
	_MU_MouseClick_Delay($iAddAccountX, $iAddAccountY)
	secondWait(5)

	Return True
EndFunc   ;==>clickAddAccount

Func inputCredentials($sUsername, $sPassword)
	writeLogFile($logFile, "Step 5: inputCredentials() - Nhập username và password")

	Local $iUsernameX = getLoginProperty("input_username_x")
	Local $iUsernameY = getLoginProperty("input_username_y")
	Local $iPasswordX = getLoginProperty("input_password_x")
	Local $iPasswordY = getLoginProperty("input_password_y")

	If $iUsernameX = "" Or $iUsernameY = "" Or $iPasswordX = "" Or $iPasswordY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy input coordinates cho username/password")
		Return False
	EndIf

	$iUsernameX = Number($iUsernameX)
	$iUsernameY = Number($iUsernameY)
	$iPasswordX = Number($iPasswordX)
	$iPasswordY = Number($iPasswordY)

	writeLogFile($logFile, "Click input username tại X=" & $iUsernameX & ", Y=" & $iUsernameY)
	_MU_MouseClick_Delay($iUsernameX, $iUsernameY)
	secondWait(1)

	sendKeyDelay("^a")

	For $i = 1 To StringLen($sUsername)
		sendKeyDelay(StringMid($sUsername, $i, 1))
	Next

	writeLogFile($logFile, "✓ Đã nhập username: " & $sUsername)
	secondWait(1)

	writeLogFile($logFile, "Click input password tại X=" & $iPasswordX & ", Y=" & $iPasswordY)
	_MU_MouseClick_Delay($iPasswordX, $iPasswordY)
	secondWait(1)

	sendKeyDelay("^a")

	For $i = 1 To StringLen($sPassword)
		sendKeyDelay(StringMid($sPassword, $i, 1))
	Next

	writeLogFile($logFile, "✓ Đã nhập password (ẩn)")

	sendKeyEnter()
	
	Return True
EndFunc   ;==>inputCredentials

Func confirmLogin()
	writeLogFile($logFile, "Step 6: confirmLogin() - Click button confirm hoặc first account")

	Local $iConfirmX = getLoginProperty("button_confirm_x")
	Local $iConfirmY = getLoginProperty("button_confirm_y")

	If $iConfirmX = "" Or $iConfirmY = "" Then
		$iConfirmX = getLoginProperty("first_account_x")
		$iConfirmY = getLoginProperty("first_account_y")
	EndIf

	If $iConfirmX = "" Or $iConfirmY = "" Then
		$iConfirmX = getLoginProperty("button_submit_x")
		$iConfirmY = getLoginProperty("button_submit_y")
	EndIf

	If $iConfirmX = "" Or $iConfirmY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy tọa độ confirm button")
		Return False
	EndIf

	$iConfirmX = Number($iConfirmX)
	$iConfirmY = Number($iConfirmY)

	writeLogFile($logFile, "Click confirm/first account tại X=" & $iConfirmX & ", Y=" & $iConfirmY)
	_MU_MouseClick_Delay($iConfirmX, $iConfirmY)
	secondWait(2)

	Return True
EndFunc   ;==>confirmLogin

; ============ PHASE 4: SERVER/CHARACTER SELECTION & VERIFICATION (5 HAM) ============

Func waitLoadUser()
	writeLogFile($logFile, "Step 7: waitLoadUser() - Chờ load user")

	Local $iWaitSec = getLoginProperty("wait_load_user_sec")
	If $iWaitSec = "" Then
		$iWaitSec = 5
	EndIf

	$iWaitSec = Number($iWaitSec)
	writeLogFile($logFile, "Chờ " & $iWaitSec & " giây để load user")
	secondWait($iWaitSec)
EndFunc   ;==>waitLoadUser

Func selectServer($iServerNo)
	writeLogFile($logFile, "Step 8: selectServer(" & $iServerNo & ")")

	If $iServerNo <= 0 Then
		$iServerNo = 1
	EndIf

	Local $bResult = returnServer($iServerNo)

	If $bResult Then
		writeLogFile($logFile, "✓ Chọn server " & $iServerNo & " thành công")
		Return True
	Else
		writeLogFile($logFile, "LỖI: Chọn server " & $iServerNo & " thất bại")
		Return False
	EndIf
EndFunc   ;==>selectServer

Func selectCharacter($sCharName)
	writeLogFile($logFile, "Step 9: selectCharacter(" & $sCharName & ")")

	Local $sMainNo = getMainNoByChar($sCharName)
	writeLogFile($logFile, "Window title format: " & $sMainNo)

	returnChar($sMainNo)

	secondWait(2)
	Local $bCheckActive = checkActiveWin($sMainNo)

	If $bCheckActive Then
		writeLogFile($logFile, "✓ Chọn character " & $sCharName & " thành công (window active)")
		Return True
	Else
		writeLogFile($logFile, "CẢNH BÁO: Window character " & $sCharName & " chưa active, tiếp tục verify")
		Return True
	EndIf
EndFunc   ;==>selectCharacter

Func verifyCharacterLoaded($sCharName)
	writeLogFile($logFile, "Step 10: verifyCharacterLoaded(" & $sCharName & ")")

	Local $aCharList = getCharInAccount($sCharName)

	If UBound($aCharList) = 0 Then
		writeLogFile($logFile, "CẢNH BÁO: Không tìm thấy danh sách character cùng tài khoản")
		Return False
	EndIf

	writeLogFile($logFile, "Danh sách character cùng tài khoản: " & _ArrayToString($aCharList, ", "))

	Local $aWindowList = WinList()
	Local $bFoundCorrectChar = False

	For $i = 1 To $aWindowList[0][0]
		Local $sWindowTitle = $aWindowList[$i][1]

		If StringInStr($sWindowTitle, "MU GamethuVN - Season 21") And StringInStr($sWindowTitle, "Hà Nội") Then
			writeLogFile($logFile, "Tìm thấy game window: " & $sWindowTitle)

			Local $aMatch = StringRegExp($sWindowTitle, "MU GamethuVN - Season 21 \(Hà Nội - (.*?)\)", 3)
			If UBound($aMatch) > 0 Then
				Local $sActiveChar = $aMatch[0]
				writeLogFile($logFile, "Character active hiện tại: " & $sActiveChar)

				For $j = 0 To UBound($aCharList) - 1
					If $aCharList[$j] = $sActiveChar Then
						writeLogFile($logFile, "✓ Character " & $sActiveChar & " ĐÚNG (trong danh sách tài khoản)")
						$bFoundCorrectChar = True
						ExitLoop 2
					EndIf
				Next

				writeLogFile($logFile, "✗ Character " & $sActiveChar & " SAI (không trong danh sách tài khoản)")
				Return False
			EndIf
		EndIf
	Next

	If $bFoundCorrectChar Then
		Return True
	Else
		writeLogFile($logFile, "LỖI: Không tìm thấy game window active")
		Return False
	EndIf
EndFunc   ;==>verifyCharacterLoaded

Func handleWrongCharacter($sUsername, $sPassword, $sCharName, $iServerNo)
	writeLogFile($logFile, "Step 11: handleWrongCharacter() - Xử lý character sai")

	If $iRetryCount >= $MAX_RETRY Then
		writeLogFile($logFile, "LỖI: Đã retry " & $iRetryCount & " lần, vượt quá giới hạn")
		Return False
	EndIf

	$iRetryCount += 1
	writeLogFile($logFile, "Retry lần " & $iRetryCount & "/" & $MAX_RETRY)

	writeLogFile($logFile, "Gửi F8 để close game")
	sendKeyF8()
	secondWait(3)

	writeLogFile($logFile, "Retry login lần " & $iRetryCount)
	Local $bRetrySuccess = processLogin($sUsername, $sPassword, $sCharName, $iServerNo, "")

	Return $bRetrySuccess
EndFunc   ;==>handleWrongCharacter

; ============ PHASE 5: REPORT & ENTRY POINT (3 HAM) ============

Func writeLoginReport($sUsername, $sCharName, $sStatus, $iServerNo, $iChannelNo)
	writeLogFile($logFile, "Step 12: writeLoginReport() - Ghi report login")

	Local $sTimestamp = _NowCalc()
	Local $sReportLine = $sTimestamp & " | " & $sUsername & " | " & $sCharName & " | " & $sStatus & " | " & $iServerNo & " | " & $iChannelNo

	Local $hReportFile = FileOpen($sUserLoginReportPath, 1)
	If $hReportFile = -1 Then
		writeLogFile($logFile, "LỖI: Không thể mở file report: " & $sUserLoginReportPath)
		Return
	EndIf

	FileWrite($hReportFile, $sReportLine & @CRLF)
	FileClose($hReportFile)

	writeLogFile($logFile, "✓ Ghi report: " & $sReportLine)
EndFunc   ;==>writeLoginReport

Func start()
	$sFilePathAutoLogin = $outputPathRoot & "File_Log_AutoLogin_.txt"
	$sUserLoginReportPath = $outputPathRoot & "report_user_login.txt"

	$logFile = FileOpen($sFilePathAutoLogin, $iLogOverwrite)
	If $logFile = -1 Then
		MsgBox($MB_ICONERROR, "Lỗi", "Không thể mở file log: " & $sFilePathAutoLogin)
		Return False
	EndIf

	writeLogFile($logFile, "===== AUTO LOGIN START =====")
	writeLogFile($logFile, "Thời gian: " & _NowCalc())
	writeLogFile($logFile, "")

	If Not init() Then
		writeLogFile($logFile, "LỖI: Khởi tạo config thất bại")
		FileClose($logFile)
		Return False
	EndIf

	Local $bResult = processAutoLogin()

	writeLogFile($logFile, "")
	writeLogFile($logFile, "===== AUTO LOGIN END =====")
	writeLogFile($logFile, "Thời gian kết thúc: " & _NowCalc())

	FileClose($logFile)

	Return $bResult
EndFunc   ;==>start

Func main()
	start()
EndFunc   ;==>main

If @Compiled = 0 Then
	main()
EndIf

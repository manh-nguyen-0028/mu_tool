#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include <Date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#RequireAdmin

; ===========================================================================
; AUTO LOGIN GAME - XUAT PHAT TU DAU
; PRE-CHECK 2 LOP:
; - Truoc processLogin: neu da co main active cung tai khoan thi skip
; - Trong processLogin: double-check lai truoc khi thuc hien Step 1
; 12 BUOC LOGIN:
; 1. closeExistingGameWindow
; 2. runGameExe
; 3. clickButtonStart
; 4. activeAndMoveGameWindow
; 5. checkPopupLogin
; 6. processLoginAccount
; 7. waitLoadUser
; 8. selectServer
; 9. selectCharacter
; 10. verifyCharacterLoaded
; 11. handleWrongCharacter
; 12. writeLoginReport
; ===========================================================================

; Global variables
Global $sFilePathAutoLogin
Global $sUserLoginReportPath
Global $logFile
Global $jAccountLoginConfig
Global $iRetryCount = 0
Global Const $MAX_RETRY = 1

; Method: preCheckActiveMainInSameAccount
; Description: Kiem tra trong cung tai khoan da co main nao dang active hay chua
Func preCheckActiveMainInSameAccount($sCharName)
	; Kiem tra nhanh main hien tai
	If checkActiveWinByChar($sCharName) Then
		writeLogFile($logFile, "Đã có main active: " & $sCharName)
		Return True
	EndIf

	; Dung method trong game_utils de tim main khac cung account dang active
	Local $currentChar = $sCharName
	Local $charNameOtherChar = checkActiveOtherChar($currentChar)
	; $charNameOtherChar: JoyBoy|2 - > charFound: JoyBoy - numberChar: 2
	Local $charFound = StringSplit($charNameOtherChar, "|")[1]
	Local $numberChar = StringSplit($charNameOtherChar, "|")[2]

	writeLogFile($logFile, "preCheckActiveMainInSameAccount -> charFound=" & $charFound & " | numberChar=" & $numberChar)

	If $charFound <> "" Then
		writeLogFile($logFile, "Đã có main active trong cùng account: " & $charFound)
		Return True
	EndIf

	Return False
EndFunc   ;==>preCheckActiveMainInSameAccount

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
	Else
		writeLogFile($logFile, "Tổng account trong config: " & UBound($jAccountLoginConfig))
		; in ra username va charname, trang thai active cua tung account
		For $i = 0 To UBound($jAccountLoginConfig) - 1
			Local $accountConfig = $jAccountLoginConfig[$i]
			Local $sUsername = getPropertyJson($accountConfig, "username")
			Local $sCharName = getPropertyJson($accountConfig, "char_name")
			Local $bActive = getPropertyJson($accountConfig, "active")
			writeLogFile($logFile, "Account " & ($i + 1) & ": username=" & $sUsername & ", char_name=" & $sCharName & ", active=" & $bActive)
		Next
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

		; Pre-check truoc khi goi processLogin: neu da co main active cung tai khoan thi bo qua
		If preCheckActiveMainInSameAccount($sCharName) Then
			writeLogFile($logFile, "Account " & $sCharName & " đã có main active, bỏ qua login")
			writeLoginReport($sUsername, $sCharName, "already_logged_in", $iServerNo, getChannelNumber($accountConfig))
			$iSuccess += 1
			ContinueLoop
		EndIf

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
	Local $iChannelNo = getChannelNumber($accountConfig)

	If Not closeExistingGameWindow() Then
		writeLoginReport($sUsername, $sCharName, "failed_close_existing_window", $iServerNo, $iChannelNo)
		;~ Return False
	EndIf

	If Not runGameExe() Then
		writeLoginReport($sUsername, $sCharName, "failed_game_not_open", $iServerNo, $iChannelNo)
		Return False
	EndIf

	If Not clickButtonStart() Then
		writeLoginReport($sUsername, $sCharName, "failed_button_start", $iServerNo, $iChannelNo)
		Return False
	EndIf

	If Not activeAndMoveGameWindow() Then
		writeLoginReport($sUsername, $sCharName, "failed_window_active", $iServerNo, $iChannelNo)
		Return False
	EndIf

	If Not checkPopupLogin() Then
		writeLoginReport($sUsername, $sCharName, "failed_check_popup_login", $iServerNo, $iChannelNo)
		Return False
	EndIf

	If Not processLoginAccount($sUsername, $sPassword) Then
		Switch @error
			Case 1
				writeLoginReport($sUsername, $sCharName, "failed_add_account", $iServerNo, $iChannelNo)
			Case 2
				writeLoginReport($sUsername, $sCharName, "failed_input_credentials", $iServerNo, $iChannelNo)
			Case 3
				writeLoginReport($sUsername, $sCharName, "failed_confirm_login", $iServerNo, $iChannelNo)
			Case Else
				writeLoginReport($sUsername, $sCharName, "failed_process_login", $iServerNo, $iChannelNo)
		EndSwitch
		Return False
	EndIf

	waitLoadUser()

	If Not selectServer($iServerNo) Then
		writeLoginReport($sUsername, $sCharName, "failed_select_server", $iServerNo, $iChannelNo)
		Return False
	EndIf

	If Not selectCharacter($sCharName) Then
		writeLoginReport($sUsername, $sCharName, "failed_select_character", $iServerNo, $iChannelNo)
		Return False
	EndIf

	Local $bCharVerified = verifyCharacterLoaded($sCharName)

	If $bCharVerified Then
		writeLogFile($logFile, "✓ Character " & $sCharName & " login ĐÚNG")
		writeLogFile($logFile, "Character đúng -> thực hiện minisize main theo flow")
		minisizeMainByChar($sCharName)
		writeLoginReport($sUsername, $sCharName, "success", $iServerNo, $iChannelNo)
		Return True
	Else
		writeLogFile($logFile, "✗ Character SAI - Cần F8 và retry")
		If Not handleWrongCharacter($sUsername, $sPassword, $sCharName, $iServerNo, $accountConfig) Then
			writeLoginReport($sUsername, $sCharName, "failed", $iServerNo, $iChannelNo)
			Return False
		Else
			writeLoginReport($sUsername, $sCharName, "retry_success", $iServerNo, $iChannelNo)
			Return True
		EndIf
	EndIf

	secondWait(5)
EndFunc   ;==>processLogin

; ============ PHASE 3: LOGIN STEPS (9 HAM) ============

Func closeExistingGameWindow()
	writeLogFile($logFile, "Step 1: closeExistingGameWindow() - Dùng hàm dùng chung từ game_utils")
	; Thuc hien 2 cong viec: 1. Close window voi $titleGameMain
	closeWinExact($titleGameMain)
	;~ closeByTitleAndClass($titleGameMain, "SDL_app")
	secondWait(1)
	; 2. Close window process co title = $titleGameMain va class = $titleGameMain
	$class = "#32770"
	;~ closeByClass($class)
	closeByTitleAndClass($titleGameMain, "#32770")
	secondWait(1)
	closeByTitleAndClass($titleGameMain, "#32770")
EndFunc   ;==>closeExistingGameWindow

Func runGameExe()
	writeLogFile($logFile, "Step 2: runGameExe() - Mở game")

	Local $sGameExePath = getProperty("common.game.exe_path")
	If $sGameExePath = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy common.game.exe_path trong config")
		Return False
	EndIf

	If Not FileExists($sGameExePath) Then
		writeLogFile($logFile, "LỖI: File game exe không tồn tại: " & $sGameExePath)
		Return False
	EndIf

	Local $sDir = StringRegExpReplace($sGameExePath, "\\[^\\]+$", "")
	Local $iPID = Run('"' & $sGameExePath & '"', $sDir)
	If $iPID = 0 Then
		writeLogFile($logFile, "LỖI: Không thể mở game exe: " & $sGameExePath)
		Return False
	EndIf

	WinWait("MU GamethuVN")
	WinActivate("MU GamethuVN")

	writeLogFile($logFile, "Chờ 3 giây trước khi xử lý popup lỗi")
	secondWait(3)

	Local $iPopupErrorOkX = getLoginProperty("popup_error_ok_x")
	Local $iPopupErrorOkY = getLoginProperty("popup_error_ok_y")

	If $iPopupErrorOkX = "" Or $iPopupErrorOkY = "" Then
		$iPopupErrorOkX = getProperty("button.dong_y.x")
		$iPopupErrorOkY = getProperty("button.dong_y.y")
	EndIf

	If $iPopupErrorOkX <> "" And $iPopupErrorOkY <> "" Then
		$iPopupErrorOkX = Number($iPopupErrorOkX)
		$iPopupErrorOkY = Number($iPopupErrorOkY)
		writeLogFile($logFile, "Click OK popup lỗi tại X=" & $iPopupErrorOkX & ", Y=" & $iPopupErrorOkY)
		_MU_MouseClick_Delay($iPopupErrorOkX, $iPopupErrorOkY)
		secondWait(1)
		sendKeyEnter()
	Else
		writeLogFile($logFile, "CẢNH BÁO: Không tìm thấy tọa độ popup_error_ok_x/y (hoặc button.dong_y.x/y), bỏ qua click popup")
	EndIf

	writeLogFile($logFile, "✓ Đã mở game exe, PID: " & $iPID)
	secondWait(5)
	Return True
EndFunc   ;==>runGameExe

Func clickButtonStart()
	writeLogFile($logFile, "Step 3: clickButtonStart() - ControlClick button Start")

	Local $sLauncherTitle = "[TITLE:MU GamethuVN - Season 21; CLASS:#32770]"
	Local $sLauncherControl = "[CLASS:Button; INSTANCE:2]"
	Local $iControlClickResult = ControlClick($sLauncherTitle, "", $sLauncherControl)

	If $iControlClickResult = 0 Then
		writeLogFile($logFile, "LỖI: ControlClick button Start thất bại với title=" & $sLauncherTitle & " control=" & $sLauncherControl)
		Return False
	EndIf

	writeLogFile($logFile, "Đã ControlClick button Start thành công")
	
	Return True
EndFunc   ;==>clickButtonStart

Func activeAndMoveGameWindow()
	writeLogFile($logFile, "Step 4: activeAndMoveGameWindow() - Active/move window + click add account phía ngoài")
	secondWait(5)
	Local $iElapsedSec = 0
	Local $bActive = False
	While $iElapsedSec < 10 And Not $bActive
		$bActive = activeAndMoveWin($titleGameMain)
		If Not $bActive Then
			writeLogFile($logFile, "Chưa active được window, thử lại sau 1s... (elapsed=" & $iElapsedSec & "s)")
			secondWait(1)
			$iElapsedSec += 1
		EndIf
	WEnd

	If Not $bActive Then
		writeLogFile($logFile, "LỖI: Không active/move được launcher window sau " & $iElapsedSec & " giây")
		Return False
	Else
		secondWait(10)
	EndIf

	; Thuc hien check color xem man nay da duoc active hay chua
	;703, 558
	;0xFFFFFF
	; "color_screen_load_game": "0xFFFFFF",
    ;~   "position_screen_load_game_x": 703,
    ;~   "position_screen_load_game_y": 558,

	Local $positionLoadGameX = getLoginProperty("position_screen_load_game_x")
	Local $positionLoadGameY = getLoginProperty("position_screen_load_game_y")
	Local $colorLoadGame = getLoginProperty("color_screen_load_game")

	If $positionLoadGameX = Default Or $positionLoadGameX = "" Or $positionLoadGameY = Default Or $positionLoadGameY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy positionLoadGameY _x/y")
		Return False
	EndIf

	If $colorLoadGame = "" Then
		$colorLoadGame = "0xFFFFFF"
	EndIf

	$checkLoadGameSuccess = checkPixelColor($positionLoadGameX, $positionLoadGameY, $colorLoadGame)
	If Not $checkLoadGameSuccess Then
		writeLogFile($logFile, "LỖI: Pixel check tai X=" & $positionLoadGameX & ", Y=" & $positionLoadGameY & " khong phai mau " & $colorLoadGame)
		secondWait(5)
	EndIf

	Local $iOuterAddAccountX = getLoginProperty("button_outer_add_account_x")
	Local $iOuterAddAccountY = getLoginProperty("button_outer_add_account_y")

	If $iOuterAddAccountX = Default Or $iOuterAddAccountX = "" Or $iOuterAddAccountY = Default Or $iOuterAddAccountY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy button_outer_add_account_x/y hoặc button_add_account_x/y")
		Return False
	EndIf

	; active 1 lan nua de tranh truong hop window bi overlay boi popup
	activeAndMoveWin($titleGameMain)

	; Thuc hien check color xem man nay da duoc active hay chua, tranh truong hop click nham vao popup
	; TODO
	$iOuterAddAccountX = Number($iOuterAddAccountX)
	$iOuterAddAccountY = Number($iOuterAddAccountY)

	writeLogFile($logFile, "Click button thêm tài khoản phía ngoài tại X=" & $iOuterAddAccountX & ", Y=" & $iOuterAddAccountY)
	_MU_MouseClick_Delay($iOuterAddAccountX, $iOuterAddAccountY)
	secondWait(1)

	Return True
EndFunc   ;==>activeAndMoveGameWindow

Func checkPopupLogin()
	writeLogFile($logFile, "Step 5: checkPopupLogin() - Check pixel popup login")

	Local $iCheckPixelX = getLoginProperty("button_outer_add_account_check_x")
	Local $iCheckPixelY = getLoginProperty("button_outer_add_account_check_y")
	Local $sCheckPixelColor = getLoginProperty("button_outer_add_account_check_color")
	Local $iCheckPixelMaxRetry = getLoginProperty("button_outer_add_account_check_max_retry")

	If $iCheckPixelX = Default Or $iCheckPixelX = "" Or $iCheckPixelY = Default Or $iCheckPixelY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy button_outer_add_account_check_x/y")
		Return False
	EndIf

	If $sCheckPixelColor = "" Then
		$sCheckPixelColor = "0xFFFFFF"
	EndIf

	If $iCheckPixelMaxRetry = "" Or Number($iCheckPixelMaxRetry) <= 0 Then
		$iCheckPixelMaxRetry = 10
	EndIf

	$iCheckPixelX = Number($iCheckPixelX)
	$iCheckPixelY = Number($iCheckPixelY)
	$iCheckPixelMaxRetry = Number($iCheckPixelMaxRetry)
	Local $iExpectedColor = Number($sCheckPixelColor)

	Local $bCheckAddAccount = False
	Local $iCheckCount = 0
	While Not $bCheckAddAccount And $iCheckCount < $iCheckPixelMaxRetry
		If PixelGetColor($iCheckPixelX, $iCheckPixelY) = $iExpectedColor Then
			$bCheckAddAccount = True
		Else
			$iCheckCount += 1
			If $iCheckCount < $iCheckPixelMaxRetry Then
				writeLogFile($logFile, "Chua xac nhan duoc mau tai X=" & $iCheckPixelX & ", Y=" & $iCheckPixelY & ", thu lai sau 1s... (lan=" & $iCheckCount & "/" & $iCheckPixelMaxRetry & ")")
				secondWait(1)
			EndIf
		EndIf
	WEnd

	If Not $bCheckAddAccount Then
		writeLogFile($logFile, "LỖI: Pixel check tai X=" & $iCheckPixelX & ", Y=" & $iCheckPixelY & " khong phai mau " & $sCheckPixelColor & " sau " & $iCheckPixelMaxRetry & " lan")
		Return False
	EndIf

	writeLogFile($logFile, "✓ Pixel check tai X=" & $iCheckPixelX & ", Y=" & $iCheckPixelY & " la " & $sCheckPixelColor & ", Step 5 thanh cong")
	secondWait(1)

	Return True
EndFunc   ;==>checkPopupLogin

Func processLoginAccount($sUsername, $sPassword)
	writeLogFile($logFile, "Step 6: processLoginAccount() - clickAddAccount -> inputCredentials -> confirmLogin")

	If Not clickAddAccount() Then
		Return SetError(1, 0, False)
	EndIf

	If Not inputCredentials($sUsername, $sPassword) Then
		Return SetError(2, 0, False)
	EndIf

	If Not confirmLogin() Then
		Return SetError(3, 0, False)
	EndIf

	Return True
EndFunc   ;==>processLoginAccount

Func clickAddAccount()
	writeLogFile($logFile, "Step 6.1: clickAddAccount() - Xoa account vi tri 2 roi them account")

	Local $iDeleteAccountX = getLoginProperty("button_delete_account_x")
	Local $iDeleteAccountY = getLoginProperty("button_delete_account_y")

	Local $iAddAccountX = getLoginProperty("button_add_account_x")
	Local $iAddAccountY = getLoginProperty("button_add_account_y")

	If $iDeleteAccountX = "" Or $iDeleteAccountY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy button_delete_account_x hoặc button_delete_account_y")
		Return False
	EndIf

	If $iAddAccountX = "" Or $iAddAccountY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy button_add_account_x hoặc button_add_account_y")
		Return False
	EndIf

	$iDeleteAccountX = Number($iDeleteAccountX)
	$iDeleteAccountY = Number($iDeleteAccountY)
	$iAddAccountX = Number($iAddAccountX)
	$iAddAccountY = Number($iAddAccountY)
	
	For $i = 1 To 4
		writeLogFile($logFile, "Click xoa account lan " & $i & " tai X=" & $iDeleteAccountX & ", Y=" & $iDeleteAccountY)
		_MU_MouseClick_Delay($iDeleteAccountX, $iDeleteAccountY)
		secondWait(1)
		sendKeyEnter()
		secondWait(2)
	Next

	writeLogFile($logFile, "Click Add Account tại X=" & $iAddAccountX & ", Y=" & $iAddAccountY)
	_MU_MouseClick_Delay($iAddAccountX, $iAddAccountY)
	secondWait(5)

	Return True
EndFunc   ;==>clickAddAccount

Func inputCredentials($sUsername, $sPassword)
	writeLogFile($logFile, "Step 6.2: inputCredentials() - Nhập username và password, chờ rồi Enter")

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
	secondWait(2)

	sendKeyEnter()
	
	secondWait(3)
	Return True
EndFunc   ;==>inputCredentials

Func confirmLogin()
	writeLogFile($logFile, "Step 6.3: confirmLogin() - Click first account")

	Local $iConfirmX = getLoginProperty("first_account_x")
	Local $iConfirmY = getLoginProperty("first_account_y")

	If $iConfirmX = "" Or $iConfirmY = "" Then
		writeLogFile($logFile, "LỖI: Không tìm thấy first_account_x hoặc first_account_y")
		Return False
	EndIf

	$iConfirmX = Number($iConfirmX)
	$iConfirmY = Number($iConfirmY)

	writeLogFile($logFile, "Click first account tại X=" & $iConfirmX & ", Y=" & $iConfirmY)
	_MU_MouseClick_Delay($iConfirmX, $iConfirmY)
	secondWait(5)

	; Thuc hien send key Enter de vao game
	sendKeyEnter()
	secondWait(5)
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

Func verifyCharacterLoaded(ByRef $sCharName)
	writeLogFile($logFile, "Step 10: verifyCharacterLoaded(" & $sCharName & ")")

	; Check character muc tieu dang active hay chua
	If checkActiveWinByChar($sCharName) Then
		writeLogFile($logFile, "✓ Character " & $sCharName & " login ĐÚNG (window active)")
		Return True
	EndIf

	; Dung method trong game_utils de tim character khac cung account dang active
	Local $currentChar = $sCharName
	Local $charNameOtherChar = checkActiveOtherChar($currentChar)
	; $charNameOtherChar: JoyBoy|2 - > charFound: JoyBoy - numberChar: 2
	Local $charFound = StringSplit($charNameOtherChar, "|")[1]
	Local $numberChar = StringSplit($charNameOtherChar, "|")[2]

	writeLogFile($logFile, "verifyCharacterLoaded -> charFound=" & $charFound & " | numberChar=" & $numberChar)

	If $charFound <> "" Then
		writeLogFile($logFile, "✓ Character hợp lệ trong cùng account (active char khác): " & $charFound)
		$sCharName = $charFound
		Return True
	EndIf

	writeLogFile($logFile, "LỖI: Không tìm thấy game window active cho character " & $sCharName)
	Return False
EndFunc   ;==>verifyCharacterLoaded

Func handleWrongCharacter($sUsername, $sPassword, $sCharName, $iServerNo, $accountConfig)
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
	Local $bRetrySuccess = processLogin($sUsername, $sPassword, $sCharName, $iServerNo, $accountConfig)

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


If StringLower(@ScriptName) = "auto_login.au3" Then
	main()
EndIf

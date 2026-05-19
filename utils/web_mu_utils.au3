#include-once
#include <date.au3>
#include <MsgBoxConstants.au3>
#include "../include/_ImageSearch_UDF.au3"
#include <AutoItConstants.au3>
#include "../include/json_utils.au3"
#include <Array.au3>
#include "common_utils.au3"
#include "../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../lib/au3WebDriver-0.12.0/webdriver_utils.au3"

Global $sAppDataPath = @AppDataDir ; Lấy đường dẫn tới thư mục "AppData"

Global $sAppDataLocalPath = StringRegExpReplace($sAppDataPath, "Roaming", "Local") ; Lấy đường dẫn thư mục gốc

Global $sChromeUserDataPath = StringRegExpReplace($sAppDataPath, "Roaming", "Local\\Google\\Chrome\\User Data\") ; Lấy đường dẫn thư mục gốc

;~ Global $baseMuUrl = "https://hn.gamethuvn.net/"

Global $sTitleLoginSuccess = "- Thông báo"
Global $sTitleLoginSuccess_EN = "- Notifications"
Global $sTitleLogoutSuccess = "/ Đăng nhập"
Global $sTitleLogoutSuccess_EN = "/ Sign In"

Local $sApiKey = "ai0xvvkw3hcoyzbgwdu5tmqdaqyjlkjs" ; Key của azcaptcha

Func checkThenCloseChrome()
	checkThenCloseProcess("chrome.exe")
EndFunc   ;==>checkThenCloseChrome

Func checkThenCloseEdge()
	checkThenCloseProcess("msedge.exe")
EndFunc   ;==>checkThenCloseEdge

Func checkThenCloseProcess($chromeProcessName)

	; Kiểm tra xem có tiến trình đang chạy không
	If ProcessExists($chromeProcessName) Then
		; Đóng tất cả các tiến trình
		ProcessClose($chromeProcessName)
		writeLogFile($logFile, "Đã đóng tất cả các procees: " & $chromeProcessName)
	Else
		writeLogFile($logFile, "Không tìm thấy procees đang chạy => " & $chromeProcessName)
	EndIf

	Return True
EndFunc   ;==>checkThenCloseProcess

Func getTitleWebsite($sSession)
	Local $sScript = 'return document.title;'
	Local $jsonString = _WD_ExecuteScript($sSession, $sScript)
	; Tìm vị trí của ký tự đầu tiên và ký tự cuối cùng trong chuỗi giá trị
	Local $startIndex = StringInStr($jsonString, ':"') + 2
	Local $endIndex = StringInStr($jsonString, '"', 0, -1)

	; Trích xuất giá trị từ chuỗi JSON
	Local $value = StringMid($jsonString, $startIndex, $endIndex - $startIndex)
	writeLogFile($logFile, "getTitleWebsite($sSession): " & $value)
	Return $value
EndFunc   ;==>getTitleWebsite

Func checkIp($sSession)
	_WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='alert alert-success']/i[@class='c-icon c-icon-xl cil-shield-alt t-pull-left']", Default, False)
	If @error Then
		writeLogFile($logFile, "IP KHONG CHINH CHU")
		Return False
	EndIf
	Return True
EndFunc   ;==>checkIp

Func login($sSession, $username, $password)
	; vao website
	navigateUrl($sSession, $baseMuUrl)
	;~ secondWait(5)
	; get title
	$sTitle = getTitleWebsite($sSession)
	$timeLoginFail = 0

	; Truong hop $sTitle co chứa chuỗi trong $sTitleLoginSuccess thi kiem tra tiep xem gia tri user name co dung voi bien $username khong
	; Neu khong dung thi thuc hien logout va lay lai $sTitle
	If StringInStr($sTitle, $sTitleLoginSuccess) Or StringInStr($sTitle, $sTitleLoginSuccess_EN) Then
	;~ Phan tu html co dang nhu sau, lay text phan tu trong h4 id="t-account_name_title"
			; <div class="t-account-title">

	;~                   <h4 id="t-account_name_title">maka</h4>
	;~       <h7>(Hà Nội 2003)</h7>


	;~   </div>
		$sElement = findElement($sSession, "//h4[@id='t-account_name_title']")
		$sValue = getTextElement($sSession, $sElement)
		writeLogFile($logFile, "$sValue account login: " & $sValue)
		If $sValue == $username Then
			writeLogFile($logFile, "Login success with account: " & $username)
			Return True
		Else
			writeLogFile($logFile, "Username is different with account login: " & $username & " - " & $sValue)
			_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
			secondWait(5)
			$sTitle = getTitleWebsite($sSession)
			writeLogFile($logFile, "Logout success!")
		EndIf
	EndIf

	While (StringInStr($sTitle, $sTitleLoginSuccess) = 0) And (StringInStr($sTitle, $sTitleLoginSuccess_EN) = 0)
		If $timeLoginFail > 6 Then ExitLoop
		closeDiaglogConfim($sSession)
		loginWebsite($sSession, $username, $password)
		$sTitle = getTitleWebsite($sSession)
		$timeLoginFail = $timeLoginFail + 1
	WEnd

	If (StringInStr($sTitle, $sTitleLoginSuccess) = 0) And (StringInStr($sTitle, $sTitleLoginSuccess_EN) = 0) Then
		Return False
	Else
		writeLogFile($logFile, "Đăng nhập thành công !")
		Return True
	EndIf
EndFunc   ;==>login

Func logout($sSession)
	; 11. Logout account
	$isSuccess = False
	$timeLogoutFail = 0
	$sTitle = getTitleWebsite($sSession)

	While (StringInStr($sTitle, $sTitleLogoutSuccess) = 0) And (StringInStr($sTitle, $sTitleLogoutSuccess_EN) = 0) And ($timeLogoutFail < 3)
		_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
		secondWait(5)
		$sTitle = getTitleWebsite($sSession)
		$timeLogoutFail = $timeLogoutFail + 1
	WEnd

	If (StringInStr($sTitle, $sTitleLogoutSuccess) > 0) Or (StringInStr($sTitle, $sTitleLogoutSuccess_EN) > 0) Then
		writeLogFile($logFile, "Logout success!")
		$isSuccess = True
	Else
		writeLogFile($logFile, "Logout fail!")
	EndIf

	Return $isSuccess
EndFunc   ;==>logout

Func closeDiaglogConfim($sSession)
	$checkConfirmBox = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//button[@class='swal2-confirm swal2-styled']")
	If @error Then
		writeLogFile($logFile, "Không tìm thấy diaglog lỗi !")
	Else
		clickElement($sSession, $checkConfirmBox)
	EndIf
EndFunc   ;==>closeDiaglogConfim

Func loginWebsite($sSession, $username, $password)
	$isSuccess = False

	writeLogFile($logFile, "$username: " & $username & " $password: " & $password)

	_WD_Window($sSession, "MINIMIZE")

	navigateUrl($sSession, $baseMuUrl)
	_WD_LoadWait($sSession, 1000)

	; Fill user name
	$sElement = _WD_GetElementByName($sSession, "username")
	; Truong hop bi loi thi return false
	If @error Then
		writeLogFile($logFile, "Không tìm thấy phần tử username!")
		Return False
	EndIf
	_WD_ElementAction($sSession, $sElement, 'value', 'xxx')
	_WD_ElementAction($sSession, $sElement, 'CLEAR')
	_WD_ElementAction($sSession, $sElement, 'value', $username)
	writeLogFile($logFile, "$sValue: " & _WD_ElementAction($sSession, $sElement, 'value'))

	; Fill password
	$sElement = _WD_GetElementByName($sSession, "password")
	_WD_ElementAction($sSession, $sElement, 'value', 'xxx')
	_WD_ElementAction($sSession, $sElement, 'CLEAR')
	_WD_ElementAction($sSession, $sElement, 'value', $password)

	; Save captcha
	;~ $captchaImgPath = saveCaptchaFromWeb($sSession, "//img[@class='captcha_img']")
	solveImageCaptchaAz($sSession,"//img[@class='captcha_img']", 90, 5)
	checkCaptchaThenSubmit($sSession)
	Return $isSuccess
EndFunc   ;==>loginWebsite

Func checkCaptchaThenSubmit($sSession)
	$sElement = findElement($sSession, "//input[@name='captcha']")
	$sValue = _WD_ElementAction($sSession, $sElement, 'value')
	writeLogFile($logFile, "Giá trị captcha trước khi submit: " & $sValue)
	If $sValue <> "" Then
		writeLogFile($logFile, "Captcha đã được nhập: " & $sValue)
		; Click submit
		_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
		secondWait(2)
	EndIf
	Return True
EndFunc   ;==>checkCaptchaThenSubmit

; Tao function giai ma captcha tu azcaptcha
; Method: solveImageCaptchaAz
; Description: Gửi captcha image lên AzCaptcha và lấy kết quả text
Func solveImageCaptchaAz($sSession, $sImgXpath = "//img[@class='captcha_img']", $iTimeoutSec = 90, $iPollSec = 5)
    writeLogMethodStart("solveImageCaptchaAz", @ScriptLineNumber)

    If $sApiKey = "" Then
        writeLogFile($logFile, "AzCaptcha API key rong!")
        writeLogMethodEnd("solveImageCaptchaAz", @ScriptLineNumber)
        Return SetError(1, 0, "")
    EndIf

    Local $sCaptchaImgPath = saveCaptchaFromWeb($sSession, $sImgXpath)
    If Not FileExists($sCaptchaImgPath) Then
        writeLogFile($logFile, "Khong tim thay file captcha: " & $sCaptchaImgPath)
        writeLogMethodEnd("solveImageCaptchaAz", @ScriptLineNumber)
        Return SetError(2, 0, "")
    EndIf

    Local $sCaptchaId = _azSubmitImageCaptcha($sApiKey, $sCaptchaImgPath)
    If $sCaptchaId = "" Then
        writeLogFile($logFile, "Submit captcha that bai.")
        writeLogMethodEnd("solveImageCaptchaAz", @ScriptLineNumber)
        Return SetError(3, 0, "")
    EndIf

    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < ($iTimeoutSec * 1000)
        secondWait($iPollSec)

        Local $sAnswer = _azGetImageCaptchaResult($sApiKey, $sCaptchaId)
        If @error = 0 And $sAnswer <> "" Then
            writeLogFile($logFile, "Giai captcha thanh cong: " & $sAnswer)
			; Thuc hien truyen du lieu vao input captcha tren web
			; <input type="text" autocomplete="off" class="form-control" name="captcha" placeholder="Captcha">
			$sElement = findElement($sSession, "//input[@name='captcha']")
            _WD_ElementAction($sSession, $sElement, 'value', $sAnswer)
            writeLogMethodEnd("solveImageCaptchaAz", @ScriptLineNumber)
            Return $sAnswer
        ElseIf @error = 10 Then
            ; CAPCHA_NOT_READY -> tiep tuc cho
            ContinueLoop
        Else
            ExitLoop
        EndIf
    WEnd

    writeLogFile($logFile, "Het thoi gian cho ket qua captcha.")
    writeLogMethodEnd("solveImageCaptchaAz", @ScriptLineNumber)
    Return SetError(4, 0, "")
EndFunc   ;==>solveImageCaptchaAz

; Method: _azSubmitImageCaptcha
; Description: Upload file captcha den AzCaptcha in.php (method=post)
Func _azSubmitImageCaptcha($sApiKey, $sImagePath)
	writeLogFile($logFile, "_azSubmitImageCaptcha($sApiKey, $sImagePath): " & $sImagePath)
    Local $oHttp = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If @error Then Return SetError(1, 0, "")

    Local $hFile = FileOpen($sImagePath, 16) ; binary
    If $hFile = -1 Then Return SetError(2, 0, "")
    Local $bFile = FileRead($hFile)
    FileClose($hFile)
    If BinaryLen($bFile) = 0 Then Return SetError(3, 0, "")

    Local $sBoundary = "----AutoItAzCaptcha" & @MSEC & Int(Random(1000, 9999, 1))
    Local $sCRLF = @CRLF
    
    ; Build body parts as binary to avoid encoding issues
    Local $sBodyHeadStr = _
            "--" & $sBoundary & $sCRLF & _
            'Content-Disposition: form-data; name="key"' & $sCRLF & $sCRLF & $sApiKey & $sCRLF & _
            "--" & $sBoundary & $sCRLF & _
            'Content-Disposition: form-data; name="method"' & $sCRLF & $sCRLF & "post" & $sCRLF & _
            "--" & $sBoundary & $sCRLF & _
            'Content-Disposition: form-data; name="json"' & $sCRLF & $sCRLF & "0" & $sCRLF & _
            "--" & $sBoundary & $sCRLF & _
            'Content-Disposition: form-data; name="file"; filename="captcha.png"' & $sCRLF & _
            "Content-Type: application/octet-stream" & $sCRLF & $sCRLF

	writeLogFile($logFile, "Body head length: " & StringLen($sBodyHeadStr) & " bytes, File binary length: " & BinaryLen($bFile) & " bytes")
    
    Local $sBodyTailStr = $sCRLF & "--" & $sBoundary & "--" & $sCRLF
    
    ; Convert strings to binary using proper encoding
    Local $bBodyHead = StringToBinary($sBodyHeadStr, 1) ; 1 = ANSI/ASCII encoding
    Local $bBodyTail = StringToBinary($sBodyTailStr, 1)
    
	; Concatenate binary parts
	Local $bBody = $bBodyHead & $bFile & $bBodyTail
	If Not IsBinary($bBody) Or BinaryLen($bBody) = 0 Then
		writeLogFile($logFile, "Invalid body: not binary or empty")
		Return SetError(3, 0, "")
	EndIf
	writeLogFile($logFile, "Total body binary length: " & BinaryLen($bBody) & " bytes")

	; Retry upload because WinHttp COM object may fail intermittently at Send()
	Local $iErrorCode = 0, $iExtErrorCode = 0, $iTry
	For $iTry = 1 To 3
		$oHttp = ObjCreate("WinHttp.WinHttpRequest.5.1")
		If @error Then
			writeLogFile($logFile, "AzCaptcha in.php ObjCreate failed! try=" & $iTry)
			If $iTry < 3 Then secondWait(1)
			ContinueLoop
		EndIf

		$oHttp.Open("POST", "http://azcaptcha.com/in.php", False)
		$iErrorCode = @error
		If $iErrorCode <> 0 Then
			writeLogFile($logFile, "AzCaptcha in.php Open failed! try=" & $iTry & " err=" & $iErrorCode & " ext=" & @extended)
			If $iTry < 3 Then secondWait(1)
			ContinueLoop
		EndIf

		$oHttp.SetTimeouts(30000, 30000, 30000, 60000)
		$oHttp.SetRequestHeader("Content-Type", "multipart/form-data; boundary=" & $sBoundary)
		$oHttp.SetRequestHeader("Content-Length", BinaryLen($bBody))
		$oHttp.SetRequestHeader("User-Agent", "AutoIt WinHttpRequest")

		$oHttp.Send($bBody)
		$iErrorCode = @error
		If $iErrorCode = 0 Then ExitLoop

		$iExtErrorCode = @extended
		writeLogFile($logFile, "AzCaptcha in.php Send failed! try=" & $iTry & " err=" & $iErrorCode & " ext=" & $iExtErrorCode)
		If $iTry < 3 Then secondWait(1)
	Next

	If $iErrorCode <> 0 Then
		writeLogFile($logFile, "AzCaptcha in.php request failed after retries!")
		Return SetError(4, 0, "")
	EndIf

    Local $sResp = $oHttp.ResponseText
    If Not IsString($sResp) Or $sResp = "" Then
        writeLogFile($logFile, "AzCaptcha in.php response empty or invalid!")
        Return SetError(4, 0, "")
    EndIf
    $sResp = StringStripWS($sResp, 3)
    writeLogFile($logFile, "AzCaptcha in.php resp: " & $sResp)

    If StringLen($sResp) >= 3 And StringLeft($sResp, 3) = "OK|" Then
        Return StringTrimLeft($sResp, 3)
    EndIf

    Return SetError(4, 0, "")
EndFunc   ;==>_azSubmitImageCaptcha

; Method: _azGetImageCaptchaResult
; Description: Poll ket qua tu AzCaptcha res.php
Func _azGetImageCaptchaResult($sApiKey, $sCaptchaId)
	Local $sUrl = "http://azcaptcha.com/res.php?key=" & $sApiKey & "&action=get&id=" & $sCaptchaId
	Local $oHttp, $iTry, $iErr
	For $iTry = 1 To 3
		$oHttp = ObjCreate("WinHttp.WinHttpRequest.5.1")
		If @error Then
			writeLogFile($logFile, "AzCaptcha res.php ObjCreate failed! try=" & $iTry)
			If $iTry < 3 Then secondWait(1)
			ContinueLoop
		EndIf

		$oHttp.Open("GET", $sUrl, False)
		$iErr = @error
		If $iErr <> 0 Then
			writeLogFile($logFile, "AzCaptcha res.php Open failed! try=" & $iTry & " err=" & $iErr & " ext=" & @extended)
			If $iTry < 3 Then secondWait(1)
			ContinueLoop
		EndIf

		$oHttp.SetTimeouts(30000, 30000, 30000, 60000)
		$oHttp.SetRequestHeader("User-Agent", "AutoIt WinHttpRequest")
		$oHttp.Send()
		$iErr = @error
		If $iErr = 0 Then ExitLoop

		writeLogFile($logFile, "AzCaptcha res.php Send failed! try=" & $iTry & " err=" & $iErr & " ext=" & @extended)
		If $iTry < 3 Then secondWait(1)
	Next

	If $iErr <> 0 Then
		writeLogFile($logFile, "AzCaptcha res.php request failed after retries!")
		Return SetError(1, 0, "")
	EndIf

	Local $sResp = $oHttp.ResponseText
    If Not IsString($sResp) Or $sResp = "" Then
        writeLogFile($logFile, "AzCaptcha res.php response empty or invalid!")
        Return SetError(2, 0, "")
    EndIf
    $sResp = StringStripWS($sResp, 3)
    writeLogFile($logFile, "AzCaptcha res.php resp: " & $sResp)

    If $sResp = "CAPCHA_NOT_READY" Then Return SetError(10, 0, "")
    If StringLen($sResp) >= 3 And StringLeft($sResp, 3) = "OK|" Then Return StringTrimLeft($sResp, 3)

    Return SetError(2, 0, "")
EndFunc   ;==>_azGetImageCaptchaResult

Func closeOtherTabs($sSession, $attachedTabHandle)
	; Lấy danh sách tất cả các tab
	Local $aHandles = _WD_Window($sSession, "handles")
	If @error Then
		writeLogFile($logFile, "Không thể lấy danh sách tab.")
		Return False
	EndIf

	; Lặp qua tất cả các tab và đóng các tab không phải là tab đã gắn kết
	For $sHandle In $aHandles
		If $sHandle <> $attachedTabHandle Then
			_WD_Window($sSession, "close", '{"handle":"' & $sHandle & '"}')
			writeLogFile($logFile, "Đã đóng tab: " & $sHandle)
		EndIf
	Next

	Return True
EndFunc   ;==>closeOtherTabs

Func getLogReset($sSession, $charName)
	; Call getLogResetCommon nếu trả về false thì thực hiện retry lại 2 lần nhé
	For $i = 0 To 1
		$sLogReset = getLogResetCommon($sSession, $charName)
		If $sLogReset Then
			Return $sLogReset
		EndIf
		writeLogFile($logFile, "Lấy log reset thất bại, thực hiện retry lần thứ " & ($i + 1))
	Next
	Return 0 & "|" & '' & "|" & 0 & "|" & 0 & "|" & 0
EndFunc

; Format: $rsInDay|$timeReset
Func getLogResetCommon($sSession, $charName)
	Local $charLvl, $rsInDay, $aMatch
	; Chuyen den site nay de thuc hien check thong tin
	_WD_Navigate($sSession, combineUrl("web/char/char_info.shtml"))
	_WD_LoadWait($sSession, 1000)

	; Kiem tra trang thai online. ; Kiem tra trong div co href="/web/char/char_info.detail.shtml?name=PhapSuNhi" co chua class="text-success" hay khong 
	; Day la text html:
	;~ <div class="col-4 col-md-2 col-sm-3 pb-3" href="/web/char/char_info.detail.shtml?name=PhapSuNhi" target="#t-char_info_detail" style="cursor: pointer;">

	;~ 				<div class="d-flex justify-content-center"><img src="/assets/img/char_icon/07_a.png" style="width: 100%; max-width: 90px;"></div>
	;~ 				<p class="text-center mb-2 mt-1">
	;~ 					Reset: <b>614</b> lần<br>
	;~ 											<span class="text-success">Online (sS15)</span>
	;~ 										</p>
	;~ 				<button class="btn 
	;~ 											btn-secondary 
	;~ 											btn-sm btn-block t-char_info_btn">PhapSuNhi</button>
	;~ 			</div>
	; Click vao button nhan vat can check
	
	;~ $checkOnlineStatus = findElement($sSession, "//div[@href='/web/char/char_info.detail.shtml?name=" & $charName & "']//span[contains(@class,'text-success')]")
	;~ If @error Then
	;~ 	writeLogFile($logFile, "Nhân vật " & $charName & " đang offline!")
	;~ 	Return False
	;~ Else
	;~ 	writeLogFile($logFile, "Nhân vật " & $charName & " đang online!")
	;~ EndIf

	$sElement = findElement($sSession, "//button[contains(text(),'" & $charName & "')]")
	clickElement($sSession, $sElement)
	;~ _WD_LoadWait($sSession, 1000)
	secondWait(2)

	; Thong tin lvl, so lan trong ngay/ thang
	$sElement = findElement($sSession, "//div[@role='alert']")
	$charInfoText = getTextElement($sSession, $sElement)
	writeLogFile($logFile, "$charInfoText: " & $charInfoText)
	; Truong hop $charInfoText empty thi return false
	If $charInfoText == "" Then
		writeLogFile($logFile, "Không lấy được thông tin nhân vật từ web!")
		Return False
	EndIf
;~ 	$charInfoText: Reset 1160 lần, point dư: 20,000
;~ Level Master: 538, skill_3: 0, skill_4: 0, level thuộc tính: 8, điểm quả: 0
;~ xxx11 level 400 (Hôm nay reset 3 lượt. Tháng này reset 101 lượt)

	; $currentReset so o giua tri Reset va lần. trong ví dụ trên là 1160
	Local $tempSplit = StringSplit($charInfoText, "Reset ", 1)
	Local $resetPart = $tempSplit[2] ; Lấy phần sau "Reset "
	Local $currentReset = Number(StringSplit($resetPart, " lần", 1)[1])
	writeLogFile($logFile, "currentReset: " & $currentReset)
	; Lvl
	$aMatch = StringRegExp($charInfoText, "level (\d+)\s*\(", 1)

	If @error Then
		ConsoleWrite("Không tìm thấy level!" & @CRLF)
	Else
		ConsoleWrite("Lvl: " & $aMatch[0] & @CRLF)
		$charLvl = $aMatch[0]
	EndIf
	
	$aMatch = StringRegExp($charInfoText, "reset (\d+)\s*lượt", 1)
	If @error Then
		ConsoleWrite("Không tìm lượt rs!" & @CRLF)
	Else
		ConsoleWrite("Số cần lấy là: " & $aMatch[0] & @CRLF)
		$rsInDay = $aMatch[0]
	EndIf

	; Xem Nhat ky reset
	navigateUrl($sSession, combineUrl("web/char/char_info.logreset.shtml"))
	; Get element
	$sElement = findElement($sSession, "//table[@class='table table-striped table-sm table-hover w-100']/tbody/tr/td[6]")
	$timeRsText = getTextElement($sSession, $sElement)
	writeLogFile($logFile, "$timeRsText: " & $timeRsText)

	$sElement = findElement($sSession, "//table[@class='table table-striped table-sm table-hover w-100']/tbody/tr/td[3]")
	$sRsCount = getTextElement($sSession, $sElement)

	writeLogFile($logFile, "Info $charLvl: " & $charLvl & " - $rsInDay: " & $rsInDay & " - $sRsCount: " & $sRsCount)

	Return Number($rsInDay) & "|" & $timeRsText & "|" & Number($sRsCount) & "|" & Number($currentReset) & "|" & Number($charLvl)
EndFunc

Func getRsInDay($sLogReset)
	Return Number(StringSplit($sLogReset, "|")[1])
EndFunc   ;==>getRsInDay

Func getRsCount($sLogReset)
	Return Number(StringSplit($sLogReset, "|")[3])
EndFunc   ;==>getRsCount

Func getCurrentReset($sLogReset)
	Return Number(StringSplit($sLogReset, "|")[4])
EndFunc   ;==>getCurrentReset

Func getCurrentlvl($sLogReset)
	Return Number(StringSplit($sLogReset, "|")[5])
EndFunc   ;==>getCurrentReset

Func getTimeReset($sLogReset, $hourPerRs)
	; $sLogReset loi = "3|07/07/2021 00:00:00|99"
	; $sLogReset dung = "5|14h39 08/11|631 - 0"
	writeLogFile($logFile, "getTimeReset($sLogReset, $hourPerRs): " & $sLogReset & " - " & $hourPerRs)
	$timeRsText = StringSplit($sLogReset, "|")[2]
	; 14h39 08/11
	$month = StringRight($timeRsText, 2)
	$day = StringMid($timeRsText, 7, 2)
	$hour = StringLeft($timeRsText, 2)
	$min = StringMid($timeRsText, 4, 2)

	writeLogFile($logFile, "month: " & $month & " - day: " & $day & " - hour: " & $hour & " - min: " & $min)
	$nextTimeRs = _DateAdd('h', $hourPerRs, @YEAR & "/" & $month & "/" & $day & " " & $hour & ":" & $min & ":00")
	writeLogFile($logFile, "nextTimeRs: " & $nextTimeRs)
	Return $nextTimeRs
EndFunc   ;==>getTimeReset

Func getUrlAuction($sId)
	Return $baseMuUrl & "web/event/boss-item-bid.item.shtml?id=" & $sId
EndFunc   ;==>getUrlAuction

Func moveToPostionInWeb($sSession, $charNameWeb, $x, $y)
	; Chuyen den trang web $baseMuUrl
	_WD_Navigate($sSession, $baseMuUrl)
	secondWait(5)
	; Check xem co IP hay khong
	$isHaveIP = checkIp($sSession)
	; Neu co IP thi thuc hien tiep, khong thi ghi log va return
	If $isHaveIP = False Then
		writeLogFile($logFile, "Khong co IP khong the thuc hien chuyen dong")
		Return False
	Else
		; Thuc hien chuyen den trang web /control
		_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charNameWeb)
		secondWait(5)
		$sElement = findElement($sSession, "//div[@id='t-player-text-info']")
		$cmdText = getTextElement($sSession, $sElement)
		writeLogFile($logFile, "cmdText full: " & $cmdText)
		Local $aMatch = StringRegExp($cmdText, "(\d+)\s*lệnh", $STR_REGEXPARRAYMATCH)
		Local $iSoLenh = 0
		If @error Or UBound($aMatch) = 0 Then
			writeLogFile($logFile, "Không tìm thấy số lượng lệnh" & @CRLF)
		Else
			$iSoLenh = $aMatch[0]
			writeLogFile($logFile, "Số lệnh còn lại: " & $iSoLenh & @CRLF)
		EndIf
		$cmdAmount = Number($iSoLenh)
		If $cmdAmount < 5 Then
			writeLogFile($logFile, "Khong du lenh de thuc hien chuyen dong. So lenh con lai: " & $cmdAmount)
			Return False
		EndIf

		; Thuc hien di toi toa do X
		$sElement = _WD_GetElementByName($sSession, "tx")
		_WD_ElementAction($sSession, $sElement, 'CLEAR')
		secondWait(1)
		_WD_ElementAction($sSession, $sElement, 'value', $x)

		; Thuc hien di toi toa do Y
		$sElement = _WD_GetElementByName($sSession, "ty")
		_WD_ElementAction($sSession, $sElement, 'CLEAR')
		secondWait(1)
		_WD_ElementAction($sSession, $sElement, 'value', $y)

		; Bam button chay ( submit )
		$sElement = findElement($sSession, "//button[@type='submit']")
		clickElement($sSession, $sElement)

		; close diaglog
		closeDiaglogConfim($sSession)

		writeLogFile($logFile, "Di chuyen den vi tri X: " & $x & " - Y: " & $y & " thanh cong!" & @CRLF)
		; Doi 2 phut roi kiem tra lai auto z
		minuteWait(2)
		; Kiem tra auto z con hoat dong khong
		Return checkAutoZEnable($sSession, $charNameWeb)
	EndIf
EndFunc   ;==>moveToPostionInWeb

Func logoutAndCloseChromeDriver($sSession)
	logout($sSession)
	secondWait(5)
	; Close webdriver neu thuc hien xong
	If $sSession Then _WD_DeleteSession($sSession)

	_WD_Shutdown()
EndFunc   ;==>logoutAndCloseChromeDriver

Func checkAutoZEnable($sSession, $charName)
	; 1️⃣ Tìm thẻ div với class 't-auto_helper'
	writeLogFile($logFile, "Bắt đầu kiểm tra Auto Z có được kích hoạt không...")
	; Vao trang check lvl
	_WD_Navigate($sSession, $baseMuUrl & "web/char/control.shtml?char=" & $charName)
	secondWait(5)
	; 2️⃣ Lấy thuộc tính style của thẻ
	Local $sElementAutoZ = findElement($sSession, "//div[@class='t-auto_helper']")
	If @error Then
		writeLogFile($logFile, "Không tìm thấy thẻ t-auto_helper => Auto Z khong hoat dong => Ket thuc xu ly reset !")
		Return False
	EndIf

	Local $styleAutoZ = _WD_ElementAction($sSession, $sElementAutoZ, 'getAttribute', 'style')
	writeLogFile($logFile, "styleAutoZ: " & $styleAutoZ)
	; 3️⃣ Kiểm tra xem có 'display: none' không
	If StringInStr($styleAutoZ, "display: none") Then
		writeLogFile($logFile, "❌ Thẻ đang bị ẩn (display: none) => Auto Z khong hoat dong => Ket thuc xu ly reset !")
		Return False
	Else
		writeLogFile($logFile, "✅ Thẻ đang hiển thị" & @CRLF)
		Return True
	EndIf
EndFunc   ;==>checkAutoZEnable

Func resetInWeb($sSession, $oAccountInfo)
	$charName = $oAccountInfo.Item("charName")
	$resetOnline = $oAccountInfo.Item("resetOnline")
	writeLogFile($logFile, "resetInWeb: Bắt đầu thực hiện reset cho nhân vật " & $charName & " - resetOnline: " & $resetOnline)
	; 2. Reset in web
	; Dien $sXpath theo html duoi
	;~ <h3 class="card-title"><i class="c-icon c-icon-xl cil-education"></i> Reset nhân vật</h3>
	$sXpath = '//h3[contains(.,"Reset nhân vật")]'
	navigateUrl($sSession, $baseMuUrl & "web/char/reset.shtml?char=" & $charName, $sXpath)
	secondWait(5)
	If $resetOnline Then
		; Click radio online
		_WD_ExecuteScript($sSession, "$(""input[name='rsonline']"").click()")
		secondWait(2)
	EndIf
	; Click radio rs vip
	_WD_ExecuteScript($sSession, "$(""input[name='rstype']"")[" & $oAccountInfo.Item("typeRs") & "].click()")
	; Thuc hien lay captcha va submit
	solveImageCaptchaAz($sSession, "//img[@class='captcha_img']", 90, 5)
	;~ secondWait(15)
	; Kiem tra xem o captcha da dc nhap chua, neu chua thi thuc hien doi 1p roi check lai
	;~ <input type="text" autocomplete="off" class="form-control" name="captcha" placeholder="Captcha">
	$sElement = findElement($sSession, "//input[@name='captcha']")
	$sValue = _WD_ElementAction($sSession, $sElement, 'value')
	writeLogFile($logFile, "Giá trị captcha trước khi submit: " & $sValue)
	If $sValue == "" Then
		writeLogFile($logFile, "Captcha chưa được nhập, đợi 1 phút rồi kiểm tra lại...")
		minuteWait(1)
		$sValue = _WD_ElementAction($sSession, $sElement, 'value')
		writeLogFile($logFile, "Giá trị captcha sau khi đợi 1 phút: " & $sValue)
		If $sValue == "" Then
			writeLogFile($logFile, "Captcha vẫn chưa được nhập sau 1 phút, không thể thực hiện reset!")
			Return False
		EndIf
	Else
		writeLogFile($logFile, "Captcha đã được nhập: " & $sValue)
		; Click submit
		_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
		secondWait(2)
	EndIf

	; Trong truong hop khong phai rs online = true thi moi thuc hien check add point
	If Not $resetOnline Then
		; Click submit
		_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
		secondWait(1)
		; Vao trang add point thuc hien lai 1 lan nua cho chac
		; <h3 class="card-title"><i class="c-icon c-icon-xl cil-playlist-add"></i> Cộng điểm nhanh</h3>
		;~ addPointReset($sSession)
	EndIf

	; close diaglog confirm
	closeDiaglogConfim($sSession)
	Return True
EndFunc   ;==>resetInWeb

Func goPageBuffChar($sSession)
	; https://hn.mugamethuvn.info/web/char/charbuff.shtml
	writeLogFile($logFile, "Begin buff char ")
	_WD_Navigate($sSession, $baseMuUrl & "web/char/charbuff.shtml")
	secondWait(5)
	_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
	secondWait(2)
	; close diaglog confirm
	closeDiaglogConfim($sSession)
EndFunc   ;==>goPageBuffChar

Func saveCaptchaFromWeb($sSession, $classCaptchaSelect)
	; Save captcha
	$captchaImgPath = @ScriptDir & "\captcha_img.png" ;
	; Find image captcha
	$sElement = findElement($sSession, $classCaptchaSelect)
	_WD_DownloadImgFromElement($sSession, $sElement, $captchaImgPath)
	secondWait(3)
	Return $captchaImgPath
EndFunc

Func navigateUrl($sSession, $sURL, $sXpath = "")
	_WD_Navigate($sSession, $sURL)
	Local $iResult = _WD_LoadWait($sSession)

	If $iResult = 1 And @error = 0 Then
		ConsoleWrite("Fully loaded URL: " & $sURL & @CRLF)
		Return True
	Else
		ConsoleWrite("Load failed URL: " & $sURL & @CRLF)
		Return False
	EndIf
EndFunc

Func addPointReset($sSession)
	$sXpath = '//h3[contains(.,"Cộng điểm nhanh")]'
	$urlAddPoint = $baseMuUrl & "web/char/char/addpoint.shtml"
	$result = navigateUrl($sSession, $urlAddPoint, $sXpath)
	If Not $result Then
		writeLogFile($logFile, "Không thể vào trang cộng điểm nhanh sau khi reset!")
		Return False
	Else
		; Click submit add point
		_WD_ExecuteScript($sSession, "$(""button[type='submit']"").click();")
		secondWait(1)
		; close diaglog confirm
		closeDiaglogConfim($sSession)
		 writeLogFile($logFile, "Cộng điểm nhanh thành công sau khi reset!")
		Return True
	EndIf
EndFunc
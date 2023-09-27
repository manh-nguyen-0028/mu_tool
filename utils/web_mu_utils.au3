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

Local $sAppDataPath = @AppDataDir ; Lấy đường dẫn tới thư mục "AppData"

Global $sAppDataLocalPath = StringRegExpReplace($sAppDataPath, "Roaming", "Local") ; Lấy đường dẫn thư mục gốc

Global $sChromeUserDataPath = StringRegExpReplace($sAppDataPath, "Roaming", "Local\\Google\\Chrome\\User Data\") ; Lấy đường dẫn thư mục gốc

Global $baseMuUrl = "https://hn.gamethuvn.net/"

Global $sTitleLoginSuccess = "MU Hà Nội 2003 | GamethuVN.net - Season 15 - Thông báo"

Func checkThenCloseChrome()
	Local $chromeProcessName = "chrome.exe"

	; Kiểm tra xem có trình duyệt Chrome đang chạy không
	If ProcessExists($chromeProcessName) Then
		; Đóng tất cả các tiến trình trình duyệt Chrome
		ProcessClose($chromeProcessName)
		;~ MsgBox($MB_ICONINFORMATION, "Thông báo", "Đã đóng tất cả các trình duyệt Chrome.")
		writeLog("Đã đóng tất cả các trình duyệt Chrome.")
	Else
		;~ MsgBox($MB_ICONINFORMATION, "Thông báo", "Không tìm thấy trình duyệt Chrome đang chạy.")
		writeLog("Không tìm thấy trình duyệt Chrome đang chạy.")
	EndIf
	
	Return True
EndFunc

Func getTitleWebsite($sSession)
	Local $sScript = 'return document.title;'
	Local $jsonString = _WD_ExecuteScript($sSession, $sScript)
	; Tìm vị trí của ký tự đầu tiên và ký tự cuối cùng trong chuỗi giá trị
	Local $startIndex = StringInStr($jsonString, ':"') + 2
	Local $endIndex = StringInStr($jsonString, '"', 0, -1)

	; Trích xuất giá trị từ chuỗi JSON
	Local $value = StringMid($jsonString, $startIndex, $endIndex - $startIndex)
	writeLog("getTitleWebsite($sSession): " & $value)
	Return $value
EndFunc

Func checkIp($sSession, $_WD_LOCATOR_ByXPath)
	$isHaveIP = True
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='alert alert-success']/i[@class='c-icon c-icon-xl cil-shield-alt t-pull-left']", Default, False)
	If @error Then
		writeLogFile($logFile, "IP KHONG CHINH CHU")
		$isHaveIP = False
	EndIf
	Return $isHaveIP
EndFunc

Func login($sSession, $username, $password, $charName)
	; vao website
	_WD_Navigate($sSession, $baseMuUrl)
	secondWait(5)
	; get title
	$sTitle = getTitleWebsite($sSession)
	$timeLoginFail = 0
	
	While $sTitle <> $sTitleLoginSuccess
		If $timeLoginFail > 10 Then ExitLoop
		$checkConfirmBox = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//button[@class='swal2-confirm swal2-styled']")
		If @error Then
			writeLogFile($logFile, "Không tìm thấy diaglog lỗi !")
		Else
			clickElement($sSession, $checkConfirmBox)
		EndIf
		loginWebsite($sSession,$username, $password, $charName)
		$sTitle = getTitleWebsite($sSession)
		$timeLoginFail = $timeLoginFail + 1
	WEnd

	If $sTitle <> $sTitleLoginSuccess Then
		Return False
	Else
		writeLogFile($logFile, "Đăng nhập thành công !")
		Return True
	EndIf
EndFunc

Func loginWebsite($sSession,$username, $password, $charName)
	$isSuccess = False

	writeLog("$username: "&$username & " $password: "&$password)

	_WD_Window($sSession,"MINIMIZE")

	_Demo_NavigateCheckBanner($sSession, $baseUrl)
    _WD_LoadWait($sSession, 1000)

	; Fill user name
	$sElement = _WD_GetElementByName($sSession,"username")
	_WD_ElementAction($sSession, $sElement, 'value','xxx')
	_WD_ElementAction($sSession, $sElement, 'CLEAR')
	secondWait(2)
	_WD_ElementAction($sSession, $sElement, 'value',$username)
	writeLog("$sValue: " & _WD_ElementAction($sSession, $sElement, 'value'))
	
	; Fill password
	$sElement = _WD_GetElementByName($sSession,"password") 
	_WD_ElementAction($sSession, $sElement, 'value','xxx')
	_WD_ElementAction($sSession, $sElement, 'CLEAR')
	secondWait(2)
	_WD_ElementAction($sSession, $sElement, 'value',$password)

	; Save captcha
	$captchaImgPath = @ScriptDir & "\captcha_img.png";
	; Find image captcha
	$sElement = findElement($sSession, "//img[@class='captcha_img']")
	_WD_DownloadImgFromElement($sSession, $sElement, $captchaImgPath)

	If @error = $_WD_ERROR_Success Then 
		$idCaptchaFinal = ''
		; Get captcha buoc 2 => call server captcha 
		While $idCaptchaFinal == '' Or StringLen($idCaptchaFinal) > 4
			$sFilePath = "file:///" & $inputPathRoot & "/get_captcha.html"

			; Get captcha buoc 1
			createNewTab($sSession,optimizeUrl($sFilePath))
			_WD_Window($sSession,"MINIMIZE")
			; select captcha
			_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='file']", $captchaImgPath)
			; Submit get id from azcaptcha
			$sElement = findElement($sSession, "//input[@type='submit']")
			clickElement($sSession, $sElement)
			; get text
			$sElement = findElement($sSession, "//body")
			$idCaptcha = getTextElement($sSession, $sElement)
			$idCaptcha = StringReplace($idCaptcha, "OK|", "")
			secondWait(2)

			; Get captcha buoc 2
			$serverCaptcha = "http://azcaptcha.com/res.php?key=ai0xvvkw3hcoyzbgwdu5tmqdaqyjlkjs&action=get&id=" & $idCaptcha
			_Demo_NavigateCheckBanner($sSession, $serverCaptcha)
			_WD_Window($sSession,"MINIMIZE")
			; get text
			$sElement = findElement($sSession, "//body")
			$idCaptchaFinal = getTextElement($sSession, $sElement)
			$idCaptchaFinal = StringReplace($idCaptchaFinal, "OK|", "")
			writeLog("Captcha value: " & $idCaptchaFinal)
			secondWait(1)
		WEnd
		
		; Chuyen lai tab ve gamethuvn.net
		writeLog("Chuyen lai tab ve hn.gamethuvn.net")
		_WD_Attach($sSession, "hn.gamethuvn.net", "URL")
		
		_WD_Window($sSession,"MINIMIZE")

		writeLog("wd_demo.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)
		; set input captcha
		$sElement = findElement($sSession, "//input[@name='captcha']") 
		_WD_ElementAction($sSession, $sElement, 'value',$idCaptchaFinal)
		secondWait(1)
		; Submit to login
		$sElement = findElement($sSession, "//button[@type='submit']") 
		clickElement($sSession, $sElement)
		secondWait(5)
	EndIf

	Return True
EndFunc
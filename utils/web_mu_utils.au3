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

;~ Global $baseMuUrl = "https://hn.gamethuvn.net/"

Global $sTitleLoginSuccess = "MU Hà Nội 2003 | GamethuVN.net - Season 15 - Thông báo"
Global $sTitleLoginSuccess_EN = "MU Hà Nội 2003 | GamethuVN.net - Season 15 - Notifications"
Global $sTitleLogoutSuccess = "MU Hà Nội 2003 | GamethuVN.net - Season 15 - GamethuVN.com / Đăng nhập"
Global $sTitleLogoutSuccess_EN = "MU Hà Nội 2003 | GamethuVN.net - Season 15 - GamethuVN.com / Sign In"

Func checkThenCloseChrome()
	checkThenCloseProcess("chrome.exe")
EndFunc

Func checkThenCloseEdge()
	checkThenCloseProcess("msedge.exe")
EndFunc

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
EndFunc

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
EndFunc

Func checkIp($sSession)
	$isHaveIP = True
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='alert alert-success']/i[@class='c-icon c-icon-xl cil-shield-alt t-pull-left']", Default, False)
	If @error Then
		writeLogFile($logFile, "IP KHONG CHINH CHU")
		$isHaveIP = False
	EndIf
	Return $isHaveIP
EndFunc

Func login($sSession, $username, $password)
	; vao website
	_WD_Navigate($sSession, $baseMuUrl)
	secondWait(5)
	; get title
	$sTitle = getTitleWebsite($sSession)
	$timeLoginFail = 0

	; Truong hop $sTitle = $sTitleLoginSuccess thi kiem tra tiep xem gia tri user name co dung voi bien $username khong
	; Neu khong dung thi thuc hien logout va lay lai $sTitle
	If ($sTitle == $sTitleLoginSuccess) Or ($sTitle == $sTitleLoginSuccess_EN) Then
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
	
	While ($sTitle <> $sTitleLoginSuccess) And ($sTitle <> $sTitleLoginSuccess_EN)
		If $timeLoginFail > 6 Then ExitLoop
		closeDiaglogConfim($sSession)
		loginWebsite($sSession,$username, $password)
		$sTitle = getTitleWebsite($sSession)
		$timeLoginFail = $timeLoginFail + 1
	WEnd

	If ($sTitle <> $sTitleLoginSuccess) And ($sTitle <> $sTitleLoginSuccess_EN) Then
		Return False
	Else
		writeLogFile($logFile, "Đăng nhập thành công !")
		Return True
	EndIf
EndFunc

Func logout($sSession)
	; 11. Logout account
	$isSuccess = False
	$timeLogoutFail = 0
	$sTitle = getTitleWebsite($sSession)

	While ($sTitle <> $sTitleLogoutSuccess) And ($sTitle <> $sTitleLogoutSuccess_EN) And ($timeLogoutFail < 3)
		_WD_Navigate($sSession, $baseMuUrl & "account/logout.shtml")
		secondWait(5)
		$sTitle = getTitleWebsite($sSession)
		$timeLogoutFail = $timeLogoutFail + 1
	WEnd

	If ($sTitle == $sTitleLogoutSuccess) Or ($sTitle == $sTitleLogoutSuccess_EN) Then
		writeLogFile($logFile, "Logout success!")
		$isSuccess = True
	Else
		writeLogFile($logFile, "Logout fail!")
	EndIf
	
	Return $isSuccess
EndFunc

Func closeDiaglogConfim($sSession)
	$checkConfirmBox = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//button[@class='swal2-confirm swal2-styled']")
	If @error Then
		writeLogFile($logFile, "Không tìm thấy diaglog lỗi !")
	Else
		clickElement($sSession, $checkConfirmBox)
	EndIf
EndFunc

Func loginWebsite($sSession,$username, $password)
	$isSuccess = False

	writeLogFile($logFile, "$username: " & $username & " $password: " & $password)

	_WD_Window($sSession,"MINIMIZE")

	_Demo_NavigateCheckBanner($sSession, $baseMuUrl)
    _WD_LoadWait($sSession, 1000)

	; Fill user name
	$sElement = _WD_GetElementByName($sSession,"username")
	_WD_ElementAction($sSession, $sElement, 'value','xxx')
	_WD_ElementAction($sSession, $sElement, 'CLEAR')
	;~ secondWait(1)
	_WD_ElementAction($sSession, $sElement, 'value',$username)
	writeLogFile($logFile, "$sValue: " & _WD_ElementAction($sSession, $sElement, 'value'))
	
	; Fill password
	$sElement = _WD_GetElementByName($sSession,"password") 
	_WD_ElementAction($sSession, $sElement, 'value','xxx')
	_WD_ElementAction($sSession, $sElement, 'CLEAR')
	;~ secondWait(1)
	_WD_ElementAction($sSession, $sElement, 'value',$password)

	; Save captcha
	$captchaImgPath = @ScriptDir & "\captcha_img.png";
	; Find image captcha
	$sElement = findElement($sSession, "//img[@class='captcha_img']")
	_WD_DownloadImgFromElement($sSession, $sElement, $captchaImgPath)

	If @error = $_WD_ERROR_Success Then 
		$idCaptchaFinal = ''
		$timeCheck = 0
		
		; Get captcha buoc 2 => call server captcha 
		While ($idCaptchaFinal == '' Or StringLen($idCaptchaFinal) > 4) And $timeCheck < 5
			$timeCheck += 1
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
			; $idCaptcha phai la dang so, neu khong thi Chuyen lai tab ve $baseMuUrl va set $isSuccess = False sau do ket thuc method
			If Not checkIsNumber($idCaptcha) Then
				writeLogFile($logFile, "Captcha value is not number: " & $idCaptcha)
				writeLogFile($logFile, "Chuyen lai tab ve " & $baseMuUrl)
				_WD_Attach($sSession, $baseMuUrl, "URL")
				_WD_Window($sSession,"MINIMIZE")
				$isSuccess = False
				ExitLoop
			Else
				; Get captcha buoc 2
				$serverCaptcha = "http://azcaptcha.com/res.php?key=ai0xvvkw3hcoyzbgwdu5tmqdaqyjlkjs&action=get&id=" & $idCaptcha
				_Demo_NavigateCheckBanner($sSession, $serverCaptcha)
				_WD_Window($sSession,"MINIMIZE")
				; get text
				$sElement = findElement($sSession, "//body")
				$idCaptchaFinal = getTextElement($sSession, $sElement)
				$idCaptchaFinal = StringReplace($idCaptchaFinal, "OK|", "")
				writeLogFile($logFile, "Captcha value: " & $idCaptchaFinal)
				secondWait(1)
			EndIf
		WEnd
		
		If StringLen($idCaptchaFinal) == 4 Then $isSuccess = True

		; Chuyen lai tab ve gamethuvn.net
		writeLogFile($logFile, "Chuyen lai tab ve " & $baseMuUrl)
		
		; Gắn kết với tab chứa URL cụ thể
		Local $attachedTabHandle = _WD_Attach($sSession, $baseMuUrl, "URL")
		If @error Then
			writeLogFile($logFile, "Không thể gắn kết với tab chứa URL: " & $baseMuUrl)
		Else
			writeLogFile($logFile, "Đã gắn kết với tab: " & $attachedTabHandle)

			; Đóng các tab khác
			closeOtherTabs($sSession, $attachedTabHandle)
		EndIf
		
		_WD_Window($sSession,"MINIMIZE")

		writeLogFile($logFile, "web_mu_utils.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)

		; set input captcha
		$sElement = findElement($sSession, "//input[@name='captcha']") 
		_WD_ElementAction($sSession, $sElement, 'value',$idCaptchaFinal)
		secondWait(1)

		; Submit to login
		$sElement = findElement($sSession, "//button[@type='submit']") 
		clickElement($sSession, $sElement)
		secondWait(5)
	EndIf

	Return $isSuccess
EndFunc

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
EndFunc

; Format: $rsInDay|$timeReset
Func getLogReset($sSession, $charName)
	Local $charLvl, $rsInDay, $aMatch
	; Chuyen den site nay de thuc hien check thong tin
	_WD_Navigate($sSession, combineUrl("web/char/char_info.shtml"))
	;~ _Demo_NavigateCheckBanner($sSession, combineUrl("web/char/char_info.shtml"))
	_WD_LoadWait($sSession, 1000)

	; Click vao button nhan vat can check 
	$sElement = findElement($sSession, "//button[contains(text(),'"& $charName &"')]")
	clickElement($sSession, $sElement)
	secondWait(5)

	; Thong tin lvl, so lan trong ngay/ thang
	$sElement = findElement($sSession, "//div[@role='alert']")
	$charInfoText = getTextElement($sSession, $sElement)
	writeLogFile($logFile, "$charInfoText: " & $charInfoText)

	; Lvl
	$aMatch = StringRegExp($charInfoText, "level (\d+)\s*\(", 1)

    If @error Then
        ConsoleWrite("Không tìm thấy level!" & @CRLF)
    Else
        ConsoleWrite("Lvl: " & $aMatch[0] & @CRLF)
		$charLvl = $aMatch[0]
    EndIf

	;~ $array = StringSplit($charInfoText, $charName &' level ', 1)
	;~ _ArrayDisplay($array)
	;~ $charLvl = Number(StringLeft ($array[2], 3))
	
	; Rs trong ngay
	;~ $array = StringSplit($charInfoText, 'Hôm nay reset ', 1)
	;~ $array = StringSplit($array[2], ' lượt.', 1)
	;~ $rsInDay = $array[1]
	$aMatch = StringRegExp($charInfoText, "reset (\d+)\s*lượt", 1)
	If @error Then
		ConsoleWrite("Không tìm lượt rs!" & @CRLF)
	Else
		ConsoleWrite("Số cần lấy là: " & $aMatch[0] & @CRLF)
		$rsInDay = $aMatch[0]
	EndIf

	; Xem Nhat ky reset
	_Demo_NavigateCheckBanner($sSession,combineUrl("web/char/char_info.logreset.shtml"))
	; Get element
	$sElement = findElement($sSession, "//table[@class='table table-striped table-sm table-hover w-100']/tbody/tr/td[6]")
	$timeRsText = getTextElement($sSession, $sElement)
	writeLogFile($logFile, "$timeRsText: " & $timeRsText)

	$sElement = findElement($sSession, "//table[@class='table table-striped table-sm table-hover w-100']/tbody/tr/td[3]")
	$sRsCount = getTextElement($sSession, $sElement)

	writeLogFile($logFile, "Info $charLvl: " & $charLvl&" - $rsInDay: " & $rsInDay &" - $sRsCount: " & $sRsCount)

	Return Number($rsInDay) & "|" & $timeRsText & "|" & Number($sRsCount)
EndFunc

Func getRsInDay($sLogReset) 
	Return Number(StringSplit($sLogReset, "|")[1])
EndFunc

Func getRsCount($sLogReset) 
	Return Number(StringSplit($sLogReset, "|")[3])
EndFunc

Func getTimeReset($sLogReset, $hourPerRs) 
	; $sLogReset loi = "3|07/07/2021 00:00:00|99"
	; $sLogReset dung = "5|14h39 08/11|631 - 0"
	writeLogFile($logFile, "getTimeReset($sLogReset, $hourPerRs): " & $sLogReset & " - " & $hourPerRs)
	$timeRsText = StringSplit($sLogReset, "|")[2]
	; 14h39 08/11
	$month = StringRight($timeRsText,2)
	$day = StringMid($timeRsText,7,2)
	$hour = StringLeft($timeRsText,2)
	$min = StringMid($timeRsText,4,2)

	writeLogFile($logFile, "month: " & $month & " - day: " & $day & " - hour: " & $hour & " - min: " & $min)
	$nextTimeRs = _DateAdd('h', $hourPerRs, @YEAR &"/"& $month &"/"& $day &" "& $hour &":"& $min &":00")
	writeLogFile($logFile, "nextTimeRs: " & $nextTimeRs)
	Return $nextTimeRs
EndFunc

Func getUrlAuction($sId)
	Return $baseMuUrl&"web/event/boss-item-bid.item.shtml?id="&$sId
EndFunc

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
	
		; Kiem so luong lenh 794 nam trong ma html sau:
		;~ <div class="alert alert-info" role="alert" id="t-player-text-info">
		;~ 					<h3 class="text-center">GiamDocSo</h3>
		;~ 					- Cấp độ: <span class="t-level">400</span>.lv, <span class="t-master_level">464</span>.mt<br>
		;~ 					- Còn lại: <b>794 lệnh. <a href="/web/char/control.buy_cmd.shtml">Mua thêm</a></b>
		;~ 					<br>
		;~ 				</div>
		$sElement = findElement($sSession, "//div[@id='t-player-text-info']")
		$cmdText = getTextElement($sSession, $sElement)
		$cmdText = StringSplit($cmdText, "Còn lại: <b>")[2]
		$cmdText = StringSplit($cmdText, " lệnh.")[1]
		writeLogFile($logFile, "cmdText: " & $cmdText)
		$cmdAmount = Number($cmdText)
		If $cmdAmount < 5 Then
			writeLogFile($logFile, "Khong du lenh de thuc hien chuyen dong. So lenh con lai: " & $cmdAmount)
			Return False
		EndIf
	
		; Thuc hien di toi toa do X
		$sElement = _WD_GetElementByName($sSession,"tx")
		_WD_ElementAction($sSession, $sElement, 'CLEAR')
		secondWait(1)
		_WD_ElementAction($sSession, $sElement, 'value',$x)
	
		; Thuc hien di toi toa do Y
		$sElement = _WD_GetElementByName($sSession,"ty")
		_WD_ElementAction($sSession, $sElement, 'CLEAR')
		secondWait(1)
		_WD_ElementAction($sSession, $sElement, 'value',$y)
	
		; Bam button chay ( submit )
		$sElement = findElement($sSession, "//input[@type='submit']")
		clickElement($sSession, $sElement)
	
		; close diaglog
		closeDiaglogConfim($sSession)
		
		Return True
	EndIf
EndFunc

Func logoutAndCloseChromeDriver($sSession)
	logout($sSession)
	secondWait(5)
	; Close webdriver neu thuc hien xong 
	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
EndFunc
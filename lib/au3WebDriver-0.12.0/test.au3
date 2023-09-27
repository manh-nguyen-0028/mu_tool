#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "wd_helper.au3"
#include "wd_capabilities.au3"

Global Const $_EXAMPLE_PROFILE_CHROME = @LocalAppDataDir & '\Google\Chrome\User Data\Default' ; CHANGE TO PROPER DIRECTORY PATH

;~ _Example()

;~ demo()

testGetElement()

Func demo()
	Local $sSession = SetupChrome()

	_WD_Window($sSession,"MINIMIZE")

	_Demo_NavigateCheckBanner($sSession,"http://hn.gamethuvn.net/",'//body/div[1][@aria-hidden="true"]')
    _WD_LoadWait($sSession, 1000)

	$sElement = findElement($sSession, "//input[@name='username']") 
	_WD_ElementAction($sSession, $sElement, 'value','bevis')

	$sElement = findElement($sSession, "//input[@name='password']") 
	_WD_ElementAction($sSession, $sElement, 'value','manh112233')

	; Find image captcha
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//img[@class='captcha_img']")

	_WD_DownloadImgFromElement($sSession, $sElement, @ScriptDir & "\testimage.png")

	If @error = $_WD_ERROR_Success Then 
		$sFilePath = "file:///" & @ScriptDir & "/../get_captcha.html"
		$urlGetCaptcha = StringReplace($sFilePath, "\", "/")
	
		_WD_NewTab($sSession)
		_Demo_NavigateCheckBanner($sSession, $urlGetCaptcha, '//body/div[1][@aria-hidden="true"]')

		; select single file
		_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='file']", @ScriptDir & "\testimage.png")

		; Submit get id from azcaptcha
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@type='submit']")
		_WD_ElementAction($sSession, $sElement, 'click')
		_WD_LoadWait($sSession, 1000)

		; get text
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//body")
		$idCaptcha = _WD_ElementAction($sSession, $sElement, 'text')
		$idCaptcha = StringReplace($idCaptcha, "OK|", "")
		_WD_LoadWait($sSession, 1000)

		; call server captcha 
		$serverCaptcha = "http://azcaptcha.com/res.php?key=ai0xvvkw3hcoyzbgwdu5tmqdaqyjlkjs&action=get&id=" & $idCaptcha
		_Demo_NavigateCheckBanner($sSession, $serverCaptcha, '//body/div[1][@aria-hidden="true"]')
		_WD_LoadWait($sSession, 1000)

		; get text
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//body")
		$idCaptcha = _WD_ElementAction($sSession, $sElement, 'text')
		$idCaptcha = StringReplace($idCaptcha, "OK|", "")
		ConsoleWrite("Captcha value: " & $idCaptcha)
		_WD_LoadWait($sSession, 1000)

		; Chuyen lai tab ve gamethuvn.net
		_WD_Attach($sSession, "gamethuvn.net", "URL")
		ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)

		; set input captcha
		$sElement = findElement($sSession, "//input[@name='captcha']") 
		_WD_ElementAction($sSession, $sElement, 'value',$idCaptcha)

		$sElement = findElement($sSession, "//button[@type='submit']") 
		_WD_ElementAction($sSession, $sElement, 'click')
		_WD_LoadWait($sSession, 1000)

		; Chuyen den site nay de thuc hien check thong tin
		_Demo_NavigateCheckBanner($sSession,"https://hn.gamethuvn.net/web/char/char_info.shtml")
    	_WD_LoadWait($sSession, 1000)

		; Click vao button nhan vat can check 
		;~ findElement($sSession, "//select[@id='OptionToChoose']/option[contains(text(), '" & $sText & "')]")
		$sElement = findElement($sSession, "//button[contains(text(),'Bevis')]")
		_WD_ElementAction($sSession, $sElement, 'click')
		_WD_LoadWait($sSession, 1000)

		; Thong tin lvl, so lan trong ngay/ thang
		$sElement = findElement($sSession, "//div[@role='alert']")

		$text = _WD_ElementAction($sSession, $sElement, 'text')
		;~ ConsoleWrite($text)

		$array = StringSplit($text, 'Bevis level ', 1)
		$charLvl = StringLeft ($array[2], 3)

		; Xem Nhat ky reset
		_Demo_NavigateCheckBanner($sSession,"https://hn.gamethuvn.net/web/char/char_info.logreset.shtml")
    	_WD_LoadWait($sSession, 1000)
		; Truy cap /web/char/char_info.logreset.shtml
		; Get element
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//table[@class='table table-striped table-sm table-hover w-100']/tbody/tr/td[6]")
		$value = _WD_ElementAction($sSession, $sElement, 'text')
		$month = StringLeft($value,2)
		$day = StringMid($value,4,2)
		$hour = StringMid($value,7,2)
		$min = StringMid($value,10,2)
		ConsoleWrite("Xem Nhat ky reset: " & $month & "@" & $day & "@" & $hour & "@" & $min & "@" & $value)
		;~ _ArrayDisplay($value)

		$diffTimeRs = 9
		
		If Number($charLvl) >= 300 And $diffTimeRs >= 8 Then
			ConsoleWrite("\n Du lvl thuc hien rs. $charLvl: " & Number($charLvl))
			;~ https://hn1.gamethuvn.net/web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char="&getCharName($accountInfo)
			_Demo_NavigateCheckBanner($sSession,"https://hn.gamethuvn.net/web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char=Bevis")
			_WD_LoadWait($sSession, 1000)
			Sleep(20000)
		Else
			ConsoleWrite("\n Khong du lvl hoac lay sai ky tu thuc hien rs. $charLvl: " & Number($charLvl))
		EndIf

		Sleep(20000)
		;~ $sElement = findElement($sSession, "//div[@class='alert-info']")
		;~ $infoValue = _WD_ElementAction($sSession, $sElement, 'text')
		;~ ConsoleWrite("Captcha value: " & $infoValue)
		; Chuyen de site nay de thuc hien rs
		;~ _Demo_NavigateCheckBanner($sSession,"https://hn.gamethuvn.net/web/char/reset.shtml?char=Bevis",'//body/div[1][@aria-hidden="true"]')
    	;~ _WD_LoadWait($sSession, 1000)
	EndIf
	
	Sleep(10000)
	
	If $sSession Then _WD_DeleteSession($sSession)
	_WD_Shutdown()
EndFunc

Func testGetElement()
	Local $sSession = SetupChrome()

	_WD_Window($sSession,"MINIMIZE")

	Local $sFilePath = _WriteTestHtml()
	_WD_Navigate($sSession, $sFilePath)
	_WD_LoadWait($sSession, 1000)

	$sElement = findElement($sSession, "//h4[contains(text(),'bevis')]")

	ConsoleWrite("sElement: " & $sElement)

EndFunc
	
Func _Example()

    ; If you want to download/update dirver the next line should be uncommented
;~  _WD_UpdateDriver('chrome')

    Local $sSession = SetupChrome()

	_WD_Window($sSession,"MINIMIZE")

    Local $sFilePath = _WriteTestHtml()
    _WD_Navigate($sSession, $sFilePath)
    _WD_LoadWait($sSession, 1000)

	$sElement = findElement($sSession, "//button[contains(text(),'Bevis')]")
	; Click
	_WD_ElementAction($sSession, $sElement, 'click')

	; Xem Nhat ky reset
	; Truy cap /web/char/char_info.logreset.shtml
	; Get element
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//table[@class='table table-striped table-sm table-hover w-100']/tbody/tr/td[6]")
	$value = _WD_ElementAction($sSession, $sElement, 'text')
	$month = StringLeft($value,2)
	$day = StringMid($value,4,2)
	$hour = StringMid($value,7,2)
	$min = StringMid($value,10,2)
	ConsoleWrite("Xem Nhat ky reset: " & $month & "@" & $day & "@" & $hour & "@" & $min & "@" & $value)
	;~ _ArrayDisplay($value)

	$diffTimeRs = 9
	; Thong tin lvl, so lan trong ngay/ thang
	$sElement = findElement($sSession, "//div[@role='alert']")

	$text = _WD_ElementAction($sSession, $sElement, 'text')
	;~ ConsoleWrite($text)

	$array = StringSplit($text, 'Bevis level ', 1)
	$charLvl = StringLeft ($array[2], 3)

	If Number($charLvl) >= 300 And $diffTimeRs >= 8 Then
		ConsoleWrite("\n Du lvl thuc hien rs. $charLvl: " & Number($charLvl))
		;~ https://hn1.gamethuvn.net/web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char="&getCharName($accountInfo)
		_Demo_NavigateCheckBanner($sSession,"https://hn1.gamethuvn.net/web/bank/reset_in_out.withdraw_confirm.shtml?val=1&char=Bevis")
    	_WD_LoadWait($sSession, 1000)
		Sleep(20000)
	Else
		ConsoleWrite("\n Khong du lvl hoac lay sai ky tu thuc hien rs. $charLvl: " & Number($charLvl))
	EndIf

	For $i = 0 To UBound($array) - 1
		;~ MsgBox(64, $i, $array[$i], 1)
	Next
	;~ _ArrayDisplay($array) ; example
	;~ Local $sSource = _WD_ElementAction($sSession, $sElement, "Attribute", "src")
	;~ $sElement = findElement($sSession, "//button[contains(text(),'Bevis')]")
	;~ _ArrayDisplay($sElement)
	;~ Sleep(20000)
    ;~ Local $sSelectElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//select[@id='OptionToChoose']")
	;~ Local $sElementSelector = "//input[@name='q']"

	;~ ;~ ; Locate a single element
	;~ $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='q']")
	;~ Sleep(500)

	;~ ;~ ;~ ; Set element's contents
	;~ If $sElement <> '' Then 
	;~ 	ConsoleWrite("$sElement: " & $sElement)
	;~ 	_WD_ElementAction($sSession, $sElement, 'VALUE', 'testing 123')
	;~ 	Sleep(500)
	;~ EndIf
	 
	;~ $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@id='gbqfbb']")
	;~ Sleep(500)
	;~ $xValue = _WD_ElementAction($sSession, $sElement, 'value','')
	;~ ConsoleWrite("$xValue: " & $xValue)

	;~ $buttonSearch = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='btnK']")
	;~ Sleep(500)
	;~ _WD_ElementAction($sSession, $buttonSearch, 'click')
	;~ Sleep(1000)
	;~ MouseClick("right",1274, 233)
	;~ Sleep(5000)
	;~ $sButton = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='btnK']")
	;~ Sleep(500)
	;~ _WD_ElementAction($sSession, $sButton, 'click')
    ;~ _ArrayDisplay($aOptionsList, '$aOptionsList, CurrentValue = ' & $sCurrentValue, '', 0, Default, '                          Value                          |                          Label                          ')

    ;~ Local $sValue = "1"
    ;~ _WD_ElementOptionSelect($sSession, $_WD_LOCATOR_ByXPath, "//select[@id='OptionToChoose']/option[@value='" & $sValue & "']")
    ;~ $sCurrentValue = _WD_ElementSelectAction($sSession, $sSelectElement, "value")
    ;~ MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, 'Using XPath #' & @ScriptLineNumber, _
    ;~         'After selecting Value "' & $sValue & '"' & @CRLF & _
    ;~         'CurrentValue = ' & $sCurrentValue)

    ;~ $sValue = "2"
    ;~ _WD_ElementOptionSelect($sSession, $_WD_LOCATOR_ByCSSSelector, "#OptionToChoose option[value='" & $sValue & "']")
    ;~ $sCurrentValue = _WD_ElementSelectAction($sSession, $sSelectElement, "value")
    ;~ MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, 'Using CSSSelector #' & @ScriptLineNumber, _
    ;~         'After selecting Value "' & $sValue & '"' & @CRLF & _
    ;~         'CurrentValue = ' & $sCurrentValue)

    ;~ Local $sText = "Moon"
    ;~ _WD_ElementOptionSelect($sSession, $_WD_LOCATOR_ByXPath, "//select[@id='OptionToChoose']/option[contains(text(), '" & $sText & "')]")
    ;~ $sCurrentValue = _WD_ElementSelectAction($sSession, $sSelectElement, "value")
    ;~ MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, 'Using XPath #' & @ScriptLineNumber, _
    ;~         'After selecting Label "' & $sText & '"' & @CRLF & _
    ;~         'CurrentValue = ' & $sCurrentValue)

    ;~ ; Selecting Text with CSSSelector is not possible.
    ;~ ; https://www.w3.org/TR/selectors-3/#content-selectors
    ;~ ; https://stackoverflow.com/questions/1520429/is-there-a-css-selector-for-elements-containing-certain-text
    ;~ ; https://sqa.stackexchange.com/questions/362/a-way-to-match-on-text-using-css-locators

    ;~ Local $iIndex = 2 ; be aware that Index is 1-based
    ;~ _WD_ElementOptionSelect($sSession, $_WD_LOCATOR_ByXPath, "//select[@id='OptionToChoose']/option[" & $iIndex & "]")
    ;~ $sCurrentValue = _WD_ElementSelectAction($sSession, $sSelectElement, "value")
    ;~ MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, 'Using XPath #' & @ScriptLineNumber, _
    ;~         'After selecting Index = ' & $iIndex & @CRLF & _
    ;~         'CurrentValue = ' & $sCurrentValue)

    ;~ $iIndex = 3 ; be aware that Index is 1-based
    ;~ _WD_ElementOptionSelect($sSession, $_WD_LOCATOR_ByCSSSelector, "select#OptionToChoose option:nth-child(" & $iIndex & ")")
    ;~ $sCurrentValue = _WD_ElementSelectAction($sSession, $sSelectElement, "value")
    ;~ MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, 'Using CSSSelector #' & @ScriptLineNumber, _
    ;~         'After selecting Index = ' & $iIndex & @CRLF & _
    ;~         'CurrentValue = ' & $sCurrentValue)

    If $sSession Then _WD_DeleteSession($sSession)
	_WD_Shutdown()
EndFunc   ;==>_Example

Func _WriteTestHtml($sFilePath = @ScriptDir & "\wd_demo_SelectElement_TestFile.html")
    FileDelete($sFilePath)
    Local Const $sHtml = _
            "<html lang='en'>" & @CRLF & _
            "    <head>" & @CRLF & _
            "        <meta charset='utf-8'>" & @CRLF & _
            "        <title>TESTING</title>" & @CRLF & _
            "    </head>" & @CRLF & _
            "    <body>" & @CRLF & _
            "       <select id='OptionToChoose'>" & @CRLF & _
            "          <option value='' selected='selected'>Choose option</option>" & @CRLF & _
            "          <option value='1'>Sun</option>" & @CRLF & _
            "          <option value='2'>Earth</option>" & @CRLF & _
            "          <option value='3'>Moon</option>" & @CRLF & _
            "       </select>" & @CRLF & _
			" <button class='btn btn-secondary btn-sm btn-block t-char_info_btn'>Bevis</button>" & @CRLF & _
			" <button class='btn btn-secondary btn-sm btn-block t-char_info_btn'>X111</button>" & @CRLF & _
			" <div class='alert alert-info' role='alert'>" & @CRLF & _                    
			" Reset <b>852</b> lần, point dư: <b>25,750</b>, ám sát: <b>0</b> (damage <b>0</b>)<br>" & @CRLF & _
			" Level Master: <b>400</b>, skill_3: <b>0</b>, skill_4: <b>0</b>, level thuộc tính: <b>9</b>, điểm quả: <b>0</b>, Phúc Duyên <b>6,377</b><br>" & @CRLF & _
			" <b>Bevis</b> level <b>384</b> (Hôm nay reset 0 lượt. Tháng này reset 28 lượt)" & @CRLF & _
			" 					<br>" & @CRLF & _
			" <button class='btn btn-secondary btn-sm btn-block t-char_info_btn'>X222</button>" & @CRLF & _
			" <div height='100%' alt='CoreUI Logo'>" & @CRLF & _
			" <div class='t-account-title'>" & @CRLF & _
            " <h4>bevis</h4>" & @CRLF & _
            " <h7>(Hà Nội 2003)</h7>" & @CRLF & _
            " </div>" & @CRLF & _
			" </div>" & @CRLF & _
            "    </body>" & @CRLF & _
            "</html>"
    FileWrite($sFilePath, $sHtml)
    Return "file:///" & StringReplace($sFilePath, "\", "/")
EndFunc   ;==>_WriteTestHtml

Func SetupChrome()
    _WD_Option('Driver', 'D:\software\AutoIt3\chromedriver_win32\chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')

 	_WD_CapabilitiesStartup()
    _WD_CapabilitiesAdd('alwaysMatch', 'chrome')
    _WD_CapabilitiesAdd('w3c', True)
    _WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	_WD_CapabilitiesAdd('args', 'start-maximized')
	_WD_CapabilitiesAdd('args', 'disable-infobars')
	;~ _WD_CapabilitiesAdd('args', 'user-data-dir', "C:\\Users\\manh.nguyentien\\AppData\\Local\\Google\\Chrome\\User Data\\")
	;~ _WD_CapabilitiesAdd('args', '--profile-directory', 'Default')
	;~ _WD_CapabilitiesAdd('binary', "C:\Program Files\Google\Chrome\Application\chrome.exe")

	_WD_Startup()
    Local $sCapabilities = _WD_CapabilitiesGet()

    Local $sSession = _WD_CreateSession($sCapabilities)

    Return $sSession
EndFunc   ;==>SetupChrome


Func _Demo_NavigateCheckBanner($sSession, $sURL, $sXpath = '//body/div[1][@aria-hidden="true"]')
	_WD_Navigate($sSession, $sURL)
	_WD_LoadWait($sSession)

	; Check if designated element is visible, as it can hide all sub elements in case when COOKIE aproval message is visible
	_WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath, 0, 1000 * 60, $_WD_OPTION_NoMatch)
	If @error Then
		ConsoleWrite('wd_demo.au3: (' & @ScriptLineNumber & ') : "' & $sURL & '" page view is hidden - it is possible that the message about COOKIE files was not accepted')
		Return SetError(@error, @extended)
	EndIf

	_WD_LoadWait($sSession)
EndFunc   ;==>_Demo_NavigateCheckBanner

Func findElement($sSession, $sXpath)
	; Check if designated element is visible, as it can hide all sub elements in case when COOKIE aproval message is visible
	_WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath, 0, 1000 * 5, $_WD_OPTION_Visible)
	
	If @error Then
		ConsoleWrite('test.au3: (' & @ScriptLineNumber & ') :  element not found !')
		Return SetError(@error, @extended)
	Else
		$resultValue = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath)
		ConsoleWrite("findElement: " & $resultValue)
		Return $resultValue
	EndIf

	_WD_LoadWait($sSession)

EndFunc   ;==>_Demo_NavigateCheckBanner
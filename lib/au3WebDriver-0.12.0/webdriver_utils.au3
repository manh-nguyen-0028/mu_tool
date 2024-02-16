#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "wd_helper.au3"
#include "wd_capabilities.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"

Global $baseUrl = "https://hn.gamethuvn.net/"

Func SetupChrome()
    _WD_Option('Driver', $driverPathRoot & 'chromedriver\chromedriver-win64\chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')

 	_WD_CapabilitiesStartup()
    _WD_CapabilitiesAdd('alwaysMatch', 'chrome')
    _WD_CapabilitiesAdd('w3c', True)
    _WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	_WD_CapabilitiesAdd('args', 'start-maximized')
	_WD_CapabilitiesAdd('args', 'disable-infobars')
	_WD_CapabilitiesAdd('args', 'user-data-dir', $sChromeUserDataPath)
	_WD_CapabilitiesAdd('args', '--profile-directory', 'Default')
	_WD_CapabilitiesAdd('binary', "C:\Program Files\Google\Chrome\Application\chrome.exe")

	_WD_Startup()
    Local $sCapabilities = _WD_CapabilitiesGet()

    Local $sSession = _WD_CreateSession($sCapabilities)

    Return $sSession
EndFunc   ;==>SetupChrome


Func _Demo_NavigateCheckBanner($sSession, $sURL, $sXpath = '//body/div[1][@aria-hidden="true"]')
	_WD_Navigate($sSession, $sURL)
	_WD_LoadWait($sSession)

	; Check if designated element is visible, as it can hide all sub elements in case when COOKIE aproval message is visible
	_WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath, 0, 1000 * 20, $_WD_OPTION_NoMatch)
	If @error Then
		ConsoleWrite('wd_demo.au3: (' & @ScriptLineNumber & ') : "' & $sURL & '" page view is hidden - it is possible that the message about COOKIE files was not accepted')
		writeLog("ERROR: " & @error)
		Return $_WD_ERROR_Timeout
	Else
		_WD_LoadWait($sSession,1000)
	EndIf
EndFunc   ;==>_Demo_NavigateCheckBanner

Func findElement($sSession, $sXpath)
	; Check if designated element is visible, as it can hide all sub elements in case when COOKIE aproval message is visible
	_WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath, 0, 1000 * 20, $_WD_OPTION_Visible)
	
	If @error Then
		ConsoleWrite('test.au3: (' & @ScriptLineNumber & ') :  element not found !')
		Return SetError(@error, @extended)
	Else
		$resultValue = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath)
		ConsoleWrite("findElement: " & $resultValue)
		Return $resultValue
	EndIf

	_WD_LoadWait($sSession,1000)
EndFunc   ;==>_Demo_NavigateCheckBanner

Func optimizeUrl($urlPath) 
	writeLog('test.au3: (' & @ScriptLineNumber & ')  => Param: ' & $urlPath)
	Return StringReplace($urlPath, "\", "/")
EndFunc

Func createNewTab($sSession,$url)
	_WD_NewTab($sSession)
	_Demo_NavigateCheckBanner($sSession, $url)
EndFunc

Func clickElement($sSession, $sElement)
	_WD_ElementAction($sSession, $sElement, 'click')
	_WD_LoadWait($sSession, 1000)
EndFunc

Func getTextElement($sSession, $sElement)
	Return _WD_ElementAction($sSession, $sElement, 'text')
EndFunc

Func combineUrl($urlCombine)
	Return _WinAPI_UrlCombine($baseUrl, $urlCombine)
EndFunc
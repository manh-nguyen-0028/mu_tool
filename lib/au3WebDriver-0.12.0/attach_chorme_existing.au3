#include "wd_helper.au3"
#include "wd_capabilities.au3"

# HOW TO TEST:
; At first run choose [Yes] to create new session Chrome running instance
; At second run choose [No] to attach to active Chrome running instance

Global $_MY__WD_SESSION
Global $__g_sDownloadDir = ""
Local $chormeDriverDir = 'D:\Project\gtvn_auto_dv\chromedriver_win32_113\chromedriver.exe'
Local $chormeUserDataDir = 'C:\Users\manh.nguyen\AppData\Local\Google\Chrome\User Data\'
Local $chormeSetupDir = 'C:\Program Files\Google\Chrome\Application\chrome.exe'

_Test()

Exit

Func _Test()
    Local $iAnswer = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON2, "Question", _
            "Open new sesion ?" & @CRLF & "[ NO ] = Try attach to active Chrome instance")
    If $iAnswer = $IDYES Then
        _Testing_CreateSession()
        Return     ; do not process next functions
    Else
        _Testing_AttachSession()
        _WD_Navigate($_MY__WD_SESSION, 'https://www.google.com/')
    EndIf

    $iAnswer = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON2, "Question", _
            "Do you want to test ?" & @CRLF & "[ NO ] = Refresh - prevent expiration")
    If $iAnswer = $IDYES Then
        _Testing_WD_Navigate()
    Else
        _Testing_Refreshing()
    EndIf

    ; CleanUp
    _WD_DeleteSession($_MY__WD_SESSION)
    _WD_Shutdown()
EndFunc   ;==>_Test

Func _Testing_CreateSession()
    $_MY__WD_SESSION = _MY__WD_SetupChrome(False, $__g_sDownloadDir, False)
EndFunc   ;==>_Testing_CreateSession

Func _Testing_AttachSession()
    $_MY__WD_SESSION = _MY__WD_SetupChrome(False, $__g_sDownloadDir, True)
EndFunc   ;==>_Testing_AttachSession

Func _Testing_Refreshing()
    While 1
;~      _WD_Navigate($_MY__WD_SESSION, '')
        _WD_Action($_MY__WD_SESSION, 'REFRESH')
        Local $iAnswer = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON2, "Question", "Finish refreshing?" & @CRLF & "[No] = Refresh - prevent expiration", 60)
        If $iAnswer = $IDYES Then Return
    WEnd
EndFunc   ;==>_Testing_Refreshing

Func _Testing_WD_Navigate()
    _WD_Navigate($_MY__WD_SESSION, 'https://www.autoitscript.com/forum')
EndFunc   ;==>_Testing_WD_Navigate

Func _MY__WD_SetupChrome($b_Headless, $s_Download_dir = Default, $bTryAttach = False)
    If $s_Download_dir = Default Then
        $s_Download_dir = ''
    ElseIf $s_Download_dir Then
        If FileExists($s_Download_dir) = 0 Then $s_Download_dir = ''
    EndIf

    _WD_UpdateDriver('chrome')
    If @error Then Return SetError(@error, @extended, '')

    _WD_Option('Driver', $chormeDriverDir)
    _WD_Option('Port', 9515)
    _WD_CapabilitiesStartup()
;~  Local $s_AttachOption = (($bTryAttach) ? ("") : (" --remote-debugging-port=9222"))
;~  _WD_Option('DriverParams', '--log trace' & $s_AttachOption)
	_WD_CapabilitiesAdd('alwaysMatch', 'chrome')
    _WD_CapabilitiesAdd('w3c', True)
    _WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	_WD_CapabilitiesAdd('args', 'start-maximized')
	_WD_CapabilitiesAdd('args', 'disable-infobars')
	_WD_CapabilitiesAdd('args', 'user-data-dir', $chormeUserDataDir)
	_WD_CapabilitiesAdd('args', '--profile-directory', 'Default')

    _WD_CapabilitiesAdd('firstMatch', 'chrome')
    _WD_CapabilitiesAdd('w3c', True)
    _WD_CapabilitiesAdd('detach', False)
    _WD_CapabilitiesAdd('binary', $chormeSetupDir)

    If $bTryAttach Then
            _WD_CapabilitiesAdd('debuggerAddress', '127.0.0.1:9222')
    Else
            _WD_CapabilitiesAdd('args', '--remote-debugging-port=9222')
    EndIf
    If $b_Headless Then _
            _WD_CapabilitiesAdd('args', '--headless')
    If $s_Download_dir Then _
            _WD_CapabilitiesAdd('prefs', 'download.default_directory', $s_Download_dir)

    _WD_CapabilitiesDump(@ScriptLineNumber & ' :WebDriver:Capabilities:')

    Local $iWebDriverPID = _WD_Startup()
    If @error Then Return SetError(@error, @extended, '')



    Local $s_Capabilities = _WD_CapabilitiesGet()
    Local $WD_SESSION = _WD_CreateSession($s_Capabilities)
    If @error Then Return SetError(@error, @extended, $WD_SESSION)

    Local $iBrowserPID = _WD_GetBrowserPID($iWebDriverPID, 'chrome')
    ConsoleWrite("! $iBrowserPID=" & $iBrowserPID & @CRLF)

    Return SetError(@error, @extended, $WD_SESSION)
EndFunc   ;==>_MY__WD_SetupChrome


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetBrowserPID
; Description ...: Get the PID of the browser that was launched by WebDriver
; Syntax ........: _WD_GetBrowserPID($iWebDriverPID, $sBrowserName)
; Parameters ....: $iWebDriverPID       - WebDriver PID returned by _WD_Startup()
;                  $sBrowserName        - [optional] Browser name from the list of supported browsers ($_WD_SupportedBrowsers)
; Return values .: Success - Browser PID
;                  Failure - 0 and sets @error to one of the following values:
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_NotSupported
;                  - $_WD_ERROR_NoMatch
; Author ........: mLipok
; Modified ......: Danp2
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetBrowserPID($iWebDriverPID, $sBrowserName = '')
    Local Const $sFuncName = "_WD_GetBrowserPID"
    Local $iErr = $_WD_ERROR_Success, $iExt = 0, $iIndex = 0, $sBrowserExe = '', $aProcessList, $iBrowserPID = 0, $sMessage = ''
    Local $sDriverProcessName = _WinAPI_GetProcessName($iWebDriverPID)

    If @error Or Not ProcessExists($iWebDriverPID) Then
        #REMARK ProcessExists($iWebDriverPID) is required because of ; https://www.autoitscript.com/trac/autoit/ticket/3894
        $sDriverProcessName = ''
        $iErr = $_WD_ERROR_GeneralError
        $iExt = 1
        $sMessage = 'Unable to retrieve WebDriver process name for given PID'
    ElseIf _ArraySearch($_WD_SupportedBrowsers, $sDriverProcessName, Default, Default, Default, Default, Default, $_WD_BROWSER_DriverName) = -1 Then
        $iErr = $_WD_ERROR_NotSupported
        $sMessage = 'WebDriverPID is related to not supported WebDriver exe name'
    Else
        If $sBrowserName Then
            $iIndex = _ArraySearch($_WD_SupportedBrowsers, $sBrowserName, Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
        EndIf
        If @error Then
            $iErr = $_WD_ERROR_GeneralError
            $iExt = 2
            $sMessage = 'BrowserName can not be found on supported browsers names list'
        Else
            $aProcessList = _WinAPI_EnumChildProcess($iWebDriverPID)
            If @error Then
                $iErr = $_WD_ERROR_GeneralError
                $iExt = 3
                $sMessage = 'Session was not created properly'
            Else
                _ArrayDisplay($aProcessList, '$aProcessList')
                ; all not supported EXE file names should be removed from $aProcessList, for example "conhost.exe" can be used by WebDriver exe file
                For $iCheck = $aProcessList[0][0] To 1 Step -1
                    _ArraySearch($_WD_SupportedBrowsers, $aProcessList[$iCheck][1], Default, Default, Default, Default, Default, $_WD_BROWSER_ExeName)
                    If @error Then
                        _ArrayDelete($aProcessList, $iCheck)
                        $aProcessList[0][0] -= 1
                    EndIf
                Next
                If $aProcessList[0][0] = 0 Then
                    $iErr = $_WD_ERROR_GeneralError
                    $iExt = 4
                    $sMessage = 'All child process (file names) are not listed on supported browsers exe'
                EndIf
            EndIf
        EndIf
    EndIf

    If $iErr = $_WD_ERROR_Success Then
        If $sBrowserName = '' Then
            $iBrowserPID = $aProcessList[1][0]
        Else
            $sBrowserExe = $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_ExeName]
            For $i = 1 To $aProcessList[0][0]
                If $aProcessList[$i][1] = $sBrowserExe Then
                    $iBrowserPID = $aProcessList[$i][0]
                    $sMessage = "Browser - " & $aProcessList[$i][1] & " - PID = " & $iBrowserPID
                    ExitLoop
                EndIf
            Next
            If Not $iBrowserPID Then
                $iErr = $_WD_ERROR_NoMatch
                $sMessage = 'BrowserExe related to requested BrowserName was not matched in the webdriver child process list'
            EndIf
        EndIf
    EndIf
    Return SetError(__WD_Error($sFuncName, $iErr, $sMessage, $iExt), $iExt, $iBrowserPID)
EndFunc   ;==>_WD_GetBrowserPID
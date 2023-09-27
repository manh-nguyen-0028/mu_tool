#include "wd_helper.au3"
#include "wd_capabilities.au3"
#include "../auto_mu_utils.au3"

# HOW TO TEST:
; At first run choose [Yes] to create new session FireFox running instance
; At second run choose [No] to attach to active FireFox running instance

# TODO:
; https://github.com/operasoftware/operachromiumdriver/blob/master/docs/desktop.md   --remote-debugging-port=port

Global $_MY__WD_SESSION
Global $__g_sDownloadDir = @ScriptDir & '\Testing_Download'

_Test()

Exit

Func _Test()
	$chormeDriverDir = @AppDataDir & '\chromedriver_win32\chromedriver.exe'
	$chormeUserDataDir = @AppDataDir & "\Local\Google\Chrome\User Data\"
	$chormeSetupDir = @ProgramFilesDir & "\Google\Chrome\Application\chrome.exe"
	writeLog("webdriver_utils.au3: (" & @ScriptLineNumber & ") : Valiable $chormeDriverDir = " & $chormeDriverDir & ", $chormeUserDataDir = " & $chormeUserDataDir& ", $chormeSetupDir = " & $chormeSetupDir)
    Local $s_FireFox_Binary = $chormeSetupDir
    If $s_FireFox_Binary And FileExists($s_FireFox_Binary) = 0 Then $s_FireFox_Binary = ''

    Local $iAnswer = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON2, "Question", _
            "Open new sesion ?" & @CRLF & "[ NO ] = Try attach to active FireFox instance")
    If $iAnswer = $IDYES Then
        _Testing_CreateSession($s_FireFox_Binary)
;~      _Testing_WD_Navigate()
        Return     ; do not process next functions
    Else
        _Testing_AttachSession($s_FireFox_Binary)
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

Func _Testing_CreateSession($s_FireFox_Binary)
    $_MY__WD_SESSION = SetupChrome_x(False, $__g_sDownloadDir, $s_FireFox_Binary, False)
EndFunc   ;==>_Testing_CreateSession

Func _Testing_AttachSession($s_FireFox_Binary)
    $_MY__WD_SESSION = SetupChrome_x(False, $__g_sDownloadDir, $s_FireFox_Binary, True)
EndFunc   ;==>_Testing_AttachSession

Func _Testing_Refreshing()
    While 1
;~      _WD_Navigate($_MY__WD_SESSION, '')
        _WD_Action($_MY__WD_SESSION, 'REFRESH')
        Local $iAnswer = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON2, "Question", "Finish refreshing?" & @CRLF & "[No] = Refresh - prevent expiration", 60)
        If $iAnswer = $IDYES Then Return
    WEnd
EndFunc   ;==>_Testing_Refreshing

Func SetupChrome_x($b_Headless, $s_Download_dir = Default, $s_FireFox_Binary = Default, $bTryAttach = False)
	$chormeDriverDir = @ScriptDir & '\..\chromedriver_win32\chromedriver.exe'
	$chormeUserDataDir = @LocalAppDataDir & "\Google\Chrome\User Data\"
	$chormeSetupDir = StringRegExpReplace(@ProgramFilesDir," \(x86\)","") & "\Google\Chrome\Application\chrome.exe"
	writeLog("attach_brower_existing.au3: (" & @ScriptLineNumber & ") : Valiable $chormeDriverDir = " & $chormeDriverDir & ", $chormeUserDataDir = " & $chormeUserDataDir& ", $chormeSetupDir = " & $chormeSetupDir)

	If $s_Download_dir = Default Then
        $s_Download_dir = ''
    ElseIf $s_Download_dir Then
        If FileExists($s_Download_dir) = 0 Then $s_Download_dir = ''
    EndIf

    Local $sCapabilities = Default
    ;~ Local $s_Profile_Dir  = @LocalAppDataDir & '\Mozilla\Firefox\Profiles\WD_Testing_Profile'
	Local $s_Profile_Dir  = $chormeUserDataDir
    DirCreate($s_Download_dir) ; MUST EXIST !!
    DirCreate($s_Profile_Dir) ; MUST EXIST !!


    _WD_Option('Driver', $chormeDriverDir)
	_WD_Option('Port', 9515)

	If $bTryAttach Then
        ;~ _WD_Option('DriverParams', '--log trace --marionette-port 2828 --connect-existing')
		_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log" --connect-existing')
    Else
        ;~ _WD_Option('DriverParams', '--log trace --marionette-port 2828')
		_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')
	
	;~ _WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')

 	_WD_CapabilitiesStartup()
    _WD_CapabilitiesAdd('alwaysMatch', 'chrome')
    _WD_CapabilitiesAdd('w3c', True)
    _WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	_WD_CapabilitiesAdd('args', 'start-maximized')
	_WD_CapabilitiesAdd('args', 'disable-infobars')
	_WD_CapabilitiesAdd('args', 'user-data-dir', $chormeUserDataDir)
	_WD_CapabilitiesAdd('args', '--profile-directory', 'Default')
	_WD_CapabilitiesAdd('binary', $chormeSetupDir)
	$sCapabilities = _WD_CapabilitiesGet()
	EndIf	
	_WD_Startup()
	If @error Then Return SetError(@error, @extended, '')

    Local $_MY__WD_SESSION = _WD_CreateSession($sCapabilities)

    Return $_MY__WD_SESSION
EndFunc   ;==>SetupChrome

Func _MY__WD_SetupFireFox($b_Headless, $s_Download_dir = Default, $s_FireFox_Binary = Default, $bTryAttach = False)
    If $s_Download_dir = Default Then
        $s_Download_dir = ''
    ElseIf $s_Download_dir Then
        If FileExists($s_Download_dir) = 0 Then $s_Download_dir = ''
    EndIf

    Local $s_Capabilities = Default
    Local $s_Profile_Dir  = @LocalAppDataDir & '\Mozilla\Firefox\Profiles\WD_Testing_Profile'
    DirCreate($s_Download_dir) ; MUST EXIST !!
    DirCreate($s_Profile_Dir) ; MUST EXIST !!

    _WD_UpdateDriver('firefox')
    If @error Then Return SetError(@error, @extended, '')

    #WARRNING DO NOT USE '--log-path=' BECAUSE OF   RODO / GDPR
    _WD_Option('Driver', 'geckodriver.exe')
    _WD_Option('Port', 4444)
    _WD_Option('DefaultTimeout', 1000)

    If $bTryAttach Then
        _WD_Option('DriverParams', '--log trace --marionette-port 2828 --connect-existing')
    Else
        _WD_Option('DriverParams', '--log trace --marionette-port 2828')

        _WD_CapabilitiesStartup()
        _WD_CapabilitiesAdd('alwaysMatch')
        _WD_CapabilitiesAdd('acceptInsecureCerts', True)
        _WD_CapabilitiesAdd('firstMatch', 'firefox')
        _WD_CapabilitiesAdd('args', '-profile')

        _WD_CapabilitiesAdd('args', $s_Profile_Dir) ; CHANGE TO PROPER DIRECTORY PATH
        If $s_FireFox_Binary Then _WD_CapabilitiesAdd('binary', $s_FireFox_Binary)

        If $b_Headless Then _
                _WD_CapabilitiesAdd('args', '--headless')

        _WD_CapabilitiesDump(@ScriptLineNumber & ' :WebDriver:Capabilities:')
        $s_Capabilities = _WD_CapabilitiesGet()
    EndIf

    _WD_Startup()
    If @error Then Return SetError(@error, @extended, '')

    Local $WD_SESSION = _WD_CreateSession($s_Capabilities)
    Return SetError(@error, @extended, $WD_SESSION)
EndFunc   ;==>_MY__WD_SetupFireFox

Func _Testing_WD_Navigate()
    _WD_Navigate($_MY__WD_SESSION, 'https://www.autoitscript.com/forum')
EndFunc   ;==>_Testing_WD_Navigate
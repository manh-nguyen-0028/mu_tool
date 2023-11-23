#include-once
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"

Local $sSession,$sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
Local $jsonZaloConfigTime
Local $sDesiredCapabilities

startPostZalo()


Func getJsonConfigTime()
    $jsonConfigTimePath = $jsonPathRoot & "config_time.json"

    $jsonConfigTime = getJsonFromFile($jsonConfigTimePath)

    $jsonZaloConfigTime = getPropertyJson($jsonConfigTime, "zalo")

    Return True
EndFunc

Func isCanPost()
    $isCanPost = False

    If @HOUR > 6 And @HOUR <= 23 Then
        $lastTimePost = getPropertyJson($jsonZaloConfigTime, "last_time_post")
        $timeNow = getTimeNow()
        $nextTimeCanPost = addTimeSubtractionMinute($lastTimePost, 1)
        If $timeNow >= $nextTimeCanPost Then $isCanPost = True
    EndIf

    Return $isCanPost
EndFunc

Func startPostZalo()
    getJsonConfigTime()

    If isCanPost() == True Then
        $sSession = SetupGecko()
        
        _WD_Navigate($sSession, "https://chat.zalo.me/")
        secondWait(5)
        $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@id='contact-search-input']")
        If @error = $_WD_ERROR_Success Then
            clickElement($sSession, $sElement)
            sendKeyDelay("Cloud")
        EndIf
        
    EndIf

    writeLog("OK")

    _WD_Shutdown()

    Return True
EndFunc

Func SetupGecko()
_WD_Option('Driver', 'D:\Project\AutoIT\mu_tool\driver\firefox\geckodriver-v0.33.0\geckodriver.exe')
_WD_Option('DriverParams', '--log trace')
_WD_Option('Port', 4444)

$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}'

_WD_Startup()

$sSession = _WD_CreateSession($sDesiredCapabilities)

Return $sSession
EndFunc
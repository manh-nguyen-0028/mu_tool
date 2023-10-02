#include-once
#include "../../utils/common_utils.au3"
#RequireAdmin

;~ startPath()

While True
    waitToNextHourMinutes(1, 35, 00)
    If @HOUR < 20 And @HOUR > 22 Then startPath()
WEnd

Func startPath()
    $exePath = $featurePathRoot &"auto_reset\auto_rs.exe"

    writeLog($exePath)
    Run($exePath)

    Return True
EndFunc
#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../auto_reset/auto_rs_v2.au3"
#include "../auto_buff/auto_buff.au3"
#RequireAdmin

start()

; Method: start
; Description: Main loop for service control V2. Runs auto reset V2 and auto buff.
Func start()
	While True
		If Not checkProcessExists("mu_auction.exe") And ((@HOUR < 23) Or (@HOUR == 23 And @MIN <= 20)) Then
			startAutoRsV2()
			startAutoBuff()
		EndIf

		Local $timeLoop = _JSONGet($jsonPositionConfig, "common.auto.time_loop_auto_rs")
		writeLog("Time loop for auto reset v2: " & $timeLoop)
		If (Number($timeLoop) = 0 Or Number($timeLoop) == 60) Then
			waitToNextHourMinutes(1, 07, 00)
		Else
			minuteWait($timeLoop)
		EndIf
	WEnd
EndFunc   ;==>start

; Method: startPath
; Description: Executes auto reset V2 executable path.
Func startPath()
	Local $exePath = $featurePathRoot & "auto_reset\auto_rs_v2.exe"
	writeLog($exePath)
	Run($exePath)
	ProcessWaitClose("auto_rs_v2.exe")
	Return True
EndFunc   ;==>startPath
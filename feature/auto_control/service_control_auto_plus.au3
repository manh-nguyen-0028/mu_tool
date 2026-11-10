#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "../auto_buff/auto_buff.au3"
#include "../auto_reset/auto_reset_toggle.au3"
#include "../auto_devil/auto_devil_toggle.au3"
#RequireAdmin

serviceControlStart()

; Method: serviceControlStart
; Description: Vong lap theo ngay dieu khien Auto Plus: buff -> 00h30 reset on -> 06h30 reset off -> 18h08 devil off -> 23h40 devil on
Func serviceControlStart()
	While True
		Local $startDay = @MDAY
		writeLog("Bat dau ngay moi: " & @YEAR & "/" & @MON & "/" & @MDAY)

		startAutoBuff()
		runScheduledStep(0, 30, "startAutoResetOn")
		runScheduledStep(6, 30, "startAutoResetOff")
		runScheduledStep(18, 8, "startAutoDevilOff")
		runScheduledStep(23, 40, "startAutoDevilOn")

		; Cho sang ngay moi roi moi lap lai chu trinh
		While @MDAY == $startDay
			Sleep(10000)
		WEnd
	WEnd
EndFunc   ;==>serviceControlStart

; Method: runScheduledStep
; Description: Cho toi gio:phut hom nay roi chay ham $funcName. Bo qua neu moc gio da qua.
Func runScheduledStep($hour, $min, $funcName)
	Local $diff = createTimeToTicks($hour, $min, 0) - createTimeToTicks(@HOUR, @MIN, @SEC)
	If $diff < 0 Then
		writeLog("Da qua " & $hour & "h" & $min & " => bo qua " & $funcName)
		Return False
	EndIf
	writeLog("Cho toi " & $hour & "h" & $min & " de chay " & $funcName & " (" & timeToText($diff) & ")")
	Sleep($diff)
	Call($funcName)
	Return True
EndFunc   ;==>runScheduledStep

; Method: startPath
; Description: Executes auto reset V2 executable path.
Func startPath()
	Local $exePath = $featurePathRoot & "auto_reset\auto_rs_v2.exe"
	writeLog($exePath)
	Run($exePath)
	ProcessWaitClose("auto_rs_v2.exe")
	Return True
EndFunc   ;==>startPath
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
		showStepLog("Bat dau ngay moi: " & @YEAR & "/" & @MON & "/" & @MDAY)

		showStepLog("Dang chay startAutoBuff")
		startAutoBuff()
		showStepLog("Xong startAutoBuff")
		runScheduledStepByConfig("reset_on", "00:30", "startAutoResetOn")
		runScheduledStepByConfig("reset_off", "06:30", "startAutoResetOff")
		runScheduledStepByConfig("devil_off", "18:08", "startAutoDevilOff")
		runScheduledStepByConfig("devil_on", "23:40", "startAutoDevilOn")

		showStepLog("Xong cac buoc trong ngay, cho sang ngay moi")
		While @MDAY == $startDay
			Sleep(10000)
		WEnd
	WEnd
EndFunc   ;==>serviceControlStart

; Method: runScheduledStepByConfig
; Description: Doc moc gio "HH:MM" tu common.auto_plus_schedule.<$key> trong position_config (khong co thi dung $default) roi goi runScheduledStep
Func runScheduledStepByConfig($key, $default, $funcName)
	Local $time = _JSONGet($jsonPositionConfig, "common.auto_plus_schedule." & $key)
	If $time == "" Then $time = $default
	Local $parts = StringSplit($time, ":")
	If $parts[0] <> 2 Then
		showStepLog("Sai dinh dang gio '" & $time & "' cho " & $key & " => dung mac dinh " & $default)
		$parts = StringSplit($default, ":")
	EndIf
	Return runScheduledStep(Number($parts[1]), Number($parts[2]), $funcName)
EndFunc   ;==>runScheduledStepByConfig

; Method: runScheduledStep
; Description: Cho toi gio:phut hom nay roi chay ham $funcName. Bo qua neu moc gio da qua.
Func runScheduledStep($hour, $min, $funcName)
	Local $diff = createTimeToTicks($hour, $min, 0) - createTimeToTicks(@HOUR, @MIN, @SEC)
	If $diff < 0 Then
		showStepLog("Da qua " & $hour & "h" & $min & " => bo qua " & $funcName)
		Return False
	EndIf
	showStepLog("Cho toi " & $hour & "h" & $min & " de chay " & $funcName & " (" & timeToText($diff) & ")")
	Sleep($diff)
	showStepLog("Dang chay " & $funcName)
	Local $result = Call($funcName)
	showStepLog("Xong " & $funcName & " - thanh cong: " & $result)
	Return True
EndFunc   ;==>runScheduledStep

; Method: showStepLog
; Description: Ghi log console va hien thong bao tray tren man hinh (TrayTip khong de lai overlay len cua so game)
Func showStepLog($text)
	writeLog($text)
	TrayTip("Auto Plus", $text, 5)
EndFunc   ;==>showStepLog

; Method: startPath
; Description: Executes auto reset V2 executable path.
Func startPath()
	Local $exePath = $featurePathRoot & "auto_reset\auto_rs_v2.exe"
	writeLog($exePath)
	Run($exePath)
	ProcessWaitClose("auto_rs_v2.exe")
	Return True
EndFunc   ;==>startPath
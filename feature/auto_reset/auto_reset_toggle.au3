#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"

$className = "auto_reset_toggle.au3"

; Thu vien bat/tat checkbox reset trong Auto Plus cho cac char active trong config.
; Entry point de dat lich (Task Scheduler): auto_reset_on.au3 (bat) va auto_reset_off.au3 (tat).

; Method: startAutoResetOn
; Description: Bat checkbox reset cho cac char active trong config
Func startAutoResetOn()
	Return runAutoResetToggle(True)
EndFunc   ;==>startAutoResetOn

; Method: startAutoResetOff
; Description: Tat checkbox reset cho cac char active trong config
Func startAutoResetOff()
	Return runAutoResetToggle(False)
EndFunc   ;==>startAutoResetOff

; Method: runAutoResetToggle
; Description: Bat/tat checkbox reset cho cac char active trong config. Tra ve so char xu ly thanh cong.
Func runAutoResetToggle($enable)
	Local $sFilePath = $outputPathRoot & ($enable ? "File_Log_AutoResetOn_.txt" : "File_Log_AutoResetOff_.txt")
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	writeLogMethodStart("runAutoResetToggle", @ScriptLineNumber, "enable=" & $enable)

	Local $successCount = 0
	Local $aActive = getActiveResetToggleChars()
	If UBound($aActive) == 0 Then
		writeLogFile($logFile, "Khong co char nao active trong config auto reset toggle")
	Else
		For $i = 0 To UBound($aActive) - 1
			If processResetToggleChar($aActive[$i], $enable) Then $successCount += 1
		Next
	EndIf

	writeLogMethodEnd("runAutoResetToggle", @ScriptLineNumber, "thanh cong " & $successCount & "/" & UBound($aActive))
	FileClose($logFile)
	Return $successCount
EndFunc   ;==>runAutoResetToggle

; Method: getActiveResetToggleChars
; Description: Doc config va tra ve danh sach record active
Func getActiveResetToggleChars()
	Local $aActive[0]
	Local $jConfig = getJsonFromFile($jsonPathRoot & $autoResetToggleConfigFileName)
	For $i = 0 To UBound($jConfig) - 1
		If getPropertyJson($jConfig[$i], "active") Then
			$aActive = redimArray($aActive, $jConfig[$i])
		EndIf
	Next
	writeLogFile($logFile, "So char active trong auto reset toggle: " & UBound($aActive))
	Return $aActive
EndFunc   ;==>getActiveResetToggleChars

; Method: processResetToggleChar
; Description: Active cua so char (co the switch tu char khac cung tai khoan) roi bat/tat checkbox reset
; Note: is_swith_other_char (giu nguyen ten "swith" de tuong thich config) = cho phep switch tu char khac cung tai khoan
Func processResetToggleChar($jChar, $enable)
	Local $charName = getPropertyJson($jChar, "char_name")
	Local $isSwitchOther = getPropertyJson($jChar, "is_swith_other_char") == True
	writeLogFile($logFile, "Xu ly char: " & $charName & " - enable reset: " & $enable & " - switch other: " & $isSwitchOther)

	If Not activeCharForAutoPlus($charName, $isSwitchOther) Then
		writeLogFile($logFile, "Khong active duoc char " & $charName & " => Bo qua")
		Return False
	EndIf
	; Thuc hien bam enter 1 lan de xoa bo cac popup (neu co) truoc khi bat/tat checkbox reset
	sendKeyEnter()
	secondWait(1)
	
	Local $result = applyResetCheckboxState($enable)
	writeLogFile($logFile, "Ket qua toggle reset char " & $charName & ": " & $result)
	minisizeMainByChar($charName)
	Return $result
EndFunc   ;==>processResetToggleChar

#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"

$className = "auto_devil_toggle.au3"

; Thu vien bat/tat checkbox devil trong Auto Plus cho cac char active trong config.
; Entry point de dat lich (Task Scheduler): auto_devil_on.au3 (bat) va auto_devil_off.au3 (tat).

; Method: startAutoDevilOn
; Description: Bat checkbox devil cho cac char active trong config
Func startAutoDevilOn()
	Return runAutoDevilToggle(True)
EndFunc   ;==>startAutoDevilOn

; Method: startAutoDevilOff
; Description: Tat checkbox devil cho cac char active trong config
Func startAutoDevilOff()
	Return runAutoDevilToggle(False)
EndFunc   ;==>startAutoDevilOff

; Method: runAutoDevilToggle
; Description: Bat/tat checkbox devil cho cac char active trong config. Tra ve so char xu ly thanh cong.
Func runAutoDevilToggle($enable)
	Local $sFilePath = $outputPathRoot & ($enable ? "File_Log_AutoDevilOn_.txt" : "File_Log_AutoDevilOff_.txt")
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	writeLogMethodStart("runAutoDevilToggle", @ScriptLineNumber, "enable=" & $enable)

	Local $successCount = 0
	Local $aActive = getActiveDevilToggleChars()
	If UBound($aActive) == 0 Then
		writeLogFile($logFile, "Khong co char nao active trong config auto devil toggle")
	Else
		For $i = 0 To UBound($aActive) - 1
			If processDevilToggleChar($aActive[$i], $enable) Then $successCount += 1
		Next
	EndIf

	writeLogMethodEnd("runAutoDevilToggle", @ScriptLineNumber, "thanh cong " & $successCount & "/" & UBound($aActive))
	FileClose($logFile)
	Return $successCount
EndFunc   ;==>runAutoDevilToggle

; Method: getActiveDevilToggleChars
; Description: Doc config va tra ve danh sach record active
Func getActiveDevilToggleChars()
	Local $aActive[0]
	Local $jConfig = getJsonFromFile($jsonPathRoot & $autoDevilToggleConfigFileName)
	For $i = 0 To UBound($jConfig) - 1
		If getPropertyJson($jConfig[$i], "active") Then
			$aActive = redimArray($aActive, $jConfig[$i])
		EndIf
	Next
	writeLogFile($logFile, "So char active trong auto devil toggle: " & UBound($aActive))
	Return $aActive
EndFunc   ;==>getActiveDevilToggleChars

; Method: processDevilToggleChar
; Description: Active cua so char (co the switch tu char khac cung tai khoan) roi bat/tat checkbox devil
; Note: is_swith_other_char (giu nguyen ten "swith" de dong bo voi auto reset toggle) = cho phep switch tu char khac cung tai khoan
Func processDevilToggleChar($jChar, $enable)
	Local $charName = getPropertyJson($jChar, "char_name")
	Local $isSwitchOther = getPropertyJson($jChar, "is_swith_other_char") == True
	writeLogFile($logFile, "Xu ly char: " & $charName & " - enable devil: " & $enable & " - switch other: " & $isSwitchOther)

	If Not activeCharForAutoPlus($charName, $isSwitchOther) Then
		writeLogFile($logFile, "Khong active duoc char " & $charName & " => Bo qua")
		Return False
	EndIf
	; Bam enter 1 lan de xoa cac popup (neu co) truoc khi bat/tat checkbox devil
	sendKeyEnter()
	secondWait(1)

	Local $result = applyDevilCheckboxState($enable)
	writeLogFile($logFile, "Ket qua toggle devil char " & $charName & ": " & $result)
	minisizeMainByChar($charName)
	Return $result
EndFunc   ;==>processDevilToggleChar

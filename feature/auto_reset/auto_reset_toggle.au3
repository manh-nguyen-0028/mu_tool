#include-once
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"

$className = "auto_reset_toggle.au3"

; Moc gio bat/tat checkbox reset trong Auto Plus (tinh theo phut trong ngay) va do lech cho phep (+- phut)
Global Const $RS_TOGGLE_ON_MINUTE = 6              ; 00:06 => bat
Global Const $RS_TOGGLE_OFF_MINUTE = 6 * 60 + 30   ; 06:30 => tat
Global Const $RS_TOGGLE_WINDOW_MINUTE = 5

; Debounce: ngay (YYYY/MM/DD) da chay moc bat/tat gan nhat trong tien trinh hien tai
Global $rsToggleLastDateOn = "", $rsToggleLastDateOff = ""

; Ket qua cua resolveResetToggleAction
Global Const $RS_TOGGLE_ACTION_SKIP = -1, $RS_TOGGLE_ACTION_OFF = 0, $RS_TOGGLE_ACTION_ON = 1

;~ startAutoResetToggle()

; Method: startAutoResetToggle
; Description: Bat checkbox reset luc 00:06 va tat luc 06:30 (+- 5 phut) cho cac char active trong config.
;              Moi moc chay toi da 1 lan/ngay. Goi duoc nhieu lan trong vong lap service.
Func startAutoResetToggle()
	Local $sFilePath = $outputPathRoot & "File_Log_AutoResetToggle_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	writeLogMethodStart("startAutoResetToggle", @ScriptLineNumber)

	Local $todayStr = @YEAR & "/" & @MON & "/" & @MDAY
	Local $action = resolveResetToggleAction(@HOUR * 60 + @MIN, $todayStr)
	If $action == $RS_TOGGLE_ACTION_SKIP Then
		FileClose($logFile)
		Return
	EndIf
	Local $enable = ($action == $RS_TOGGLE_ACTION_ON)

	Local $aActive = getActiveResetToggleChars()
	If UBound($aActive) == 0 Then
		writeLogFile($logFile, "Khong co char nao active trong config auto reset toggle")
	Else
		For $i = 0 To UBound($aActive) - 1
			processResetToggleChar($aActive[$i], $enable)
		Next
	EndIf

	If $enable Then
		$rsToggleLastDateOn = $todayStr
	Else
		$rsToggleLastDateOff = $todayStr
	EndIf

	writeLogMethodEnd("startAutoResetToggle", @ScriptLineNumber)
	FileClose($logFile)
EndFunc   ;==>startAutoResetToggle

; Method: resolveResetToggleAction
; Description: Xac dinh hanh dong (BAT/TAT/bo qua) theo phut trong ngay va debounce theo ngay
Func resolveResetToggleAction($nowMinute, $todayStr)
	If isInToggleWindow($RS_TOGGLE_ON_MINUTE, $nowMinute) Then
		If $rsToggleLastDateOn == $todayStr Then
			writeLogFile($logFile, "Moc BAT reset da chay hom nay => Bo qua")
			Return $RS_TOGGLE_ACTION_SKIP
		EndIf
		Return $RS_TOGGLE_ACTION_ON
	ElseIf isInToggleWindow($RS_TOGGLE_OFF_MINUTE, $nowMinute) Then
		If $rsToggleLastDateOff == $todayStr Then
			writeLogFile($logFile, "Moc TAT reset da chay hom nay => Bo qua")
			Return $RS_TOGGLE_ACTION_SKIP
		EndIf
		Return $RS_TOGGLE_ACTION_OFF
	EndIf
	writeLogFile($logFile, "Chua den moc gio bat/tat reset => Bo qua")
	Return $RS_TOGGLE_ACTION_SKIP
EndFunc   ;==>resolveResetToggleAction

; Method: isInToggleWindow
; Description: Kiem tra phut trong ngay (mac dinh = gio hien tai) co nam trong cua so [moc - 5 phut, moc + 5 phut] hay khong
Func isInToggleWindow($targetMinuteOfDay, $nowMinute = Default)
	If IsKeyword($nowMinute) Then $nowMinute = @HOUR * 60 + @MIN
	Return Abs($nowMinute - $targetMinuteOfDay) <= $RS_TOGGLE_WINDOW_MINUTE
EndFunc   ;==>isInToggleWindow

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

	Local $result = applyResetCheckboxState($enable)
	writeLogFile($logFile, "Ket qua toggle reset char " & $charName & ": " & $result)
	minisizeMainByChar($charName)
	Return $result
EndFunc   ;==>processResetToggleChar

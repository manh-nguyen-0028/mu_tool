#include-once
#include "../../utils/common_utils.au3"
#include "../auto_reset/auto_reset_toggle.au3"

; Chay bo test cho logic auto reset toggle (khong phu thuoc game runtime).
runAllTestsAutoResetToggle()

Func runAllTestsAutoResetToggle()
	Local $total = 0
	Local $pass = 0

	If _RunTestCaseToggle("testIsInToggleWindow", testIsInToggleWindow()) Then $pass += 1
	$total += 1

	If _RunTestCaseToggle("testResolveResetToggleAction", testResolveResetToggleAction()) Then $pass += 1
	$total += 1

	If _RunTestCaseToggle("testResolveResetToggleActionDebounce", testResolveResetToggleActionDebounce()) Then $pass += 1
	$total += 1

	If _RunTestCaseToggle("testGetActiveResetToggleChars", testGetActiveResetToggleChars()) Then $pass += 1
	$total += 1

	If _RunTestCaseToggle("testGetActiveResetToggleCharsNoneActive", testGetActiveResetToggleCharsNoneActive()) Then $pass += 1
	$total += 1

	ConsoleWrite("[TEST SUMMARY] auto_reset_toggle PASS " & $pass & "/" & $total & @CRLF)
	Return ($pass == $total)
EndFunc   ;==>runAllTestsAutoResetToggle

Func _RunTestCaseToggle($name, $ok)
	ConsoleWrite("[TEST " & $name & "] " & ($ok ? "PASS" : "FAIL") & @CRLF)
	Return $ok
EndFunc   ;==>_RunTestCaseToggle

Func _AssertToggle($label, $actual, $expected)
	If $actual == $expected Then Return True
	ConsoleWrite("  [ASSERT FAIL] " & $label & " expected=" & $expected & " actual=" & $actual & @CRLF)
	Return False
EndFunc   ;==>_AssertToggle

; Bien gio:phut thanh phut trong ngay
Func _ToMinuteOfDay($hour, $min)
	Return $hour * 60 + $min
EndFunc   ;==>_ToMinuteOfDay

Func testIsInToggleWindow()
	; [target, now, expected]
	Local $cases[10][3] = [ _
			[$RS_TOGGLE_ON_MINUTE, _ToMinuteOfDay(0, 0), False], _
			[$RS_TOGGLE_ON_MINUTE, _ToMinuteOfDay(0, 1), True], _
			[$RS_TOGGLE_ON_MINUTE, _ToMinuteOfDay(0, 6), True], _
			[$RS_TOGGLE_ON_MINUTE, _ToMinuteOfDay(0, 11), True], _
			[$RS_TOGGLE_ON_MINUTE, _ToMinuteOfDay(0, 12), False], _
			[$RS_TOGGLE_OFF_MINUTE, _ToMinuteOfDay(6, 24), False], _
			[$RS_TOGGLE_OFF_MINUTE, _ToMinuteOfDay(6, 25), True], _
			[$RS_TOGGLE_OFF_MINUTE, _ToMinuteOfDay(6, 30), True], _
			[$RS_TOGGLE_OFF_MINUTE, _ToMinuteOfDay(6, 35), True], _
			[$RS_TOGGLE_OFF_MINUTE, _ToMinuteOfDay(6, 36), False]]

	Local $ok = True
	For $i = 0 To UBound($cases) - 1
		Local $actual = isInToggleWindow($cases[$i][0], $cases[$i][1])
		If Not _AssertToggle("isInToggleWindow(" & $cases[$i][0] & ", " & $cases[$i][1] & ")", $actual, $cases[$i][2]) Then $ok = False
	Next
	Return $ok
EndFunc   ;==>testIsInToggleWindow

Func testResolveResetToggleAction()
	Local $today = "2026/10/21"
	$rsToggleLastDateOn = ""
	$rsToggleLastDateOff = ""

	; [now, expected action]
	Local $cases[9][2] = [ _
			[_ToMinuteOfDay(0, 0), $RS_TOGGLE_ACTION_SKIP], _
			[_ToMinuteOfDay(0, 1), $RS_TOGGLE_ACTION_ON], _
			[_ToMinuteOfDay(0, 6), $RS_TOGGLE_ACTION_ON], _
			[_ToMinuteOfDay(0, 11), $RS_TOGGLE_ACTION_ON], _
			[_ToMinuteOfDay(3, 0), $RS_TOGGLE_ACTION_SKIP], _
			[_ToMinuteOfDay(6, 25), $RS_TOGGLE_ACTION_OFF], _
			[_ToMinuteOfDay(6, 35), $RS_TOGGLE_ACTION_OFF], _
			[_ToMinuteOfDay(12, 0), $RS_TOGGLE_ACTION_SKIP], _
			[_ToMinuteOfDay(23, 59), $RS_TOGGLE_ACTION_SKIP]]

	Local $ok = True
	For $i = 0 To UBound($cases) - 1
		Local $actual = resolveResetToggleAction($cases[$i][0], $today)
		If Not _AssertToggle("resolveResetToggleAction(" & $cases[$i][0] & ")", $actual, $cases[$i][1]) Then $ok = False
	Next
	Return $ok
EndFunc   ;==>testResolveResetToggleAction

Func testResolveResetToggleActionDebounce()
	Local $today = "2026/10/21", $tomorrow = "2026/10/22"
	Local $ok = True

	; Moc BAT da chay hom nay => bo qua, moc TAT van chay
	$rsToggleLastDateOn = $today
	$rsToggleLastDateOff = ""
	If Not _AssertToggle("ON da chay hom nay", resolveResetToggleAction(_ToMinuteOfDay(0, 6), $today), $RS_TOGGLE_ACTION_SKIP) Then $ok = False
	If Not _AssertToggle("OFF chua chay", resolveResetToggleAction(_ToMinuteOfDay(6, 30), $today), $RS_TOGGLE_ACTION_OFF) Then $ok = False

	; Moc TAT da chay hom nay => bo qua
	$rsToggleLastDateOff = $today
	If Not _AssertToggle("OFF da chay hom nay", resolveResetToggleAction(_ToMinuteOfDay(6, 30), $today), $RS_TOGGLE_ACTION_SKIP) Then $ok = False

	; Sang ngay moi => chay lai ca 2 moc
	If Not _AssertToggle("ON ngay moi", resolveResetToggleAction(_ToMinuteOfDay(0, 6), $tomorrow), $RS_TOGGLE_ACTION_ON) Then $ok = False
	If Not _AssertToggle("OFF ngay moi", resolveResetToggleAction(_ToMinuteOfDay(6, 30), $tomorrow), $RS_TOGGLE_ACTION_OFF) Then $ok = False

	$rsToggleLastDateOn = ""
	$rsToggleLastDateOff = ""
	Return $ok
EndFunc   ;==>testResolveResetToggleActionDebounce

; Ghi config tam vao @TempDir, tro $jsonPathRoot sang do, goi getActiveResetToggleChars roi khoi phuc
Func _GetActiveCharsFromJsonText($jsonText)
	Local $backupPathRoot = $jsonPathRoot, $backupFileName = $autoResetToggleConfigFileName
	Local $tmpFileName = "test_auto_reset_toggle_config.json"
	Local $hFile = FileOpen(@TempDir & "\" & $tmpFileName, 2 + 256)
	FileWrite($hFile, $jsonText)
	FileClose($hFile)

	$jsonPathRoot = @TempDir & "\"
	$autoResetToggleConfigFileName = $tmpFileName
	Local $aActive = getActiveResetToggleChars()

	$jsonPathRoot = $backupPathRoot
	$autoResetToggleConfigFileName = $backupFileName
	FileDelete(@TempDir & "\" & $tmpFileName)
	Return $aActive
EndFunc   ;==>_GetActiveCharsFromJsonText

Func testGetActiveResetToggleChars()
	Local $aActive = _GetActiveCharsFromJsonText('[' & _
			'{"active":true,"char_name":"char1","is_swith_other_char":false,"other_char_name":""},' & _
			'{"active":false,"char_name":"char2","is_swith_other_char":false,"other_char_name":""},' & _
			'{"active":true,"char_name":"char3","is_swith_other_char":true,"other_char_name":"char4"}]')

	If Not _AssertToggle("so char active", UBound($aActive), 2) Then Return False
	Local $ok = True
	If Not _AssertToggle("char[0]", getPropertyJson($aActive[0], "char_name"), "char1") Then $ok = False
	If Not _AssertToggle("char[1]", getPropertyJson($aActive[1], "char_name"), "char3") Then $ok = False
	If Not _AssertToggle("char[1] switch other", getPropertyJson($aActive[1], "is_swith_other_char") == True, True) Then $ok = False
	Return $ok
EndFunc   ;==>testGetActiveResetToggleChars

Func testGetActiveResetToggleCharsNoneActive()
	Local $aActive = _GetActiveCharsFromJsonText('[' & _
			'{"active":false,"char_name":"char1","is_swith_other_char":false,"other_char_name":""},' & _
			'{"active":false,"char_name":"char2","is_swith_other_char":true,"other_char_name":"char3"}]')
	Return _AssertToggle("so char active", UBound($aActive), 0)
EndFunc   ;==>testGetActiveResetToggleCharsNoneActive

#include-once
#include "../../utils/common_utils.au3"
#include "../auto_reset/auto_reset_toggle.au3"

Global Const $TEST_TOGGLE_CONFIG_FILE = "test_auto_reset_toggle_config.json"
Global $testToggleBackupPathRoot, $testToggleBackupFileName

; Chay bo test cho logic auto reset toggle (khong phu thuoc game runtime).
runAllTestsAutoResetToggle()

Func runAllTestsAutoResetToggle()
	Local $total = 0
	Local $pass = 0

	If _RunTestCaseToggle("testGetActiveResetToggleChars", testGetActiveResetToggleChars()) Then $pass += 1
	$total += 1

	If _RunTestCaseToggle("testGetActiveResetToggleCharsNoneActive", testGetActiveResetToggleCharsNoneActive()) Then $pass += 1
	$total += 1

	If _RunTestCaseToggle("testStartAutoResetOnNoActiveChar", testStartAutoResetOnNoActiveChar()) Then $pass += 1
	$total += 1

	If _RunTestCaseToggle("testStartAutoResetOffNoActiveChar", testStartAutoResetOffNoActiveChar()) Then $pass += 1
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

; Ghi config tam vao @TempDir va tro $jsonPathRoot sang do
Func _UseTempToggleConfig($jsonText)
	$testToggleBackupPathRoot = $jsonPathRoot
	$testToggleBackupFileName = $autoResetToggleConfigFileName
	Local $hFile = FileOpen(@TempDir & "\" & $TEST_TOGGLE_CONFIG_FILE, 2 + 256)
	FileWrite($hFile, $jsonText)
	FileClose($hFile)
	$jsonPathRoot = @TempDir & "\"
	$autoResetToggleConfigFileName = $TEST_TOGGLE_CONFIG_FILE
EndFunc   ;==>_UseTempToggleConfig

; Khoi phuc config goc va xoa file tam
Func _RestoreToggleConfig()
	$jsonPathRoot = $testToggleBackupPathRoot
	$autoResetToggleConfigFileName = $testToggleBackupFileName
	FileDelete(@TempDir & "\" & $TEST_TOGGLE_CONFIG_FILE)
EndFunc   ;==>_RestoreToggleConfig

Func _NoActiveConfigText()
	Return '[' & _
			'{"active":false,"char_name":"QuyHuyet","is_swith_other_char":false,"other_char_name":""},' & _
			'{"active":false,"char_name":"char2","is_swith_other_char":true,"other_char_name":"char3"}]'
EndFunc   ;==>_NoActiveConfigText

Func testGetActiveResetToggleChars()
	_UseTempToggleConfig('[' & _
			'{"active":true,"char_name":"QuyHuyet","is_swith_other_char":false,"other_char_name":""},' & _
			'{"active":false,"char_name":"char2","is_swith_other_char":false,"other_char_name":""},' & _
			'{"active":true,"char_name":"char3","is_swith_other_char":true,"other_char_name":"char4"}]')
	Local $aActive = getActiveResetToggleChars()
	_RestoreToggleConfig()

	If Not _AssertToggle("so char active", UBound($aActive), 2) Then Return False
	Local $ok = True
	If Not _AssertToggle("char[0]", getPropertyJson($aActive[0], "char_name"), "QuyHuyet") Then $ok = False
	If Not _AssertToggle("char[1]", getPropertyJson($aActive[1], "char_name"), "char3") Then $ok = False
	If Not _AssertToggle("char[1] switch other", getPropertyJson($aActive[1], "is_swith_other_char") == True, True) Then $ok = False
	Return $ok
EndFunc   ;==>testGetActiveResetToggleChars

Func testGetActiveResetToggleCharsNoneActive()
	_UseTempToggleConfig(_NoActiveConfigText())
	Local $aActive = getActiveResetToggleChars()
	_RestoreToggleConfig()
	Return _AssertToggle("so char active", UBound($aActive), 0)
EndFunc   ;==>testGetActiveResetToggleCharsNoneActive

; Khong co char active => khong dung toi game, tra ve 0 char thanh cong
Func testStartAutoResetOnNoActiveChar()
	_UseTempToggleConfig(_NoActiveConfigText())
	Local $count = startAutoResetOn()
	_RestoreToggleConfig()
	Return _AssertToggle("startAutoResetOn so char thanh cong", $count, 0)
EndFunc   ;==>testStartAutoResetOnNoActiveChar

Func testStartAutoResetOffNoActiveChar()
	_UseTempToggleConfig(_NoActiveConfigText())
	Local $count = startAutoResetOff()
	_RestoreToggleConfig()
	Return _AssertToggle("startAutoResetOff so char thanh cong", $count, 0)
EndFunc   ;==>testStartAutoResetOffNoActiveChar

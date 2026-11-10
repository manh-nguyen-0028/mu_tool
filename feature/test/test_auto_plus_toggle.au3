#include-once
#include "../../utils/common_utils.au3"
#include "../auto_reset/auto_reset_toggle.au3"
#include "../auto_devil/auto_devil_toggle.au3"

; Test THAT tren game: bat/tat checkbox reset + devil cho 1 char.
; Cach chay: test_auto_plus_toggle.au3 <ten_char> [true|false: cho phep switch tu char khac]
Global $testPlusCharName = "QuyHuyet"
Global $testPlusSwitchOther = False
Global $testPlusBackupPathRoot, $testPlusBackupResetFile, $testPlusBackupDevilFile
Global Const $TEST_PLUS_RESET_CONFIG = "test_auto_plus_reset_config.json"
Global Const $TEST_PLUS_DEVIL_CONFIG = "test_auto_plus_devil_config.json"

If $CmdLine[0] >= 1 Then $testPlusCharName = $CmdLine[1]
If $CmdLine[0] >= 2 Then $testPlusSwitchOther = ($CmdLine[2] == "true")

runAllTestsAutoPlusToggle($testPlusCharName, $testPlusSwitchOther)

Func runAllTestsAutoPlusToggle($charName, $switchOther)
	Local $total = 0
	Local $pass = 0
	ConsoleWrite("[TEST] char=" & $charName & " switchOther=" & $switchOther & @CRLF)

	_UseTempPlusConfig($charName, $switchOther)

	If _RunTestCasePlus("testStartAutoResetOn", _AssertPlus("startAutoResetOn", startAutoResetOn(), 1)) Then $pass += 1
	$total += 1

	If _RunTestCasePlus("testStartAutoResetOff", _AssertPlus("startAutoResetOff", startAutoResetOff(), 1)) Then $pass += 1
	$total += 1

	If _RunTestCasePlus("testStartAutoDevilOn", _AssertPlus("startAutoDevilOn", startAutoDevilOn(), 1)) Then $pass += 1
	$total += 1

	If _RunTestCasePlus("testStartAutoDevilOff", _AssertPlus("startAutoDevilOff", startAutoDevilOff(), 1)) Then $pass += 1
	$total += 1

	_RestorePlusConfig()

	ConsoleWrite("[TEST SUMMARY] auto_plus_toggle PASS " & $pass & "/" & $total & @CRLF)
	Return ($pass == $total)
EndFunc   ;==>runAllTestsAutoPlusToggle

Func _RunTestCasePlus($name, $ok)
	ConsoleWrite("[TEST " & $name & "] " & ($ok ? "PASS" : "FAIL") & @CRLF)
	Return $ok
EndFunc   ;==>_RunTestCasePlus

Func _AssertPlus($label, $actual, $expected)
	If $actual == $expected Then Return True
	ConsoleWrite("  [ASSERT FAIL] " & $label & " expected=" & $expected & " actual=" & $actual & @CRLF)
	Return False
EndFunc   ;==>_AssertPlus

; Ghi config tam (1 char active) vao @TempDir de khong dong toi config that
Func _UseTempPlusConfig($charName, $switchOther)
	$testPlusBackupPathRoot = $jsonPathRoot
	$testPlusBackupResetFile = $autoResetToggleConfigFileName
	$testPlusBackupDevilFile = $autoDevilToggleConfigFileName

	Local $jsonText = '[{"active":true,"char_name":"' & $charName & '","is_swith_other_char":' & ($switchOther ? "true" : "false") & ',"other_char_name":""}]'
	_WritePlusFile($TEST_PLUS_RESET_CONFIG, $jsonText)
	_WritePlusFile($TEST_PLUS_DEVIL_CONFIG, $jsonText)

	$jsonPathRoot = @TempDir & "\"
	$autoResetToggleConfigFileName = $TEST_PLUS_RESET_CONFIG
	$autoDevilToggleConfigFileName = $TEST_PLUS_DEVIL_CONFIG
EndFunc   ;==>_UseTempPlusConfig

Func _WritePlusFile($fileName, $text)
	Local $hFile = FileOpen(@TempDir & "\" & $fileName, 2 + 256)
	FileWrite($hFile, $text)
	FileClose($hFile)
EndFunc   ;==>_WritePlusFile

Func _RestorePlusConfig()
	$jsonPathRoot = $testPlusBackupPathRoot
	$autoResetToggleConfigFileName = $testPlusBackupResetFile
	$autoDevilToggleConfigFileName = $testPlusBackupDevilFile
	FileDelete(@TempDir & "\" & $TEST_PLUS_RESET_CONFIG)
	FileDelete(@TempDir & "\" & $TEST_PLUS_DEVIL_CONFIG)
EndFunc   ;==>_RestorePlusConfig

#include-once
#include "../../utils/common_utils.au3"
#include "../auto_reset/auto_reset_toggle.au3"
#include "../auto_devil/auto_devil_toggle.au3"

; Test THAT tren game: bat/tat checkbox reset + devil cho 1 char.
; Cach chay: test_auto_plus_toggle.au3 <ten_char> [true|false: cho phep switch tu char khac] [case]
;   case: all (mac dinh) | reset_on | reset_off | devil_on | devil_off
;   Co the chay nhieu case, cach nhau dau phay. Vd: reset_on,devil_off
Global $testPlusCharName = "QuyHuyet"
Global $testPlusSwitchOther = False
Global $testPlusCase = "all"
Global $testPlusBackupPathRoot, $testPlusBackupResetFile, $testPlusBackupDevilFile
Global Const $TEST_PLUS_RESET_CONFIG = "test_auto_plus_reset_config.json"
Global Const $TEST_PLUS_DEVIL_CONFIG = "test_auto_plus_devil_config.json"
; Danh sach case: [ten case, ten test, ham can goi]
Global Const $TEST_PLUS_CASES[4][3] = [ _
		["reset_on", "testStartAutoResetOn", "startAutoResetOn"], _
		["reset_off", "testStartAutoResetOff", "startAutoResetOff"], _
		["devil_on", "testStartAutoDevilOn", "startAutoDevilOn"], _
		["devil_off", "testStartAutoDevilOff", "startAutoDevilOff"]]

If $CmdLine[0] >= 1 Then $testPlusCharName = $CmdLine[1]
If $CmdLine[0] >= 2 Then $testPlusSwitchOther = ($CmdLine[2] == "true")
If $CmdLine[0] >= 3 Then $testPlusCase = $CmdLine[3]

runTestsAutoPlusToggle($testPlusCharName, $testPlusSwitchOther, $testPlusCase)

Func runAllTestsAutoPlusToggle($charName, $switchOther)
	Return runTestsAutoPlusToggle($charName, $switchOther, "all")
EndFunc   ;==>runAllTestsAutoPlusToggle

; Chay 1 hoac nhieu case (cach nhau dau phay), "all" = tat ca
Func runTestsAutoPlusToggle($charName, $switchOther, $caseList = "all")
	Local $total = 0
	Local $pass = 0
	Local $runAll = ($caseList == "" Or $caseList == "all")
	Local $wanted = StringSplit(StringStripWS($caseList, 8), ",")
	ConsoleWrite("[TEST] char=" & $charName & " switchOther=" & $switchOther & " case=" & $caseList & @CRLF)

	; Kiem tra ten case hop le truoc khi dong vao game
	If Not $runAll Then
		For $j = 1 To $wanted[0]
			If _FindPlusCase($wanted[$j]) < 0 Then
				ConsoleWrite("[TEST] Case khong ton tai: " & $wanted[$j] & " (all|reset_on|reset_off|devil_on|devil_off)" & @CRLF)
				Return False
			EndIf
		Next
	EndIf

	_UseTempPlusConfig($charName, $switchOther)

	For $i = 0 To UBound($TEST_PLUS_CASES) - 1
		If Not $runAll And Not _IsPlusCaseWanted($TEST_PLUS_CASES[$i][0], $wanted) Then ContinueLoop
		Local $funcName = $TEST_PLUS_CASES[$i][2]
		If _RunTestCasePlus($TEST_PLUS_CASES[$i][1], _AssertPlus($funcName, Call($funcName), 1)) Then $pass += 1
		$total += 1
	Next

	_RestorePlusConfig()

	ConsoleWrite("[TEST SUMMARY] auto_plus_toggle PASS " & $pass & "/" & $total & @CRLF)
	Return ($pass == $total)
EndFunc   ;==>runTestsAutoPlusToggle

Func _FindPlusCase($caseName)
	For $i = 0 To UBound($TEST_PLUS_CASES) - 1
		If $TEST_PLUS_CASES[$i][0] = $caseName Then Return $i
	Next
	Return -1
EndFunc   ;==>_FindPlusCase

Func _IsPlusCaseWanted($caseName, $wanted)
	For $j = 1 To $wanted[0]
		If $wanted[$j] = $caseName Then Return True
	Next
	Return False
EndFunc   ;==>_IsPlusCaseWanted

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

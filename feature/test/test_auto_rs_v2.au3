#include-once
#include "../../utils/common_utils.au3"
#include "../auto_reset/auto_rs_v2.au3"

; Chay bo test nhanh cho logic V2 khong phu thuoc web/game runtime.
runAllTestsAutoRsV2()

Func runAllTestsAutoRsV2()
	Local $total = 0
	Local $pass = 0

	If _RunTestCase("testCalculateRequiredLevelForResetV2", testCalculateRequiredLevelForResetV2()) Then $pass += 1
	$total += 1

	If _RunTestCase("testNormalizeAccountV2Defaults", testNormalizeAccountV2Defaults()) Then $pass += 1
	$total += 1

	If _RunTestCase("testExtractAccountInfoV2UsernameFallback", testExtractAccountInfoV2UsernameFallback()) Then $pass += 1
	$total += 1

	If _RunTestCase("testValidRsIsMaxResetReachedV2", testValidRsIsMaxResetReachedV2()) Then $pass += 1
	$total += 1

	ConsoleWrite("[TEST SUMMARY] auto_rs_v2 PASS " & $pass & "/" & $total & @CRLF)
	Return ($pass == $total)
EndFunc   ;==>runAllTestsAutoRsV2

Func _RunTestCase($name, $ok)
	ConsoleWrite("[TEST " & $name & "] " & ($ok ? "PASS" : "FAIL") & @CRLF)
	Return $ok
EndFunc   ;==>_RunTestCase

Func testCalculateRequiredLevelForResetV2()
	If calculateRequiredLevelForResetV2(0) <> 200 Then Return False
	If calculateRequiredLevelForResetV2(10) <> 250 Then Return False
	If calculateRequiredLevelForResetV2(40) <> 400 Then Return False
	If calculateRequiredLevelForResetV2(120) <> 400 Then Return False
	Return True
EndFunc   ;==>testCalculateRequiredLevelForResetV2

Func testNormalizeAccountV2Defaults()
	Local $jAccount = getJsonFromText('{"user_name":"tester_v2","char_name":"CharA"}')
	Local $jNormalized = _NormalizeAccountV2($jAccount)

	If getPropertyJson($jNormalized, "username") <> "tester_v2" Then Return False
	If getPropertyJson($jNormalized, "user_name") <> "tester_v2" Then Return False
	If getPropertyJson($jNormalized, "go_arena") <> False Then Return False
	If Number(getPropertyJson($jNormalized, "hour_per_reset")) <> 1 Then Return False
	If Number(getPropertyJson($jNormalized, "arena_loop_count")) <> 5 Then Return False
	If Number(getPropertyJson($jNormalized, "rs")) <> 0 Then Return False
	If Number(getPropertyJson($jNormalized, "max_rs")) <> 2000 Then Return False
	Return True
EndFunc   ;==>testNormalizeAccountV2Defaults

Func testExtractAccountInfoV2UsernameFallback()
	Local $jAccount = getJsonFromText('{"user_name":"legacy_user","password":"p","char_name":"CharB","type_rs":1,"hour_per_reset":2,"reset_online":false,"time_rs":0,"arena_loop_count":3,"go_arena":true}')
	Local $oInfo = extractAccountInfoV2($jAccount)

	If $oInfo.Item("username") <> "legacy_user" Then Return False
	If $oInfo.Item("charName") <> "CharB" Then Return False
	If Number($oInfo.Item("hourPerRs")) <> 2 Then Return False
	If Not $oInfo.Item("goArena") Then Return False
	If Number($oInfo.Item("arenaLoopCount")) <> 3 Then Return False
	Return True
EndFunc   ;==>testExtractAccountInfoV2UsernameFallback

Func testValidRsIsMaxResetReachedV2()
	Local $jA = getJsonFromText('{"rs":1999,"max_rs":2000}')
	Local $jB = getJsonFromText('{"rs":2000,"max_rs":3000}')
	Local $jC = getJsonFromText('{"rs":120,"max_rs":100}')
	Local $jD = getJsonFromText('{"rs":50,"max_rs":0}')

	If _ValidRs_IsMaxResetReachedV2($jA) Then Return False
	If Not _ValidRs_IsMaxResetReachedV2($jB) Then Return False
	If Not _ValidRs_IsMaxResetReachedV2($jC) Then Return False
	If _ValidRs_IsMaxResetReachedV2($jD) Then Return False
	Return True
EndFunc   ;==>testValidRsIsMaxResetReachedV2
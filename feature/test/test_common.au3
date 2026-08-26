#include-once
#include "../../utils/common_utils.au3"

testGetTimeWaitNextEvent()
testMergeInfoAccountDevil()

; Method: testGetTimeWaitNextEvent
; Description: Test logic getTimeWaitNextEvent() theo các mốc giờ chính.
Func testGetTimeWaitNextEvent()
	Local $testCases[10][4] = [ _
			[0, 10, 2, 55], _
			[2, 59, 5, 55], _
			[3, 0, 5, 55], _
			[5, 58, 5, 55], _
			[6, 15, 6, 55], _
			[11, 10, 11, 25], _
			[11, 40, 11, 55], _
			[20, 10, 20, 25], _
			[22, 40, 22, 55], _
			[23, 56, 2, 55]]

	Local $passCount = 0
	Local $total = UBound($testCases)

	For $i = 0 To $total - 1
		Local $inputHour = $testCases[$i][0]
		Local $inputMin = $testCases[$i][1]
		Local $expectedHour = $testCases[$i][2]
		Local $expectedMin = $testCases[$i][3]

		Local $actual = getTimeWaitNextEvent($inputHour, $inputMin)
		Local $ok = ($actual[0] == $expectedHour And $actual[1] == $expectedMin)

		Local $msg = "[TEST getTimeWaitNextEvent] input=" & $inputHour & ":" & StringFormat("%02d", $inputMin) & _
				" expected=" & $expectedHour & ":" & StringFormat("%02d", $expectedMin) & _
				" actual=" & $actual[0] & ":" & StringFormat("%02d", $actual[1]) & _
				" => " & ($ok ? "PASS" : "FAIL")

		ConsoleWrite($msg & @CRLF)
		If $ok Then $passCount += 1
	Next

	Local $summary = "[TEST SUMMARY] getTimeWaitNextEvent PASS " & $passCount & "/" & $total
	ConsoleWrite($summary & @CRLF)

	Return $passCount == $total
EndFunc   ;==>testGetTimeWaitNextEvent

; Method: testMergeInfoAccountDevil
; Description: Test mergeInfoAccountDevil() cho 2 truong hop: khong typeFilter va co typeFilter = auto_plus.
Func testMergeInfoAccountDevil()
	; Case 1: khong truyen typeFilter -> lay tat ca account devil active.
	Local $allAccounts = mergeInfoAccountDevil()
	ConsoleWrite("[TEST mergeInfoAccountDevil] Case 1 (khong typeFilter) => so luong: " & UBound($allAccounts) & @CRLF)
	printDevilAccountsInfo($allAccounts)

	; Case 2: truyen typeFilter = auto_plus -> chi lay account type = auto_plus.
	Local $typeFilter = "auto_plus"
	Local $filteredAccounts = mergeInfoAccountDevil($typeFilter)
	ConsoleWrite("[TEST mergeInfoAccountDevil] Case 2 (typeFilter=" & $typeFilter & ") => so luong: " & UBound($filteredAccounts) & @CRLF)
	printDevilAccountsInfo($filteredAccounts)

	; Kiem tra moi ban ghi Case 2 deu co type dung voi typeFilter.
	Local $ok = True
	For $i = 0 To UBound($filteredAccounts) - 1
		Local $itemType = _JSONGet($filteredAccounts[$i], "type")
		If $itemType <> $typeFilter Then
			$ok = False
			ConsoleWrite("[TEST mergeInfoAccountDevil] FAIL - ban ghi " & $i & " co type=" & $itemType & @CRLF)
		EndIf
	Next

	ConsoleWrite("[TEST SUMMARY] mergeInfoAccountDevil typeFilter check => " & ($ok ? "PASS" : "FAIL") & @CRLF)
	Return $ok
EndFunc   ;==>testMergeInfoAccountDevil

; Method: printDevilAccountsInfo
; Description: In danh sach char_name + type cua mang account devil.
Func printDevilAccountsInfo($accounts)
	For $i = 0 To UBound($accounts) - 1
		ConsoleWrite("  - char_name: " & _JSONGet($accounts[$i], "char_name") & " | type: " & _JSONGet($accounts[$i], "type") & @CRLF)
	Next
EndFunc   ;==>printDevilAccountsInfo

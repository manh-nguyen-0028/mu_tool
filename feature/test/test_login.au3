#include-once
#include <Array.au3>
#include <File.au3>
#include <Date.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#RequireAdmin

; ===========================================================================
; TEST LOGIN HARNESS
; Muc dich: test cac case trong .github/plan/auto_login.md
; Cach dung:
; 1) Mo file nay va bo comment case muon test
; 2) Chuan bi config account/position theo case
; 3) Chay script bang SciTE/AutoIt
; ===========================================================================

Global $sAutoLoginScript = $featurePathRoot & "auto_login\\auto_login.au3"
Global $sLoginReportPath = $outputPathRoot & "report_user_login.txt"
Global $sTestLogPath = $outputPathRoot & "File_Log_Test_Login_.txt"
Global $hTestLog = FileOpen($sTestLogPath, $iLogOverwrite)

If $hTestLog = -1 Then
    MsgBox(16, "Loi", "Khong the mo file log test: " & $sTestLogPath)
    Exit
EndIf

writeLogFile($hTestLog, "===== TEST LOGIN START =====")
writeLogFile($hTestLog, "Thoi gian: " & _NowCalc())

; ======================= CHON CASE CAN CHAY =======================
; Unit tests
;~ testCase01_getLoginProperties()
;~ testCase02_getCharInAccount("char1")
;~ testCase03_verifyCharacterWindow("char1")

; Integration tests (can chuan bi du lieu truoc)
;~ testCase04_successCase()
;~ testCase05_wrongCharacterRetryCase()
;~ testCase06_timeoutCase_gameNotOpen()
;~ testCase07_wrongPasswordCase()
;~ testCase08_multipleAccountsCase()

; Quick smoke
testQuickRunAutoLogin()

writeLogFile($hTestLog, "===== TEST LOGIN END =====")
FileClose($hTestLog)

; ---------------------------------------------------------------------------
; UNIT TESTS
; ---------------------------------------------------------------------------

Func testCase01_getLoginProperties()
    writeLogFile($hTestLog, "[CASE-01] getLoginProperty/getProperty for login keys")

    Local $aKeys[13] = [ _
        "button_delete_account_x", "button_delete_account_y", _
        "button_add_account_x", "button_add_account_y", _
        "input_username_x", "input_username_y", _
        "input_password_x", "input_password_y", _
        "first_account_x", "first_account_y", _
        "wait_load_user_sec", "popup_error_ok_x" _
    ]

    For $i = 0 To UBound($aKeys) - 1
        Local $value = getProperty("common.login." & $aKeys[$i])
        If $value = "" Then $value = getProperty($aKeys[$i])

        If $value = "" Then
            writeLogFile($hTestLog, "[FAIL] Missing key: " & $aKeys[$i])
        Else
            writeLogFile($hTestLog, "[PASS] " & $aKeys[$i] & " = " & $value)
        EndIf
    Next

    ; popup_error_ok_y tach rieng de log de doc
    Local $popupY = getProperty("common.login.popup_error_ok_y")
    If $popupY = "" Then $popupY = getProperty("popup_error_ok_y")
    If $popupY = "" Then
        writeLogFile($hTestLog, "[WARN] Missing key: popup_error_ok_y (se fallback button.dong_y.y)")
    Else
        writeLogFile($hTestLog, "[PASS] popup_error_ok_y = " & $popupY)
    EndIf

    Return True
EndFunc

Func testCase02_getCharInAccount($charName)
    writeLogFile($hTestLog, "[CASE-02] getCharInAccount for char=" & $charName)

    If $charInAccountFileName = "" Then
        writeLogFile($hTestLog, "[FAIL] char_in_account file name chua duoc map trong config.json")
        Return False
    EndIf

    Local $aLines = getArrayInFileTxt($textPathRoot & $charInAccountFileName)
    If UBound($aLines) = 0 Then
        writeLogFile($hTestLog, "[FAIL] File char_in_account trong hoac khong ton tai")
        Return False
    EndIf

    For $i = 0 To UBound($aLines) - 1
        If StringInStr($aLines[$i], $charName) Then
            Local $aChars = StringSplit($aLines[$i], "|")
            If @error Or $aChars[0] = 0 Then ExitLoop

            Local $aResult[$aChars[0]]
            For $j = 0 To $aChars[0] - 1
                $aResult[$j] = $aChars[$j + 1]
            Next
            writeLogFile($hTestLog, "[PASS] Tim thay " & UBound($aResult) & " char cung account")
            writeLogFile($hTestLog, "[INFO] " & _ArrayToString($aResult, ", "))
            Return True
        EndIf
    Next

    writeLogFile($hTestLog, "[FAIL] Khong tim thay char trong char_in_account.txt: " & $charName)
    Return False
EndFunc

Func testCase03_verifyCharacterWindow($charName)
    writeLogFile($hTestLog, "[CASE-03] verify active character window for char=" & $charName)

    Local $aLines = getArrayInFileTxt($textPathRoot & $charInAccountFileName)
    If UBound($aLines) = 0 Then
        writeLogFile($hTestLog, "[FAIL] char_in_account.txt rong")
        Return False
    EndIf

    Local $aExpected[0]
    For $i = 0 To UBound($aLines) - 1
        If StringInStr($aLines[$i], $charName) Then
            Local $tmp = StringSplit($aLines[$i], "|")
            If Not @error And $tmp[0] > 0 Then
                Local $aExpected[$tmp[0]]
                For $j = 0 To $tmp[0] - 1
                    $aExpected[$j] = $tmp[$j + 1]
                Next
            EndIf
            ExitLoop
        EndIf
    Next

    If UBound($aExpected) = 0 Then
        writeLogFile($hTestLog, "[FAIL] Khong co danh sach char cung account")
        Return False
    EndIf

    Local $aWindows = WinList()
    For $i = 1 To $aWindows[0][0]
        Local $title = $aWindows[$i][0]
        If StringInStr($title, "MU GamethuVN - Season 21") And StringInStr($title, "Hà Nội") Then
            Local $aMatch = StringRegExp($title, "MU GamethuVN - Season 21 \(Hà Nội - (.*?)\)", 3)
            If UBound($aMatch) > 0 Then
                For $j = 0 To UBound($aExpected) - 1
                    If $aExpected[$j] = $aMatch[0] Then
                        writeLogFile($hTestLog, "[PASS] Active character hop le: " & $aMatch[0])
                        Return True
                    EndIf
                Next
                writeLogFile($hTestLog, "[FAIL] Active character khong hop le: " & $aMatch[0])
                Return False
            EndIf
        EndIf
    Next

    writeLogFile($hTestLog, "[FAIL] Khong tim thay cua so game de verify")
    Return False
EndFunc

; ---------------------------------------------------------------------------
; INTEGRATION TESTS
; ---------------------------------------------------------------------------

Func testCase04_successCase()
    writeLogFile($hTestLog, "[CASE-04] Success case")
    writeLogFile($hTestLog, "[PREPARE] Config account dung va character dung truoc khi chay")
    resetLoginReport()
    runAutoLoginScript()
    assertReportHasStatus("success", 1)
EndFunc

Func testCase05_wrongCharacterRetryCase()
    writeLogFile($hTestLog, "[CASE-05] Wrong character retry case")
    writeLogFile($hTestLog, "[PREPARE] Tao tinh huong vao sai character o lan 1")
    resetLoginReport()
    runAutoLoginScript()
    assertReportHasStatus("retry_success", 1)
EndFunc

Func testCase06_timeoutCase_gameNotOpen()
    writeLogFile($hTestLog, "[CASE-06] Timeout/Game not open case")
    writeLogFile($hTestLog, "[PREPARE] Dat common.game.exe_path sai hoac file khong ton tai")
    resetLoginReport()
    runAutoLoginScript()
    assertReportHasStatus("failed_game_not_open", 1)
EndFunc

Func testCase07_wrongPasswordCase()
    writeLogFile($hTestLog, "[CASE-07] Wrong password case")
    writeLogFile($hTestLog, "[PREPARE] Dat password sai trong file account login")
    resetLoginReport()
    runAutoLoginScript()
    assertReportHasStatus("failed", 1)
EndFunc

Func testCase08_multipleAccountsCase()
    writeLogFile($hTestLog, "[CASE-08] Multiple accounts case")
    writeLogFile($hTestLog, "[PREPARE] Bat active >= 3 account trong file account login")
    resetLoginReport()
    runAutoLoginScript()

    Local $lineCount = getReportLineCount()
    If $lineCount >= 3 Then
        writeLogFile($hTestLog, "[PASS] Report co " & $lineCount & " dong (>=3)")
    Else
        writeLogFile($hTestLog, "[FAIL] Report co " & $lineCount & " dong (<3)")
    EndIf
EndFunc

Func testQuickRunAutoLogin()
    writeLogFile($hTestLog, "[SMOKE] Run auto_login script va thong ke report")
    runAutoLoginScript()
    writeLogFile($hTestLog, "[SMOKE] So dong report hien tai: " & getReportLineCount())
EndFunc

; ---------------------------------------------------------------------------
; HELPER
; ---------------------------------------------------------------------------

Func runAutoLoginScript()
    If Not FileExists($sAutoLoginScript) Then
        writeLogFile($hTestLog, "[FAIL] Khong tim thay script: " & $sAutoLoginScript)
        Return False
    EndIf

    Local $cmd = '"' & @AutoItExe & '" "' & $sAutoLoginScript & '"'
    writeLogFile($hTestLog, "[RUN] " & $cmd)
    Local $exitCode = RunWait($cmd)
    writeLogFile($hTestLog, "[RUN] ExitCode = " & $exitCode)
    Return $exitCode = 0
EndFunc

Func resetLoginReport()
    If FileExists($sLoginReportPath) Then
        FileDelete($sLoginReportPath)
    EndIf
    FileWrite($sLoginReportPath, "")
    writeLogFile($hTestLog, "[INFO] Reset report file: " & $sLoginReportPath)
EndFunc

Func getReportLineCount()
    If Not FileExists($sLoginReportPath) Then Return 0

    Local $aLines
    _FileReadToArray($sLoginReportPath, $aLines)
    If @error Then Return 0

    Local $count = 0
    For $i = 1 To $aLines[0]
        If StringStripWS($aLines[$i], 8) <> "" Then $count += 1
    Next
    Return $count
EndFunc

Func assertReportHasStatus($status, $minCount = 1)
    If Not FileExists($sLoginReportPath) Then
        writeLogFile($hTestLog, "[FAIL] Report file khong ton tai")
        Return False
    EndIf

    Local $aLines
    _FileReadToArray($sLoginReportPath, $aLines)
    If @error Then
        writeLogFile($hTestLog, "[FAIL] Khong doc duoc report")
        Return False
    EndIf

    Local $count = 0
    For $i = 1 To $aLines[0]
        If StringInStr($aLines[$i], "| " & $status & " |") Then $count += 1
    Next

    If $count >= $minCount Then
        writeLogFile($hTestLog, "[PASS] Tim thay status '" & $status & "' = " & $count)
        Return True
    EndIf

    writeLogFile($hTestLog, "[FAIL] Status '" & $status & "' chi co " & $count & " (<" & $minCount & ")")
    Return False
EndFunc
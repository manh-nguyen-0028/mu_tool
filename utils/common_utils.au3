#include-once
#include <date.au3>
#include "../include/json_utils.au3"
#include <Array.au3>
#include <File.au3>

; CONSTANT
Global $baseDir = StringSplit(@ScriptDir,"mu_tool",1)[1] & "mu_tool"
Global $imagePathRoot = $baseDir & "\media\image\"
Global $jsonPathRoot = $baseDir & "\config\json\"
Global $textPathRoot = $baseDir & "\config\text\"
Global $inputPathRoot = $baseDir & "\input\"
Global $outputPathRoot = $baseDir & "\output\"
Global $driverPathRoot = $baseDir & "\driver\"
Global $featurePathRoot = $baseDir & "\feature\"

Local $sScriptDir = @ScriptDir ; Đường dẫn thư mục hiện tại của script
Global $sRootDir = StringRegExpReplace($sScriptDir, "^(.+\\)[^\\]+\\?$", "$1") ; Lấy đường dẫn thư mục gốc

Global $baseMuUrl = "https://hn.gamethuvn.net/"
Global $logFile, $jsonPositionConfig

Global $aCharInAccount

init()

; init
Func init()
	$jsonPositionConfig = getJsonFromFile($jsonPathRoot & "position_config.json")
	$aCharInAccount=getArrayInFileTxt($textPathRoot & "char_in_account.txt")
	Return True
EndFunc

; FUNCTION
; Log
Func writeLog($textLog)
	ConsoleWrite(@HOUR & "-" &@MIN & "-" &@SEC & " : " & $textLog &@CRLF)
EndFunc

Func writeLogFile($logFile, $sText)
	writeLog($sText)
	FileWriteLine($logFile, @HOUR & "-" &@MIN & "-" &@SEC & " : " & $sText)
EndFunc

; Time
Func minuteWait($minuteWait)
	writeLogFile($logFile,"Sleep in: " & $minuteWait & " minute !")
	Sleep($minuteWait*60*1000)
EndFunc

Func secondWait($secondWait)
	;~ writeLogFile($logFile,"Sleep in: " & $secondWait & " second !")
	Sleep($secondWait*1000)
EndFunc

Func createTimeToTicks($gio,$phut,$giay)
	If $gio == 24 Then $gio = 0
	writeLog("Function createTimeToTicks($gio,$phut,$giay) : " & $gio & "-" & $phut & "-" & $giay)
	Return _TimeToTicks($gio, $phut, $giay)
EndFunc

Func diffTime($time1, $time2)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time2-$time1, $sHour, $sMinute, $sSecond)
	Return $sHour*60*60*1000 +  $sMinute*60*1000 + $sSecond*1000;
EndFunc

Func timeLeft($time1, $time2)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time2-$time1, $sHour, $sMinute, $sSecond)
	Return $sHour & ": " & $sMinute & ": " & $sSecond;
EndFunc

Func timeToText($time)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time, $sHour, $sMinute, $sSecond)
	Return $sHour & " h: " & $sMinute & " m: " & $sSecond & " s ";
EndFunc

Func waitToNextHour($hourPlus = 1)
	$nextHour = @HOUR + $hourPlus
	writeLogFile($logFile,"Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, 0 , "05")
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	$diffTime = diffTime($currentTime, $nextTime)
	Sleep($diffTime)
EndFunc

Func waitToNextHourMinutes($hourPlus, $minPlus, $secPlus)
	If @MIN <= $minPlus Then 
		$nextHour = @HOUR
	Else
		$nextHour = @HOUR + $hourPlus
	EndIf
	writeLogFile($logFile, "Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, $minPlus , $secPlus)
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	
	If @HOUR == 23 And @MIN > $minPlus Then 
		$minuteWait = 60 - @MIN + $minPlus
		minuteWait($minuteWait)
	Else
		$diffTime = diffTime($currentTime, $nextTime)
		writeLogFile($logFile,"time diff: " & timeToText($diffTime))
		Sleep($diffTime)
	EndIf
EndFunc

Func waitToNextTime($hourPlus, $minPlus, $secPlus)
	$nextHour = @HOUR + $hourPlus
	writeLogFile($logFile,"Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, $minPlus , $secPlus)
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	$diffTime = diffTime($currentTime, $nextTime)
	writeLogFile($logFile,"time diff: " & timeToText($diffTime))
	Sleep($diffTime)
EndFunc

Func getCurrentTime()
	Return createTimeToTicks(@HOUR, @MIN, @SEC)
EndFunc

Func getCurrentDate()
	Return createTimeToTicks(@HOUR, @MIN, @SEC)
EndFunc

; Return format 2023/09/28 09:20:44
Func getTimeNow()
	Return _NowCalc()
EndFunc

Func addTimePerRs($pTime, $amount)
	$addHour = _DateAdd('h', $amount, $pTime)
	$addMinute = _DateAdd('n', -20, $addHour)
	Return $addMinute
EndFunc

Func addTimeSubtractionMinute($pTime, $amount)
    $addHour = _DateAdd('h', $amount, $pTime)
    $addMinute = _DateAdd('n', -10, $addHour)
    Return $addMinute
EndFunc

Func addHour($pTime, $amount)
	Return _DateAdd('h', $amount, $pTime)
EndFunc

Func addMin($pTime, $amount)
	Return _DateAdd('n', $amount, $pTime)
EndFunc

; mouse
Func _MU_Rs_MouseClick_Delay($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_LEFT) ; Set the left mouse button state as down.
	Sleep(500)
	MouseUp($MOUSE_CLICK_LEFT) ; Set the left mouse button state as up.
	Sleep(500)
EndFunc

Func _MU_MouseClick_Delay($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_LEFT) ; Set the left mouse button state as down.
	Sleep(500)
	MouseUp($MOUSE_CLICK_LEFT) ; Set the left mouse button state as up.
	Sleep(500)
EndFunc

Func _MU_MouseClick($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_LEFT) ; Set the left mouse button state as down.
EndFunc

Func _MU_Mouse_RightClick_Delay($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_RIGHT) ; Set the left mouse button state as down.
	Sleep(500)
	MouseUp($MOUSE_CLICK_RIGHT) ; Set the left mouse button state as up.
	Sleep(500)
EndFunc

Func mouseMainClick($toaDoX, $toaDoY) 
	_MU_MouseClick_Delay($toaDoX, $toaDoY)
	secondWait(1)
EndFunc

; key board
Func sendKeyDelay($keyPress)
	Opt("SendKeyDownDelay", 1000)  ;5 second delay
	Send($keyPress)
	Opt("SendKeyDownDelay", 5)  ;reset to default when done
EndFunc

; active
Func activeMain($mainNo)
	WinActivate($mainNo,"")
	secondWait(1)
EndFunc

Func minisizeMain($mainNo)
	writeLogFile($logFile,"SW_MINIMIZE main: " & $mainNo)
	WinSetState($mainNo,"",@SW_MINIMIZE)
EndFunc

Func activeAndMoveWin($main_i)
	writeLogFile($logFile,"activeAndMoveWin. Main no: " & $main_i )
	$isActive = False;
	If WinActivate($main_i) Then
		$winActive = WinActivate($main_i)
		WinMove($winActive,"",0,0)
		$isActive = True
	Else
		writeLogFile($logFile,"Window not activated : " & $main_i)
	EndIf
	Return $isActive
EndFunc

; text
Func readFileText($filePath)
	writeLogFile($logFile,"Read file : " &$filePath)
	$rtfhandle = FileOpen($filePath)
	$convtext = FileRead($rtfhandle)
	FileClose($rtfhandle)
	Return $convtext
EndFunc

Func getArrayInFileTxt($filePath)
	Local $arrayTmp 
	; Đọc nội dung của file .txt vào mảng
	If FileExists($filePath) Then
		; char auction list
		$arrayTmp = FileReadToArray($filePath)
		If @error Then
			MsgBox(16, "Lỗi", "Đã xảy ra lỗi khi đọc file.")
			Exit
		EndIf
	Else
		writeLogFile($logFile,"File không tồn tại." & $filePath)
		MsgBox(16, "Lỗi", "File không tồn tại.")
		Exit
	EndIf
	Return $arrayTmp
EndFunc

Func convertJsonToString($json)
	Return _JSONEncode($json)
EndFunc

; image search 
Func checkPixelColor($toaDoX, $toaDoY, $color)
	writeLogFile($logFile,"checkPixelColor($toaDoX, $toaDoY, $color) : " & $toaDoX & $toaDoY & $color)
	$resultCompare = False
	MouseMove($toaDoX, $toaDoY)
	secondWait(1)
	$colorGetPosition = PixelGetColor($toaDoX, $toaDoY)
	writeLogFile($logFile,"checkPixelColor -> colorGetPosition : " & $toaDoX & "-" & $toaDoY & "-" & Hex($colorGetPosition,6))
	If $colorGetPosition = $color Then $resultCompare = True
	Return $resultCompare
EndFunc

; json
Func setJsonConfigToFile($path, $json)
	$rtfhandle = FileOpen($path, $FO_OVERWRITE)
	$json_str = convertJsonToString($json)
	writeLogFile($logFile,"setJsonConfigTimeToFile =>> " & $json_str)
	FileWriteLine($rtfhandle, $json_str)
	FileClose($rtfhandle)
EndFunc

Func setJsonToFileFormat($path, $json)
	$rtfhandle = FileOpen($path, $FO_OVERWRITE)
	If UBound($json) <> 0 Then
		FileWriteLine($rtfhandle, "[")
		For $i = 0 To UBound($json) -1
			$json_str = convertJsonToString($json[$i]) & ","
			If $i == UBound($json) -1 Then
				$json_str = convertJsonToString($json[$i])
			Else
				$json_str = convertJsonToString($json[$i]) & ","
			EndIf
			writeLogFile($logFile,"setJsonConfigTimeToFile =>> " & $json_str)
			FileWriteLine($rtfhandle, $json_str)
		Next
		FileWriteLine($rtfhandle, "]")
	EndIf 
	
	FileClose($rtfhandle)
EndFunc

Func getJsonFromFile($filePath)
	writeLogFile($logFile,"Read file getJsonFromFile: " &$filePath)
	$rtfhandle = FileOpen($filePath)
	$convtext = FileRead($rtfhandle)
	writeLogFile($logFile,"Text read from file getJsonFromFile: " &$convtext)
	FileClose($rtfhandle)
	$json = _JSONDecode($convtext)
	Return $json
EndFunc

Func getPropertyJson($json, $propertyName)
	Return _JSONGet($json, $propertyName)
EndFunc

Func setPropertyJson($json, $propertyName, $value)
	Return _JSONSet($json, $propertyName, $value)
EndFunc

Func readFileTxtToArray($filePath)
	$aResult = FileReadToArray($filePath)
	If @error Then
		MsgBox(16, "Lỗi", "Đã xảy ra lỗi khi đọc file : " & $filePath)
		Exit
	Else
		writeLogFile($logFile,"Read file " & $filePath & " success !")
	EndIf
	Return $aResult
EndFunc

Func checkProcessExists($exeFileName)
	$resultCheck = False
	If ProcessExists($exeFileName) Then
		writeLogFile($logFile, "Chương trình " & $exeFileName & " ĐANG chạy.")
		$resultCheck = True
	Else
		writeLogFile($logFile, "Chương trình " & $exeFileName & " KHÔNG chạy.")
		$resultCheck = False
	EndIf
	Return $resultCheck
EndFunc

Func deleteFileInFolder($sFolderPath)
	Local $sDateToday = @YEAR & @MON & @MDAY
	;~ Local $sFolderPath = $outputPathRoot ; Đường dẫn thư mục output

	Local $aFileList = _FileListToArray($sFolderPath) ; Lấy danh sách các file trong thư mục

	If @error Then
		writeLogFile($logFile, "Không thể đọc danh sách file trong thư mục")
	Else
		For $i = 1 To $aFileList[0] ; Duyệt qua từng file
			If StringInStr($aFileList[$i], "File_" & $sDateToday) == 0 Then ; Kiểm tra nếu tên file chứa "File_"
				Local $sFilePath = $sFolderPath & "\" & $aFileList[$i] ; Đường dẫn đầy đủ của file
				FileDelete($sFilePath) ; Xoá file
			EndIf
		Next
		;~ MsgBox(64, "Thông báo", "Xoá các file thành công")
	EndIf

	Return True
EndFunc
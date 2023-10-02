#include-once
#include <date.au3>
#include "../include/json_utils.au3"
#include <Array.au3>

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
Global $logFile

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
	writeLog("Sleep in: " & $minuteWait & " minute !")
	Sleep($minuteWait*60*1000)
EndFunc

Func secondWait($secondWait)
	;~ writeLog("Sleep in: " & $secondWait & " second !")
	Sleep($secondWait*1000)
EndFunc

Func createTimeToTicks($gio,$phut,$giay)
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
	writeLog("Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, 0 , "05")
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	$diffTime = diffTime($currentTime, $nextTime)
	Sleep($diffTime)
EndFunc

Func waitToNextHourMinutes($hourPlus, $minPlus, $secPlus)
	If @MIN < $minPlus Then 
		$nextHour = @HOUR
	Else
		$nextHour = @HOUR + $hourPlus
	EndIf
	writeLog("Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, $minPlus , $secPlus)
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	$diffTime = diffTime($currentTime, $nextTime)
	writeLog("time diff: " & timeToText($diffTime))
	Sleep($diffTime)
EndFunc

Func waitToNextTime($hourPlus, $minPlus, $secPlus)
	$nextHour = @HOUR + $hourPlus
	writeLog("Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, $minPlus , $secPlus)
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	$diffTime = diffTime($currentTime, $nextTime)
	writeLog("time diff: " & timeToText($diffTime))
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
	MouseClick("main",$toaDoX, $toaDoY,1)
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
	writeLog("SW_MINIMIZE main: " & $mainNo)
	WinSetState($mainNo,"",@SW_MINIMIZE)
EndFunc

Func activeAndMoveWin($main_i)
	writeLog("activeAndMoveWin. Main no: " & $main_i )
	$isActive = False;
	If WinActivate($main_i) Then
		$winActive = WinActivate($main_i)
		WinMove($winActive,"",0,0)
		$isActive = True
	Else
		writeLog("Window not activated : " & $main_i)
	EndIf
	Return $isActive
EndFunc

; text
Func readFileText($filePath)
	writeLog("Read file : " &$filePath)
	$rtfhandle = FileOpen($filePath)
	$convtext = FileRead($rtfhandle)
	FileClose($rtfhandle)
	Return $convtext
EndFunc

Func getArrayInFileTxt($filePath)
	$filePath = $baseDir & $filePath
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
		writeLog("File không tồn tại." & $filePath)
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
	writeLog("checkPixelColor($toaDoX, $toaDoY, $color) : " & $toaDoX & $toaDoY & $color)
	$resultCompare = False
	MouseMove($toaDoX, $toaDoY)
	secondWait(1)
	$colorGetPosition = PixelGetColor($toaDoX, $toaDoY)
	writeLog("checkPixelColor -> colorGetPosition : " & $toaDoX & "-" & $toaDoY & "-" & Hex($colorGetPosition,6))
	If $colorGetPosition = $color Then $resultCompare = True
	Return $resultCompare
EndFunc

; json
Func setJsonConfigToFile($path, $json)
	$rtfhandle = FileOpen($path, $FO_OVERWRITE)
	$json_str = convertJsonToString($json)
	writeLog("setJsonConfigTimeToFile =>> " & $json_str)
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
			writeLog("setJsonConfigTimeToFile =>> " & $json_str)
			FileWriteLine($rtfhandle, $json_str)
		Next
		FileWriteLine($rtfhandle, "]")
	EndIf 
	
	FileClose($rtfhandle)
EndFunc

Func getJsonFromFile($filePath)
	writeLog("Read file : " &$filePath)
	$rtfhandle = FileOpen($filePath)
	$convtext = FileRead($rtfhandle)
	;~ writeLog("Text read from file: " &$convtext)
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
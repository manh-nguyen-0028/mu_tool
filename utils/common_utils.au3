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

Global $baseMuUrl = "https://hn.mugamethuvn.info/"
Global $logFile, $jsonPositionConfig, $jsonConfig
Global $devilFileName, $accountRsFileName, $charInAccountFileName

Global $aCharInAccount
Global $currentFile = @ScriptName ; Lấy tên file script hiện tại

init()

; Method: init
; Description: Initializes the script by loading JSON configurations and reading character data from a text file.
Func init()
	$jsonPositionConfig = getJsonFromFile($jsonPathRoot & "position_config.json")

	$jsonConfig = getJsonFromFile($jsonPathRoot & "config.json")

	For $i =0 To UBound($jsonConfig) - 1
		$active = getPropertyJson($jsonConfig[$i], "active")
		$type = getPropertyJson($jsonConfig[$i], "type")
		$key = getPropertyJson($jsonConfig[$i], "key")
		$value = getPropertyJson($jsonConfig[$i], "value")
		If $active == True Then
			If "position" == $type Then
				$jsonPositionConfig = getJsonFromFile($jsonPathRoot & $value)
				ContinueLoop ; Bỏ qua các lệnh còn lại và chuyển sang lần lặp tiếp theo
			ElseIf "devil" == $type Then
				$devilFileName = $value
			ElseIf "reset" == $type Then
				$accountRsFileName = $value
			ElseIf "char_in_account" == $type Then
				$charInAccountFileName = $value
			EndIf
		EndIf
	Next
	
	Return True
EndFunc

; Method: writeLog
; Description: Writes a log message with the current time.
Func writeLog($textLog)
	ConsoleWrite(@HOUR & "-" &@MIN & "-" &@SEC & " : " & $textLog &@CRLF)
EndFunc

; Method: writeLogMethodStart
; Description: Logs the start of a method with optional parameters.
Func writeLogMethodStart($methodName='Khong xac dinh', $line=@ScriptLineNumber, $textLog=Default)
	$sText = "INFO  "& "START " & $methodName & "()"
	If $textLog <> Default Then
		$sText = $sText&" with parameter =>" & $textLog
	EndIf
	writeLogFile($logFile,$sText, $line)
EndFunc

; Method: writeLogMethodEnd
; Description: Logs the end of a method with optional parameters.
Func writeLogMethodEnd($methodName='Khong xac dinh', $line=@ScriptLineNumber, $textLog=Default)
	$sText = "INFO  "& "END " & $methodName & "()"
	If $textLog <> Default Then
		$sText = $sText&" with parameter =>" & $textLog
	EndIf
	writeLogFile($logFile,$sText, $line)
EndFunc

; Method: writeLogFile
; Description: Writes a log message to a specified log file.
Func writeLogFile($logFile, $sText,$line=Default)
	logFileCommon($logFile, $sText,$line)
EndFunc

; Method: logFileCommon
; Description: Common function to format and write log messages to a file.
Func logFileCommon($logFile, $sText,$line=Default)
	$sTextFinal = ''
	If $line == Default Then
		$sTextFinal = @HOUR & "-" &@MIN & "-" &@SEC & " " &  @ScriptName &" : " & $sText
	Else
		$sTextFinal = @HOUR & "-" &@MIN & "-" &@SEC & " " &  @ScriptName & "["&$line&"]" &" : " & $sText
	EndIf
	writeLog($sTextFinal)
	FileWriteLine($logFile, $sTextFinal)
	Return True
EndFunc

; Method: minuteWait
; Description: Pauses execution for a specified number of minutes.
Func minuteWait($minuteWait)
	writeLogFile($logFile,"Sleep in: " & $minuteWait & " minute !")
	Sleep($minuteWait*60*1000)
EndFunc

; Method: secondWait
; Description: Pauses execution for a specified number of seconds.
Func secondWait($secondWait)
	;~ writeLogFile($logFile,"Sleep in: " & $secondWait & " second !")
	Sleep($secondWait*1000)
EndFunc

; Method: createTimeToTicks
; Description: Converts hours, minutes, and seconds to ticks.
Func createTimeToTicks($gio,$phut,$giay)
	If $gio == 24 Then $gio = 0
	writeLog("Function createTimeToTicks($gio,$phut,$giay) : " & $gio & "-" & $phut & "-" & $giay)
	Return _TimeToTicks($gio, $phut, $giay)
EndFunc

; Method: diffTime
; Description: Calculates the difference in ticks between two times.
Func diffTime($time1, $time2)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time2-$time1, $sHour, $sMinute, $sSecond)
	Return $sHour*60*60*1000 +  $sMinute*60*1000 + $sSecond*1000;
EndFunc

; Method: timeLeft
; Description: Returns the time left between two times in hours, minutes, and seconds.
Func timeLeft($time1, $time2)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time2-$time1, $sHour, $sMinute, $sSecond)
	Return $sHour & ": " & $sMinute & ": " & $sSecond;
EndFunc

; Method: timeToText
; Description: Converts time in ticks to a formatted string.
Func timeToText($time)
	Local $sHour, $sMinute, $sSecond
	_TicksToTime($time, $sHour, $sMinute, $sSecond)
	Return $sHour & " h: " & $sMinute & " m: " & $sSecond & " s ";
EndFunc

; Method: waitToNextHour
; Description: Pauses execution until the next specified hour.
Func waitToNextHour($hourPlus = 1)
	$nextHour = @HOUR + $hourPlus
	writeLogFile($logFile,"Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, 0 , "05")
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	$diffTime = diffTime($currentTime, $nextTime)
	Sleep($diffTime)
EndFunc

; Method: waitToNextHourMinutes
; Description: Pauses execution until the next specified hour and minute.
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

; Method: waitToNextTime
; Description: Pauses execution until the next specified time.
Func waitToNextTime($hourPlus, $minPlus, $secPlus)
	$nextHour = @HOUR + $hourPlus
	writeLogFile($logFile,"Wait to next hour : " &$nextHour)
	$nextTime = createTimeToTicks($nextHour, $minPlus , $secPlus)
	$currentTime = createTimeToTicks(@HOUR, @MIN, @SEC)
	$diffTime = diffTime($currentTime, $nextTime)
	writeLogFile($logFile,"time diff: " & timeToText($diffTime))
	Sleep($diffTime)
EndFunc

; Method: getCurrentTime
; Description: Returns the current time in ticks.
Func getCurrentTime()
	Return createTimeToTicks(@HOUR, @MIN, @SEC)
EndFunc

; Method: getCurrentDate
; Description: Returns the current date in ticks.
Func getCurrentDate()
	Return createTimeToTicks(@HOUR, @MIN, @SEC)
EndFunc

; Method: getTimeNow
; Description: Returns the current date and time in the format YYYY/MM/DD HH:MM:SS.
Func getTimeNow()
	Return _NowCalc()
EndFunc

; Method: addTimePerRs
; Description: Adds a specified number of hours and subtracts 20 minutes from a given time.
Func addTimePerRs($pTime, $amount)
	$addHour = _DateAdd('h', $amount, $pTime)
	$addMinute = _DateAdd('n', -20, $addHour)
	Return $addMinute
EndFunc

; Method: addTimeSubtractionMinute
; Description: Adds a specified number of hours and subtracts 10 minutes from a given time.
Func addTimeSubtractionMinute($pTime, $amount)
    $addHour = _DateAdd('h', $amount, $pTime)
    $addMinute = _DateAdd('n', -10, $addHour)
    Return $addMinute
EndFunc

; Method: addHour
; Description: Adds a specified number of hours to a given time.
Func addHour($pTime, $amount)
	Return _DateAdd('h', $amount, $pTime)
EndFunc

; Method: addMin
; Description: Adds a specified number of minutes to a given time.
Func addMin($pTime, $amount)
	Return _DateAdd('n', $amount, $pTime)
EndFunc

; Method: _MU_Rs_MouseClick_Delay
; Description: Moves the mouse to specified coordinates, clicks with a delay, and releases the click.
Func _MU_Rs_MouseClick_Delay($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_LEFT) ; Set the left mouse button state as down.
	Sleep(500)
	MouseUp($MOUSE_CLICK_LEFT) ; Set the left mouse button state as up.
	Sleep(500)
EndFunc

; Method: _MU_MouseClick_Delay
; Description: Moves the mouse to specified coordinates, clicks with a delay, and releases the click.
Func _MU_MouseClick_Delay($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_LEFT) ; Set the left mouse button state as down.
	Sleep(500)
	MouseUp($MOUSE_CLICK_LEFT) ; Set the left mouse button state as up.
	Sleep(500)
EndFunc

Func mouseClickDelayAlt($toadoX, $toadoY)
	Send("{ALTDOWN}")
	_MU_MouseClick_Delay($toadoX, $toadoY)
	Sleep(500)
	Send("{ALTUP}")
EndFunc

; Method: _MU_MouseClick
; Description: Moves the mouse to specified coordinates and clicks.
Func _MU_MouseClick($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_LEFT) ; Set the left mouse button state as down.
EndFunc

; Method: _MU_Mouse_RightClick_Delay
; Description: Moves the mouse to specified coordinates, right-clicks with a delay, and releases the click.
Func _MU_Mouse_RightClick_Delay($toadoX, $toadoY)
	MouseMove($toadoX, $toadoY)
	secondWait(1)
	MouseDown($MOUSE_CLICK_RIGHT) ; Set the left mouse button state as down.
	Sleep(500)
	MouseUp($MOUSE_CLICK_RIGHT) ; Set the left mouse button state as up.
	Sleep(500)
EndFunc

; Method: mouseMainClick
; Description: Moves the mouse to specified coordinates, clicks with a delay, and waits for a second.
Func mouseMainClick($toaDoX, $toaDoY) 
	_MU_MouseClick_Delay($toaDoX, $toaDoY)
	secondWait(1)
EndFunc

; Method: sendKeyDelay
; Description: Sends a key press with a delay.
Func sendKeyDelay($keyPress)
	Opt("SendKeyDownDelay", 1000)  ;5 second delay
	Send($keyPress)
	Opt("SendKeyDownDelay", 5)  ;reset to default when done
EndFunc

; Method: activeMain
; Description: Activates a specified window.
Func activeMain($mainNo)
	WinActivate($mainNo,"")
	secondWait(1)
EndFunc

; Method: minisizeMain
; Description: Minimizes a specified window.
Func minisizeMain($mainNo)
	writeLogFile($logFile,"SW_MINIMIZE main: " & $mainNo)
	WinSetState($mainNo,"",@SW_MINIMIZE)
EndFunc

; Method: activeAndMoveWin
; Description: Activates and moves a specified window to the top-left corner of the screen.
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

; Method: readFileText
; Description: Reads the contents of a text file and returns it as a string.
Func readFileText($filePath)
	writeLogFile($logFile,"Read file : " &$filePath)
	$rtfhandle = FileOpen($filePath)
	$convtext = FileRead($rtfhandle)
	FileClose($rtfhandle)
	Return $convtext
EndFunc

; Method: getArrayInFileTxt
; Description: Reads a text file and returns its contents as an array.
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

; Method: convertJsonToString
; Description: Converts a JSON object to a string representation.
Func convertJsonToString($json)
	$result = _JSONEncode($json)
	writeLogFile($logFile,"convertJsonToString: " & $result)
	Return $result
EndFunc

; Method: checkPixelColor
; Description: Checks if the color of a pixel at specified coordinates matches a given color.
Func checkPixelColor($toaDoX, $toaDoY, $color)
	writeLogFile($logFile,"checkPixelColor($toaDoX, $toaDoY, $color) : " & $toaDoX & $toaDoY & "-" & $color)
	$resultCompare = False
	;~ MouseMove($toaDoX, $toaDoY)
	secondWait(1)
	$colorGetPosition = PixelGetColor($toaDoX, $toaDoY)
	writeLogFile($logFile,"checkPixelColor -> colorGetPosition : " & $toaDoX & "-" & $toaDoY & "-" & $colorGetPosition)
	If Hex($colorGetPosition, 6) == Hex($color, 6) Then $resultCompare = True
	Return $resultCompare
EndFunc

; Method: setJsonConfigToFile
; Description: Writes a JSON object to a file in string format.
Func setJsonConfigToFile($path, $json)
	$rtfhandle = FileOpen($path, $FO_OVERWRITE)
	$json_str = convertJsonToString($json)
	writeLogFile($logFile,"setJsonConfigTimeToFile =>> " & $json_str)
	FileWriteLine($rtfhandle, $json_str)
	FileClose($rtfhandle)
EndFunc

; Method: setJsonToFileFormat
; Description: Writes a JSON array to a file in a formatted string.
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

; Method: getJsonFromFile
; Description: Reads a JSON object from a file.
Func getJsonFromFile($filePath)
	writeLogFile($logFile,"Read file getJsonFromFile: " &$filePath)
	$rtfhandle = FileOpen($filePath)
	$convtext = FileRead($rtfhandle)
	;~ writeLogFile($logFile,"Text read from file getJsonFromFile: " &$convtext)
	FileClose($rtfhandle)
	$json = _JSONDecode($convtext)
	Return $json
EndFunc

; Method: getPropertyJson
; Description: Retrieves a property value from a JSON object.
Func getPropertyJson($json, $propertyName)
	$value = _JSONGet($json, $propertyName)
	writeLogFile($logFile,"$propertyName: " & $propertyName & " - value: " & $value)
	Return $value
EndFunc

; Method: setPropertyJson
; Description: Sets a property value in a JSON object.
Func setPropertyJson($json, $propertyName, $value)
	Return _JSONSet($json, $propertyName, $value)
EndFunc

; Method: readFileTxtToArray
; Description: Reads a text file and returns its contents as an array.
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

; Method: checkProcessExists
; Description: Checks if a process with a specified name is running.
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

; Method: deleteFileInFolder
; Description: Deletes files in a specified folder except those containing today's date.
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

; Method: getOtherChar
; Description: Finds and returns the name of another character in the account.
Func getOtherChar($currentChar)
	writeLogFile($logFile, "getOtherChar($currentChar) : " & $currentChar)

	; load char in account
	$aCharInAccount = getArrayInFileTxt($textPathRoot & $charInAccountFileName)

	$otherCharName = ""

	For $i = 0 To UBound($aCharInAccount) -1
		$resultCheck = StringInStr($aCharInAccount[$i], $currentChar & "|")
		If $resultCheck Then
			; Chuyen sang char con lai
			$otherCharName = StringSplit($aCharInAccount[$i],"|")[2]
			writeLogFile($logFile, "Da tim thay other char: " & $otherCharName)
			ExitLoop
		EndIf
	Next

	If $otherCharName == "" Then writeLogFile($logFile, "Khong tim thay char nao phu hop")

	Return $otherCharName
EndFunc
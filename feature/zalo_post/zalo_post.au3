#include-once
#include <Array.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"

; Khung giờ đăng: từ 7h đến hết 23h59 (cấm 0h -> 7h)
Global Const $ZALO_START_HOUR = 7
Global Const $ZALO_NORMAL_INTERVAL_MIN = 60
Global Const $ZALO_PEAK_INTERVAL_MIN = 30
Global Const $ZALO_CHECK_INTERVAL_SEC = 60
Global $g_sLastLoggedNextPost = ""

runZaloPostScheduler()

; Method: isInZaloPostWindow
; Description: Chỉ cho phép đăng từ 7h trở đi, cấm 0h -> 7h
Func isInZaloPostWindow()
	Return @HOUR >= $ZALO_START_HOUR
EndFunc   ;==>isInZaloPostWindow

; Method: isZaloPeakHour
; Description: Giờ cao điểm: 8h -> 11h và 20h -> 22h
Func isZaloPeakHour()
	Return (@HOUR >= 8 And @HOUR < 11) Or (@HOUR >= 20 And @HOUR < 22)
EndFunc   ;==>isZaloPeakHour

; Method: getZaloIntervalMin
; Description: Chu kỳ đăng theo giờ hiện tại (30p giờ cao điểm, 60p giờ thường)
Func getZaloIntervalMin()
	If isZaloPeakHour() Then Return $ZALO_PEAK_INTERVAL_MIN
	Return $ZALO_NORMAL_INTERVAL_MIN
EndFunc   ;==>getZaloIntervalMin

; Method: isZaloGroupDue
; Description: Đến lượt đăng khi chưa có last_time_post hoặc đã qua đủ chu kỳ
Func isZaloGroupDue($jGroupInfo)
	Local $sLastTime = getPropertyJson($jGroupInfo, "last_time_post")
	If $sLastTime = "" Then Return True

	Local $iElapsedMin = _DateDiff('n', $sLastTime, _NowCalc())
	If @error Then Return True

	Return $iElapsedMin >= getZaloIntervalMin()
EndFunc   ;==>isZaloGroupDue

; Method: getNextZaloPostTime
; Description: Thời gian gần nhất group có thể post: last_time_post + chu kỳ (không sớm hơn hiện tại), nếu rơi vào 0h -> 7h thì dời sang 7h
Func getNextZaloPostTime($jGroupInfo)
	Local $sNow = _NowCalc()
	Local $sNext = $sNow
	Local $sLastTime = getPropertyJson($jGroupInfo, "last_time_post")
	If $sLastTime <> "" Then
		Local $sCandidate = _DateAdd('n', getZaloIntervalMin(), $sLastTime)
		If Not @error And _DateDiff('n', $sNow, $sCandidate) > 0 Then $sNext = $sCandidate
	EndIf

	Local $aDate, $aTime
	_DateTimeSplit($sNext, $aDate, $aTime)
	If $aTime[1] < $ZALO_START_HOUR Then
		$sNext = StringFormat("%04d/%02d/%02d %02d:00:00", $aDate[1], $aDate[2], $aDate[3], $ZALO_START_HOUR)
	EndIf
	Return $sNext
EndFunc   ;==>getNextZaloPostTime

; Method: getEarliestNextZaloPostTime
; Description: Thời gian gần nhất có thể post trong các group active, trả về "" nếu không có group active
Func getEarliestNextZaloPostTime()
	Local $sEarliest = ""
	Local $jGroups = getJsonFromFile($jsonPathRoot & $zaloPostConfigFileName)
	For $i = 0 To UBound($jGroups) - 1
		If Not getPropertyJson($jGroups[$i], "active") Then ContinueLoop
		Local $sNext = getNextZaloPostTime($jGroups[$i])
		If $sEarliest = "" Or _DateDiff('s', $sEarliest, $sNext) < 0 Then $sEarliest = $sNext
	Next
	Return $sEarliest
EndFunc   ;==>getEarliestNextZaloPostTime

; Method: getDueZaloGroups
; Description: Lấy danh sách group active và đã đến lượt đăng
Func getDueZaloGroups()
	Local $aGroupDue[0]
	Local $jGroups = getJsonFromFile($jsonPathRoot & $zaloPostConfigFileName)
	For $i = 0 To UBound($jGroups) - 1
		If getPropertyJson($jGroups[$i], "active") And isZaloGroupDue($jGroups[$i]) Then
			$aGroupDue = redimArray($aGroupDue, $jGroups[$i])
		EndIf
	Next
	Return $aGroupDue
EndFunc   ;==>getDueZaloGroups

; Method: updateLastTimePost
; Description: Ghi last_time_post của group vào file config
Func updateLastTimePost($groupId)
	Local $sFile = $jsonPathRoot & $zaloPostConfigFileName
	Local $jGroups = getJsonFromFile($sFile)
	Local $now = _NowCalc()
	For $i = 0 To UBound($jGroups) - 1
		If getPropertyJson($jGroups[$i], "group_id") = $groupId Then
			_JSONSet($now, $jGroups[$i], "last_time_post")
			writeLogFile($logFile, "Cap nhat last_time_post cho " & $groupId & " = " & $now)
			writeLogFile($logFile, "Thoi gian gan nhat co the post tiep theo cho " & $groupId & ": " & getNextZaloPostTime($jGroups[$i]))
			ExitLoop
		EndIf
	Next
	setJsonToFileFormat($sFile, $jGroups)
EndFunc   ;==>updateLastTimePost

; Method: logNextZaloPostTime
; Description: Log thời gian gần nhất có thể post, chỉ log khi giá trị thay đổi
Func logNextZaloPostTime()
	Local $sNext = getEarliestNextZaloPostTime()
	If $sNext = $g_sLastLoggedNextPost Then Return
	$g_sLastLoggedNextPost = $sNext
	If $sNext = "" Then
		writeLog("Zalo post: khong co group active")
	Else
		writeLog("Zalo post: thoi gian gan nhat co the post: " & $sNext)
	EndIf
EndFunc   ;==>logNextZaloPostTime

; Method: runZaloPostScheduler
; Description: Vòng lặp vô hạn: trong khung giờ cho phép, đăng các group đã đến lượt theo last_time_post
Func runZaloPostScheduler()
	While True
		Local $aGroupDue = getDueZaloGroups()
		If isInZaloPostWindow() And UBound($aGroupDue) > 0 Then
			startZaloPost($aGroupDue)
		Else
			logNextZaloPostTime()
		EndIf
		Sleep($ZALO_CHECK_INTERVAL_SEC * 1000)
	WEnd
EndFunc   ;==>runZaloPostScheduler

; Method: startZaloPost
; Description: Mở Zalo web, đăng bài cho các group đến lượt rồi cập nhật last_time_post
Func startZaloPost($aGroupActive)
	Local $sFilePath = $outputPathRoot & "File_Log_ZaloPost_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	writeLogMethodStart("startZaloPost", @ScriptLineNumber)

	$sSession = startChromeSession()
	navigateUrl($sSession, $zaloWebUrl)

	If checkZaloLoggedIn($sSession) Then
		For $i = 0 To UBound($aGroupActive) - 1
			If Not isInZaloPostWindow() Then
				writeLogFile($logFile, "Ngoai khung gio dang bai (0h-7h) => Dung dang bai !")
				ExitLoop
			EndIf
			If processZaloGroup($sSession, $aGroupActive[$i]) Then
				updateLastTimePost(getPropertyJson($aGroupActive[$i], "group_id"))
			EndIf
		Next
	Else
		writeLogFile($logFile, "Chua dang nhap Zalo => Ket thuc chuong trinh !")
	EndIf

	writeLogMethodEnd("startZaloPost", @ScriptLineNumber)
	FileClose($logFile)
	closeChromeSession($sSession)
	Return True
EndFunc   ;==>startZaloPost

; Method: processZaloGroup
; Description: Tìm group → click → kiểm tra tiêu đề → click ô nhập tin nhắn
Func processZaloGroup($sSession, $jGroupInfo)
	Local $groupName = getPropertyJson($jGroupInfo, "group_name")
	Local $groupId = getPropertyJson($jGroupInfo, "group_id")
	writeLogMethodStart("processZaloGroup", @ScriptLineNumber, $groupName)

	If Not searchZaloGroup($sSession, $groupName) Then Return False
	If Not clickZaloGroupItem($sSession, $groupId, $groupName) Then Return False

	If Not checkZaloGroupHeader($sSession, $groupName) Then
		writeLogFile($logFile, "Sai group, tieu de khong khop: " & $groupName)
		Return False
	EndIf

	If Not clickZaloMessageInput($sSession) Then Return False

	Local $imagePath = getPropertyJson($jGroupInfo, "image_path")
	If $imagePath <> "" Then uploadZaloImages($sSession, $imagePath)

	Local $textPath = getPropertyJson($jGroupInfo, "text_path")
	If $textPath <> "" Then
		Local $sText = readFileTextUtf8($textPath)
		If @error Or $sText = "" Then
			writeLogFile($logFile, "Khong doc duoc noi dung file text: " & $textPath)
		Else
			sendZaloText($sSession, StringRegExpReplace($sText, "\s+$", ""))
		EndIf
	EndIf

	writeLogMethodEnd("processZaloGroup", @ScriptLineNumber, $groupName)
	Return True
EndFunc   ;==>processZaloGroup

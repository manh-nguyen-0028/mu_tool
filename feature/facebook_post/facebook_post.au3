#include-once
#include <Array.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"

; Khung giờ đăng mặc định (6h -> 17h), ghi đè bằng start_hour/end_hour trong config
Global Const $FB_DEFAULT_START_HOUR = 6
Global Const $FB_DEFAULT_END_HOUR = 17
Global Const $FB_DEFAULT_INTERVAL_MIN = 60
Global Const $FB_CHECK_INTERVAL_SEC = 60
Global $g_sLastLoggedNextFbPost = ""

runFacebookPostScheduler()

; Method: getFacebookStartHour
; Description: Giờ bắt đầu được đăng (start_hour), mặc định 6
Func getFacebookStartHour($jInfo)
	Local $sHour = getPropertyJson($jInfo, "start_hour")
	If $sHour = "" Then Return $FB_DEFAULT_START_HOUR
	Return Number($sHour)
EndFunc   ;==>getFacebookStartHour

; Method: getFacebookEndHour
; Description: Giờ kết thúc (end_hour, không bao gồm), mặc định 17
Func getFacebookEndHour($jInfo)
	Local $sHour = getPropertyJson($jInfo, "end_hour")
	If $sHour = "" Then Return $FB_DEFAULT_END_HOUR
	Return Number($sHour)
EndFunc   ;==>getFacebookEndHour

; Method: isInFacebookPostWindow
; Description: Chỉ cho phép đăng trong khung start_hour <= giờ hiện tại < end_hour của target
Func isInFacebookPostWindow($jInfo)
	Return @HOUR >= getFacebookStartHour($jInfo) And @HOUR < getFacebookEndHour($jInfo)
EndFunc   ;==>isInFacebookPostWindow

; Method: getFacebookIntervalMin
; Description: Chu kỳ đăng của target (interval_min), mặc định 60 phút
Func getFacebookIntervalMin($jInfo)
	Local $iInterval = Number(getPropertyJson($jInfo, "interval_min"))
	If $iInterval <= 0 Then Return $FB_DEFAULT_INTERVAL_MIN
	Return $iInterval
EndFunc   ;==>getFacebookIntervalMin

; Method: isFacebookTargetDue
; Description: Đến lượt đăng khi chưa có last_time_post hoặc đã qua đủ chu kỳ
Func isFacebookTargetDue($jInfo)
	Local $sLastTime = getPropertyJson($jInfo, "last_time_post")
	If $sLastTime = "" Then Return True

	Local $iElapsedMin = _DateDiff('n', $sLastTime, _NowCalc())
	If @error Then Return True

	Return $iElapsedMin >= getFacebookIntervalMin($jInfo)
EndFunc   ;==>isFacebookTargetDue

; Method: getNextFacebookPostTime
; Description: Thời gian gần nhất target có thể post: last_time_post + chu kỳ (không sớm hơn hiện tại), nếu ngoài khung giờ thì dời sang start_hour (hôm nay hoặc ngày mai)
Func getNextFacebookPostTime($jInfo)
	Local $sNow = _NowCalc()
	Local $sNext = $sNow
	Local $sLastTime = getPropertyJson($jInfo, "last_time_post")
	If $sLastTime <> "" Then
		Local $sCandidate = _DateAdd('n', getFacebookIntervalMin($jInfo), $sLastTime)
		If Not @error And _DateDiff('n', $sNow, $sCandidate) > 0 Then $sNext = $sCandidate
	EndIf

	Local $aDate, $aTime
	_DateTimeSplit($sNext, $aDate, $aTime)
	Local $iStart = getFacebookStartHour($jInfo)
	If $aTime[1] >= getFacebookEndHour($jInfo) Then
		$sNext = _DateAdd('d', 1, StringFormat("%04d/%02d/%02d", $aDate[1], $aDate[2], $aDate[3]))
		_DateTimeSplit($sNext, $aDate, $aTime)
		$sNext = StringFormat("%04d/%02d/%02d %02d:00:00", $aDate[1], $aDate[2], $aDate[3], $iStart)
	ElseIf $aTime[1] < $iStart Then
		$sNext = StringFormat("%04d/%02d/%02d %02d:00:00", $aDate[1], $aDate[2], $aDate[3], $iStart)
	EndIf
	Return $sNext
EndFunc   ;==>getNextFacebookPostTime

; Method: getEarliestNextFacebookPostTime
; Description: Thời gian gần nhất có thể post trong các target active, trả về "" nếu không có target active
Func getEarliestNextFacebookPostTime()
	Local $sEarliest = ""
	Local $jTargets = getJsonFromFile($jsonPathRoot & $facebookPostConfigFileName)
	For $i = 0 To UBound($jTargets) - 1
		If Not getPropertyJson($jTargets[$i], "active") Then ContinueLoop
		Local $sNext = getNextFacebookPostTime($jTargets[$i])
		If $sEarliest = "" Or _DateDiff('s', $sEarliest, $sNext) < 0 Then $sEarliest = $sNext
	Next
	Return $sEarliest
EndFunc   ;==>getEarliestNextFacebookPostTime

; Method: getDueFacebookTargets
; Description: Lấy danh sách target active, đang trong khung giờ đăng và đã đến lượt
Func getDueFacebookTargets()
	Local $aDue[0]
	Local $jTargets = getJsonFromFile($jsonPathRoot & $facebookPostConfigFileName)
	For $i = 0 To UBound($jTargets) - 1
		If getPropertyJson($jTargets[$i], "active") And isInFacebookPostWindow($jTargets[$i]) And isFacebookTargetDue($jTargets[$i]) Then
			$aDue = redimArray($aDue, $jTargets[$i])
		EndIf
	Next
	Return $aDue
EndFunc   ;==>getDueFacebookTargets

; Method: updateFacebookLastTimePost
; Description: Ghi last_time_post của target (theo group_url) vào file config
Func updateFacebookLastTimePost($sGroupUrl)
	Local $sFile = $jsonPathRoot & $facebookPostConfigFileName
	Local $jTargets = getJsonFromFile($sFile)
	Local $now = _NowCalc()
	For $i = 0 To UBound($jTargets) - 1
		If getPropertyJson($jTargets[$i], "group_url") = $sGroupUrl Then
			_JSONSet($now, $jTargets[$i], "last_time_post")
			writeLogFile($logFile, "Cap nhat last_time_post cho " & $sGroupUrl & " = " & $now)
			writeLogFile($logFile, "Thoi gian gan nhat co the post tiep theo cho " & $sGroupUrl & ": " & getNextFacebookPostTime($jTargets[$i]))
			ExitLoop
		EndIf
	Next
	setJsonToFileFormat($sFile, $jTargets)
EndFunc   ;==>updateFacebookLastTimePost

; Method: logNextFacebookPostTime
; Description: Log thời gian gần nhất có thể post, chỉ log khi giá trị thay đổi
Func logNextFacebookPostTime()
	Local $sNext = getEarliestNextFacebookPostTime()
	If $sNext = $g_sLastLoggedNextFbPost Then Return
	$g_sLastLoggedNextFbPost = $sNext
	If $sNext = "" Then
		writeLog("Facebook post: khong co target active")
	Else
		writeLog("Facebook post: thoi gian gan nhat co the post: " & $sNext)
	EndIf
EndFunc   ;==>logNextFacebookPostTime

; Method: runFacebookPostScheduler
; Description: Vòng lặp vô hạn: đăng các target đang trong khung giờ cho phép và đã đến lượt theo last_time_post
Func runFacebookPostScheduler()
	While True
		Local $aDue = getDueFacebookTargets()
		If UBound($aDue) > 0 Then
			startFacebookPost($aDue)
		Else
			logNextFacebookPostTime()
		EndIf
		Sleep($FB_CHECK_INTERVAL_SEC * 1000)
	WEnd
EndFunc   ;==>runFacebookPostScheduler

; Method: startFacebookPost
; Description: Mở Chrome (profile đã đăng nhập Facebook), đăng bài cho các target đến lượt rồi cập nhật last_time_post
Func startFacebookPost($aTargets)
	Local $sFilePath = $outputPathRoot & "File_Log_FacebookPost_.txt"
	$logFile = FileOpen($sFilePath, $iLogOverwrite)
	writeLogMethodStart("startFacebookPost", @ScriptLineNumber)

	$sSession = startChromeSession()
	For $i = 0 To UBound($aTargets) - 1
		If Not isInFacebookPostWindow($aTargets[$i]) Then
			writeLogFile($logFile, "Ngoai khung gio dang bai => Bo qua: " & getPropertyJson($aTargets[$i], "group_name"))
			ContinueLoop
		EndIf
		If processFacebookTarget($sSession, $aTargets[$i]) Then
			updateFacebookLastTimePost(getPropertyJson($aTargets[$i], "group_url"))
		EndIf
	Next

	writeLogMethodEnd("startFacebookPost", @ScriptLineNumber)
	FileClose($logFile)
	closeChromeSession($sSession)
	Return True
EndFunc   ;==>startFacebookPost

; Method: processFacebookTarget
; Description: Vào trang group → click vùng đăng bài → nhập text → up ảnh → bấm Đăng
Func processFacebookTarget($sSession, $jInfo)
	Local $groupName = getPropertyJson($jInfo, "group_name")
	Local $groupUrl = getPropertyJson($jInfo, "group_url")
	writeLogMethodStart("processFacebookTarget", @ScriptLineNumber, $groupName)

	If $groupUrl = "" Then
		writeLogFile($logFile, "Thieu group_url cho: " & $groupName)
		Return False
	EndIf
	If Not navigateUrl($sSession, $groupUrl) Then Return False
	If Not clickFacebookComposer($sSession) Then Return False

	Local $textPath = getPropertyJson($jInfo, "text_path")
	If $textPath <> "" Then
		Local $sText = readFileTextUtf8($textPath)
		If @error Or $sText = "" Then
			writeLogFile($logFile, "Khong doc duoc noi dung file text: " & $textPath)
			Return False
		EndIf
		If Not sendFacebookText($sSession, StringRegExpReplace($sText, "\s+$", "")) Then Return False
	EndIf

	Local $imagePath = getPropertyJson($jInfo, "image_path")
	If $imagePath <> "" Then uploadFacebookImages($sSession, $imagePath)

	Local $isPosted = submitFacebookPost($sSession)
	writeLogMethodEnd("processFacebookTarget", @ScriptLineNumber, $groupName)
	Return $isPosted
EndFunc   ;==>processFacebookTarget

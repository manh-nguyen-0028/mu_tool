#include-once
#include <date.au3>
#include <MsgBoxConstants.au3>
#include "../include/_ImageSearch_UDF.au3"
#include <AutoItConstants.au3>
#include "../include/json_utils.au3"
#include <Array.au3>
#include "common_utils.au3"

Local $aArray[20]

; Enum
Global $SERVICE_CONFIG_TYPE_SEEDING_ZALO = "seeding_zalo"
Global $SERVICE_CONFIG_TYPE_POST_FACEBOOK = "post_facebook"
Global $SERVICE_CONFIG_TYPE_SEEDING_DIEN_DAN = "seeding_dien_dan"
Global $SERVICE_CONFIG_TYPE_POST_DIEN_DAN = "post_dien_dan"
Global $SERVICE_CONFIG_TYPE_WITHDRAW_RS = "withdraw_rs"
Global $SERVICE_CONFIG_TYPE_RESET = "reset"


; Type config constant
Global $baseDir = StringSplit(@ScriptDir,"gtvn_auto_dv",1)[1] & "gtvn_auto_dv"
; Json path 
Global $JSON_CONFIG_TIME_EVENT_PATH = $baseDir & "\json\config_time.json"
Global $serviceConfigPath =	$baseDir & "\config\service_config.json"
Global $JSON_ACCOUNT_RS_REPORT_PATH = $baseDir & "\json\account_rs_report.json"
Global $JSON_CONFIG_PATH = $baseDir & "\json\config.json"
Global $JSON_ACCOUNT_CONFIG_PATH = $baseDir & "\json\account_config.json"
Global $JSON_SEEDING_CONFIG_PATH = $baseDir & "\json\seeding_post_config.json"
Global $jsonConfigCommon = getJsonFromFile($JSON_CONFIG_PATH)
Global $jsonSeedingConfig = getJsonFromFile($JSON_SEEDING_CONFIG_PATH)

Global $file_path_chrome_portable='D:\Setup\GoogleChromePortable\GoogleChromePortable.exe'

Global $accountNeedRs[0];
Global $accountNeedGoDevil[0];
Global $accountNeedRsAfterGoDevil[0];
Global $accountWithdrawRs[0];

Global $facebookPost[0]
Global $maxHourRs

loadInitAccount()
getConfigSeeding()

Func loadInitAccount()
	writeLog("$sRootDir: " & $sRootDir)
	writeLog("$baseDir: " & $baseDir)
	$json_config_account = getJsonFromFile($JSON_ACCOUNT_CONFIG_PATH)
	$maxHourRs = _JSONGet($json_config_account, "max_hour_rs")
	$allAccount = _JSONGet($json_config_account, "account_all")
	; Load account reset
	$countAccoutRs = 0 
	$countAccoutDevil = 0
	$countAccoutRsAfterDevil = 0
	$countWithdrawRs = 0

	For $i = 0 To UBound($allAccount) -1
		If _JSONGet($allAccount[$i], "isRs") = True Then 
			$countAccoutRs += 1
			ReDim $accountNeedRs[UBound($accountNeedRs) + 1]
			$accountNeedRs[$countAccoutRs - 1] = _JSONGet($allAccount[$i], "account") & "|" & _JSONGet($allAccount[$i], "password") & "|" & _JSONGet($allAccount[$i], "charName") & "|" & _JSONGet($allAccount[$i], "mainNo") & "|" & _JSONGet($allAccount[$i], "rsType") & "|" & _JSONGet($allAccount[$i], "rsType")
		EndIf
		If _JSONGet($allAccount[$i], "isGoDevil") = True Then 
			$countAccoutDevil += 1
			ReDim $accountNeedGoDevil[UBound($accountNeedGoDevil) + 1]
			$accountNeedGoDevil[$countAccoutDevil - 1] = _JSONGet($allAccount[$i], "account") & "|" & _JSONGet($allAccount[$i], "password") & "|" & _JSONGet($allAccount[$i], "charName") & "|" & _JSONGet($allAccount[$i], "mainNo") & "|" & _JSONGet($allAccount[$i], "rsType") & "|" & _JSONGet($allAccount[$i], "rsType")
		EndIf
		If _JSONGet($allAccount[$i], "isRsAfterDevil") = True Then 
			$countAccoutRsAfterDevil += 1
			ReDim $accountNeedRsAfterGoDevil[UBound($accountNeedRsAfterGoDevil) + 1]
			$accountNeedRsAfterGoDevil[$countAccoutRsAfterDevil - 1] = _JSONGet($allAccount[$i], "account") & "|" & _JSONGet($allAccount[$i], "password") & "|" & _JSONGet($allAccount[$i], "charName") & "|" & _JSONGet($allAccount[$i], "mainNo") & "|" & _JSONGet($allAccount[$i], "rsType") & "|" & _JSONGet($allAccount[$i], "rsType")
		EndIf
		If _JSONGet($allAccount[$i], "isWithdrawRs") = True Then 
			$countWithdrawRs += 1
			ReDim $accountWithdrawRs[UBound($accountWithdrawRs) + 1]
			$accountWithdrawRs[$countWithdrawRs - 1] = _JSONGet($allAccount[$i], "account") & "|" & _JSONGet($allAccount[$i], "password") & "|" & _JSONGet($allAccount[$i], "charName") & "|" & _JSONGet($allAccount[$i], "mainNo") & "|" & _JSONGet($allAccount[$i], "rsType") & "|" & _JSONGet($allAccount[$i], "rsType")
		EndIf
	Next
	writeLog("countAccoutRs : " & $countAccoutRs)
	writeLog("countAccoutDevil : " & $countAccoutDevil)
	writeLog("countAccoutRsAfterDevil : " & $countAccoutRsAfterDevil)
	writeLog("countWithdrawRs : " & $countWithdrawRs)
EndFunc

Func getConfigSeeding()
	$facebookPost= _JSONGet($jsonSeedingConfig, "facebook_post")
	writeLog(UBound($facebookPost))
EndFunc

Func _MU_followLeader($position)
	sendKeyDelay("{Enter}")
	sendKeyDelay("{Enter}")
	writeLog("Begin follow leader !")
	If $position == 1 Then
		_MU_MouseClick_Delay(995, 147)
		sendKeyDelay("{Enter}")
		;~ _MU_MouseClick_Delay(477, 476)
	EndIf
EndFunc

Func _MU_Get_Info_Char($accountInfo)
	$charInfo = StringSplit($accountInfo, "|")
	$user = $charInfo[1]
	$pass = $charInfo[2]
	$charName = $charInfo[3]
	$mainNo = $charInfo[4]
	$typeRs = $charInfo[5]
	$sportNo = $charInfo[6]

	$aArray[1] = $user;
	$aArray[2] = $pass;
	$aArray[3] = $charName;
	$aArray[4] = $mainNo;
	$aArray[5] = $typeRs;
	$aArray[6] = $sportNo;

	Return $aArray
EndFunc

Func getUserName($accountInfo)
	$aArray = _MU_Get_Info_Char($accountInfo)
	Return $aArray[1]
EndFunc

Func getPassword($accountInfo)
	$aArray = _MU_Get_Info_Char($accountInfo)
	Return $aArray[2]
EndFunc

Func getCharName($accountInfo)
	$aArray = _MU_Get_Info_Char($accountInfo)
	Return $aArray[3]
EndFunc

Func getMainNo($accountInfo)
	$aArray = _MU_Get_Info_Char($accountInfo)
	Return $aArray[4]
EndFunc

Func getMainNoByChar($charName)
	Return "GamethuVN.net - MU Online Season 15 part 2 (Hà Nội - " & $charName &")"
EndFunc

Func getRsType($accountInfo)
	$aArray = _MU_Get_Info_Char($accountInfo)
	Return $aArray[5]
EndFunc

Func getSportNo($accountInfo)
	$aArray = _MU_Get_Info_Char($accountInfo)
	Return $aArray[6]
EndFunc

Func _MU_Get_Main_No_Char($accountInfo)
	$charInfo = StringSplit($accountInfo, "|")
	$user = $charInfo[1]
	$pass = $charInfo[2]
	$charName = $charInfo[3]
	$mainNo = $charInfo[4]
	$typeRs = $charInfo[5]
	$sportNo = $charInfo[6]
	ConsoleWrite("Info: " & $user & "-"&$pass & "-"&$charName& "-"&$mainNo& "-"&$typeRs)
	Return $mainNo
EndFunc

Func checkLvl400($mainNo)
	$is400Lvl = False
	secondWait(1)
	$color = PixelSearch(130, 762, 210, 802, 0x83CD18, 10)
	$countSearch = 0
	While $color = '' And $countSearch < 5
		$color = PixelSearch(130, 762, 210, 802, 0x83CD18, 10)
		secondWait(1)
		$countSearch = $countSearch + 1
	WEnd

	If $color = '' Then $is400Lvl = True

	writeLog("Main no: " & $mainNo & " $is400Lvl: " & $is400Lvl)

	Return $is400Lvl
EndFunc

Func _MU_Start_AutoZ()
	;~ MouseClick($MOUSE_CLICK_LEFT, 299, 56,1)
	sendKeyDelay("{Home}")
EndFunc

Func checkEmptyMinuteStadium($mainNo)
	writeLog("checkEmptyMinuteStadium($mainNo)")
	;~ WinActivate($mainNo,"")
	$isEmptyMinute = False
	; Click vao icon event
	clickEventIcon()
	$color = 0x262626
	; TODO: Doan nay check chuyen thanh check pixel
	If checkPixelColor(528, 494,$color) = True Then
		writeLog("Het phut vao stadium roi !")
		$isEmptyMinute = True
	EndIf
	Return $isEmptyMinute
EndFunc

Func webLoadSuccess($isPrivateWeb)
	; Search load page success
	$_Image_Load_Web = @ScriptDir & "\image\load.bmp"
	While _ImageSearch($_Image_Load_Web, 120, True)[0] = 0
		secondWait(1)
		writeLog("Web chua load xong. Doi 1 phut nhe !")
	WEnd
	writeLog("Load web success !")
EndFunc

Func searchConsoleTab()
	#cs
		; Search Console Tab an click
		writeLog("Begin search console tab !")
		$_Image_Search_Console_Tab = @ScriptDir & "\image\console_tab.bmp"
		While _ImageSearch($_Image_Search_Console_Tab, 120, True)[0] = 0
			secondWait(1)
			;writeLog(_ImageSearch($_Image_Load_Web, 120, True)[0])
			writeLog("Chua dc console tab. Doi 1s nhe !")
		WEnd

		$consoleTab_Location = _ImageSearch($_Image_Search_Console_Tab, 120, True);
	#ce
	writeLog("Click console tab")
	; Click to console tab
	$toaDoConsoleTabX = _JSONGet($jsonConfigCommon, "web.console_tab.x")
	$toaDoConsoleTabY = _JSONGet($jsonConfigCommon, "web.console_tab.y")
	_MU_MouseClick_Delay($toaDoConsoleTabX, $toaDoConsoleTabY)
	; Bam vao button clean console
	_MU_MouseClick_Delay(_JSONGet($jsonConfigCommon, "web.button_clean_console.x"), _JSONGet($jsonConfigCommon, "web.button_clean_console.y"))
	; Click vao vi tri nhap text
	_MU_MouseClick_Delay(@DesktopWidth -50, @DesktopHeight - 50);
EndFunc

Func loadWebAndOpenConsole($isPrivateWeb)
	webLoadSuccess($isPrivateWeb)
	_MU_MouseClick_Delay(10, 10);
	secondWait(2)
	; Send F12
	Send("{F12}")
	secondWait(2)
	; Search console tab and click
	searchConsoleTab()
EndFunc

Func getPathImage($imagePath)
	$path =  @ScriptDir & "\image\" & $imagePath
	writeLog("execute method getPathIgetPathImage($imagePath). Response: " & $path)
	Return $path
EndFunc

Func getPathImageBanDo()
	Return getPathImage("ban_do")
EndFunc

Func openWeb($link)
	ShellExecute($file_path_chrome_portable, $link & " --new-window --start-maximized --simulate-outdated-no-au='01 Jan 2199'")
EndFunc

Func getAccountRsReportConfig()
	Return getJsonFromFile($JSON_ACCOUNT_RS_REPORT_PATH)
EndFunc

Func setAccountRsReportConfig($json)
	Return setJsonConfigToFile($JSON_ACCOUNT_RS_REPORT_PATH, $json)
EndFunc

Func setRsLogByAccountProperty($accountInfo, $propertyName, $value)
	; accountName
	$charName = getCharName($accountInfo)
	$jsonRsLog = getAccountRsReportConfig()
	_JSONSet($value, $jsonRsLog, "account." & $charName & "." & $propertyName)
	setAccountRsReportConfig($jsonRsLog)
EndFunc

Func getRsLogByAccountProperty($accountInfo, $propertyName, $jsonRsLog = Default)
	writeLog("$propertyName: " & $propertyName)
	; accountName
	$charName = getCharName($accountInfo)
	If $jsonRsLog == Default Then $jsonRsLog = getAccountRsReportConfig()
	$value = _JSONGet($jsonRsLog, "account." & $charName & "." & $propertyName)
	Return $value
EndFunc

Func getJsonConfigCommon()
	Return $jsonConfigCommon
EndFunc

Func setJsonConfigTimeToFile($json_config_time)
	$rtfhandle = FileOpen($JSON_CONFIG_TIME_EVENT_PATH, $FO_OVERWRITE)
	$json_str = convertJsonToString($json_config_time)
	writeLog("setJsonConfigTimeToFile =>> " & $json_str)
	FileWrite($rtfhandle, $json_str)
	FileClose($rtfhandle)
EndFunc

Func getConfigByName($jsonName)
	Return _JSONGet($jsonConfigCommon, $jsonName)
EndFunc

Func handelWhenFinshDevilEvent()
	sendKeyDelay("{Enter}")
	sendKeyDelay("{Enter}")
	; Click neu dang bat shop
	mouseMainClick(327, 104)
	; Click vao tat neu dang bat may quay chao
	mouseMainClick(508, 526)
EndFunc

Func openConsoleThenClear()
	; Send F12
	Send("{F12}")
	secondWait(2)
	; Click into console tab
	MouseClick("main",217, 782,2)
	; click clean console
	MouseClick("main",56, 815,2)
	; Click vao cuoi man hinh
	MouseClick("main",1837, 1006,1)
	secondWait(1)
EndFunc

Func clickEventIcon()
	writeLog("clickEventIcon() ")
	MouseClick("main",157, 119, 1)
	secondWait(1)
EndFunc

Func clickEventIconThenGoStadium() 
	clickEventIcon() 
	MouseClick("main",503, 493,1)
	secondWait(5)
EndFunc

Func clickEventStadium() 
	MouseClick("main",503, 493,1)
	secondWait(1)
EndFunc

Func getServiceConfig($typeService, $propertyName = Default)
	$serviceConfigData = getJsonFromFile($serviceConfigPath)
	If $propertyName = Default Then 
		Return _JSONGet($serviceConfigData, $typeService)
	Else
		Return _JSONGet($serviceConfigData, $typeService & "." & $propertyName)
	EndIf
EndFunc

Func checkActiveAutoHome()
	$pathImage = getPathImage("common") & "\not_active_auto_home.bmp"
	$result = True
	$imageSearchResult = _ImageSearch_Area($pathImage, 0, 0, 385, 103, 100, True)
	If $imageSearchResult[0] == 1 Then $result = False
	Return $result
EndFunc

Func checkRuongK($charInfo)
	$charName = _JSONGet($charInfo, "char_name")
	$title = getMainNoByChar($charName)
	$activeWin = activeAndMoveWin($title)
	secondWait(3)
	$result = False
	If $activeWin == True Then
		; mouse move to top
		MouseMove(0,0)

		; send key K
		sendKeyDelay("k")
		$imageSearch = _ImageSearch_Area(@ScriptDir & "\image\devil\ruong_k.bmp", 0, 0, 1019, 471, 100,False)
		If $imageSearch[0] == 1 Then
			writeLog("Tim thay ruong K")
			$result = True
		EndIf
		; send key K
		sendKeyDelay("k")
		minisizeMain($title)
	EndIf
	Return $result
EndFunc

Func getArrayActiveDevil()
	$jsonDevilConfig = getJsonFromFile($baseDir & "\json\devil_config.json")
	Local $jsonAccountActiveDevil[0]
	For $i = 0 To UBound($jsonDevilConfig) -1
		; active win and check ruong K
		writeLog(_JSONGet($jsonDevilConfig[$i], "char_name"))
		$activeDevil = _JSONGet($jsonDevilConfig[$i], "active")
		If $activeDevil == True Then 
			Redim $jsonAccountActiveDevil[UBound($jsonAccountActiveDevil) + 1]
			$jsonAccountActiveDevil[UBound($jsonAccountActiveDevil) - 1] = $jsonDevilConfig[$i]
		EndIf
	Next
	Return $jsonAccountActiveDevil
EndFunc
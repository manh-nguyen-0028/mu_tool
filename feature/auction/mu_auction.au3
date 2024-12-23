#include-once
#include <Array.au3>
#include <Excel.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>
#include "../../lib/au3WebDriver-0.12.0/wd_helper.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_capabilities.au3"
#include "../../lib/au3WebDriver-0.12.0/wd_core.au3"
#include "../../lib/au3WebDriver-0.12.0/webdriver_utils.au3"
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"
#include "../../utils/game_utils.au3"
#include <Constants.au3>
#include <String.au3>

; Valiable
Local $sSession,$adminIDs,$auctionsConfig, $accountAuction
Local $sTitleLoginSuccess = "MU Hà Nội 2003 | GamethuVN.net - Season 15 - Thông báo"
Local $sDateToday = @YEAR & @MON & @MDAY
Local $sDateTime = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
Local $logFile,$auctionResultFile, $auctionArray[0]
Local $recordExample = "5153|100"

;~ startAuction()
;~ test()

getConfigAuction()
;~ minuteWait(60)

Func test()

	Local $sSession = SetupChrome()

	Local $sURL = "https://www.facebook.com/groups/406692874523853/community_roles/Admin"
	Local $aParentElements = ["x9f619 x1n2onr6 x1ja2u2z x78zum5 xdt5ytf x2lah0s x193iq5w x1xmf6yo x1e56ztr xzboxd6 x14l7nz5"]
	Local $sChildClassName = "x9f619 x1n2onr6 x1ja2u2z x78zum5 xdt5ytf x1iyjqo2 x2lwn1j"


	; Mở trang web
	_WD_Navigate( $sSession,$sURL)

	Local $sClassName = "x1n2onr6 x1ja2u2z x9f619 x78zum5 xdt5ytf x2lah0s x193iq5w xjkvuk6 x1cnzs8"
	Local $sText = "Thành viên đảm nhận vai trò này"

	; Tìm phần tử theo class và chứa văn bản
	Local $sXPath = "//span[contains(text(), 'Thành viên đảm nhận vai trò này')]/ancestor::div[contains(@class, 'x1n2onr6 x1ja2u2z x9f619 x78zum5 xdt5ytf x2lah0s x193iq5w xjkvuk6 x1cnzs8')]"

	Local $aElements = findElement($sSession, $sXPath) 

	Local $sParentXPath = "./parent::div"
    Local $aParentElement = _WD_FindElement($sSession, $sParentXPath, $aElements)
	
	If @error Then
		ConsoleWrite("Không tìm thấy phần tử" & @CRLF)
	Else
		; In ra tên class của phần tử cha
		Local $sClass = _WD_ElementAction($sSession, $aParentElement, "Attribute", "class")
		ConsoleWrite("Tên class cha: " & $sClass & @CRLF)
	EndIf

	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()
	
	Return True
EndFunc

Func startAuction()

	Local $sFilePath = $outputPathRoot & "File_" & $sDateTime & ".txt"
	Local $resultAuctionFilePath = $outputPathRoot & "File_" & $sDateTime & "_auction_result.txt"

	$logFile = FileOpen($sFilePath, $FO_OVERWRITE)
	$auctionResultFile = FileOpen($resultAuctionFilePath, $FO_OVERWRITE)
	
	checkThenCloseChrome()

	deleteFileInFolder($outputPathRoot)

	; Set up chrome
	$sSession = SetupChrome()

	; thuc hien di vao trang dau gia
	While @HOUR >= 19 And @HOUR < 23 
		getConfigAuction()

		$accountInfo = $accountAuction[0]
		$username = StringSplit($accountInfo, "|")[1]
		$password = StringSplit($accountInfo, "|")[2]

		; Truong hop co 1 phan tu va phan tu do bang phan tu example thi dong chuong trinh
		If UBound($auctionsConfig) == 1 And $auctionsConfig[0] == $recordExample Then ExitLoop

		writeLogFile($logFile, "Begin process login")
		$isLoginSuccess = login($sSession, $username, $password)
		secondWait(5)
		If $isLoginSuccess Then 
			$isHaveIP = checkIp($sSession)
			If Not $isHaveIP Then ExitLoop
		Else
			; Login khong thanh cong => exit
			ExitLoop
		EndIf

		ReDim $auctionArray[0]
		$amountCanAuction = 0
		For $i = 0 To UBound($auctionsConfig) - 1
			writeLogFile($logFile, "Thông tin account đấu giá: " & $auctionsConfig[$i])
			If $auctionsConfig[$i] <> '' Then
				$idUrl = StringSplit($auctionsConfig[$i], "|")[1]
				$maxPrice = StringSplit($auctionsConfig[$i], "|")[2]
				$canAuction = False
				If StringSplit($auctionsConfig[$i], "|")[0] >= 3 Then
					Local $dateTimeString = StringSplit($auctionsConfig[$i], "|")[3]
					$dateTimeString = _DateAdd('h', 0, $dateTimeString)
					$currentTime = _NowCalc()
					Local $dateTimeArray = StringSplit($dateTimeString, " ")
					writeLogFile($logFile, "Thời gian đấu giá: " & $dateTimeArray[1])
					If $dateTimeArray[1] == @YEAR & "-" & @MON & "-" & @MDAY Or $dateTimeArray[1] == @YEAR & "/" & @MON & "/" & @MDAY Then 
						$canAuction = True
						$amountCanAuction = $amountCanAuction + 1
					Else
						If $dateTimeString > $currentTime Then 
							writeLogFile($logFile, "Thời gian đấu giá trong tương lai !" & $auctionsConfig[$i])
							Redim $auctionArray[UBound($auctionArray) + 1]
							$auctionArray[UBound($auctionArray) - 1] = $auctionsConfig[$i]
						EndIf
					EndIf
				Else
					$canAuction = True
				EndIf

				If $canAuction Then 
					auction($idUrl, $maxPrice, $adminIDs)
				Else
					writeLogFile($logFile, "Thời gian đấu giá trong tương lai hoặc đã qua !")
				EndIf
			EndIf 
		Next

		reWriteAuctionFile($auctionArray)

		minuteWait(4)
	WEnd
	
	FileClose($logFile)
	FileClose($auctionResultFile)
	
	; Close webdriver neu thuc hien xong 
	If $sSession Then _WD_DeleteSession($sSession)
	
	_WD_Shutdown()

	Return True
EndFunc

Func auction($idUrl, $maxPrice, $adminIDs)
	$maxPriceTmp = Number($maxPrice) * 105 / 100
	writeLogFile($logFile, "Bắt đầu đấu giá cho id : " & $idUrl &  ". Giá tối đa: " & $maxPrice)
	_WD_Navigate($sSession, getUrlAuction($idUrl))
	secondWait(5)
	; Check title xem dung chua, neu dung thi moi tiep tuc
	$sTitle = getTitleWebsite($sSession)
	If $sTitle == 'MU Hà Nội 2003 | GamethuVN.net - Season 15 - Đấu giá vật phẩm BOSS' Then
		$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@class='card']/div[@class='card-body']/form[@action='/web/event/boss-item-bid.submit_bid.shtml']", Default, True)

		$aChildElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//div[@class='col-sm-6 align-self-center']/div[@class='input-group']/span", $aElements[0], True)
      
		$sTimeFinish = getTextElement($sSession, $aChildElements[0])

		
		$sCurrentChar = getTextElement($sSession, $aChildElements[1])

		; Boc tach du lieu va trim du lieu
		$currentCharAuction = ''
		
		If 'Chưa có' == $sCurrentChar Then
			$currentCharAuction = $sCurrentChar
		Else
			$currentCharAuction = StringSplit($sCurrentChar, " (")[1]
			writeLogFile($logFile, "Nhân vật đang đấu giá hiện tại: " & $currentCharAuction)
		EndIf
		
		$timeFinish = _DateAdd('h', 0, $sTimeFinish)

		$timeMatch = _DateAdd('n', -7, $sTimeFinish)

		$currentTime = _NowCalc()

		$isCheckTimeOk = True 

		If $currentTime < $timeMatch Or $currentTime > $timeFinish Then
			$isCheckTimeOk = False
			If $currentTime > $timeFinish Then 
				writeLogFile($logFile, "Đấu giá đã kết thúc ! Đã kết thúc đấu giá lúc: " & $timeFinish)
				writeLogFile($auctionResultFile, "ID: " & $idUrl & ". Nhân vật đấu giá thành công: " & $sCurrentChar & ". Giá tối đa cho phép: " & $maxPrice)
			Else
				Redim $auctionArray[UBound($auctionArray) + 1]
				$auctionArray[UBound($auctionArray) - 1] = $idUrl & "|" & $maxPrice & "|" & $timeFinish 
			EndIf
			If $currentTime < $timeMatch Then writeLogFile($logFile, "Chưa tới thời gian đấu giá ! Thời gian có thể vào đấu giá lúc: " & $timeMatch)
		Else
			Redim $auctionArray[UBound($auctionArray) + 1]
			$auctionArray[UBound($auctionArray) - 1] = $idUrl & "|" & $maxPrice & "|" & $timeFinish 
		EndIf

		; check gia dang duoc goi y
		$sElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//span[@name='help-price']", Default, False)

		$sHelpPrice = getTextElement($sSession, $sElements)

		$minAuctionAllow = _StringBetween($sHelpPrice, "Tối thiểu ", " bạc")[0]

		writeLogFile($logFile, "Giá tối thiểu được lấy từ website: " & $minAuctionAllow)

		; Check nhan vat dang dau gia co phai la nhan vat cua minh hay khong
		$bFound = False
		; Neu nhan vat dang dau gia khac cua minh thi moi thuc hien dau gia 
		For $z = 0 To UBound($adminIDs) - 1
			If $adminIDs[$z] == $currentCharAuction Then
				$bFound = True
				ExitLoop
			EndIf
		Next

		If $bFound == False Then
			writeLogFile($logFile, "Nhân vật đang đấu giá khác với ID được cấu hình. Có thể vào đấu giá. Nhân vật đang đấu giá là: " & $currentCharAuction)
		EndIf

		$checkMatchMaxPrice = True

		$numPriceAuctionAllow = Number(StringReplace($minAuctionAllow, ",", ""))

		If Number($numPriceAuctionAllow) > Number($maxPriceTmp) Then $checkMatchMaxPrice = False

		If $isCheckTimeOk And $bFound == False And $checkMatchMaxPrice Then
			Local $sScript = "document.querySelector('input[name=price]').value = '"& ($numPriceAuctionAllow + 1) &"';"
			_WD_ExecuteScript($sSession, $sScript)
			secondWait(1)
		
			$sElement = findElement($sSession, "//button[@type='submit']") 
			clickElement($sSession, $sElement)
			secondWait(2)
			$checkConfirmBox = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, ".//button[@class='swal2-confirm swal2-styled']")
			If @error Then
				writeLogFile($logFile, "Không tìm thấy message confirm !")
			Else
				clickElement($sSession, $checkConfirmBox)
			EndIf
			writeLogFile($logFile, "Đấu giá thành công !")
		Else
			$reason = "Không đủ điều kiện đấu giá ! Nguyên nhân: " & @CRLF
			If $isCheckTimeOk == False Then $reason &= "Thời gian chưa đủ để đấu giá ! Thời gian kết thúc: " & $timeFinish  & @CRLF
			If $bFound Then $reason &= "Nhân vật đang đấu giá là chính bạn. Nhân vật đang đấu giá: " & $currentCharAuction & @CRLF
			If $checkMatchMaxPrice == False Then $reason &= "Giá cho phép đã vượt qua ngưỡng tối đa. Max giá: " & $maxPrice & " ! Giá hiện tại: " & $numPriceAuctionAllow & @CRLF
			writeLogFile($logFile, $reason)
		EndIf	
		secondWait(2)
	Else
		writeLogFile($logFile,"Khong the lay thong tin dau gia")
		Redim $auctionArray[UBound($auctionArray) + 1]
		$auctionArray[UBound($auctionArray) - 1] = $idUrl & "|" & $maxPrice
	EndIf
	Return True
EndFunc

Func getConfigAuction()
	Local $sAdminsIdFilePath = $inputPathRoot & "admins_id.txt"
	Local $auctionConfigPath = $inputPathRoot & "auctions.txt"
	Local $auctionAccountPath = $inputPathRoot & "account.txt"

	; Đọc nội dung của file .txt vào mảng
	If FileExists($sAdminsIdFilePath) And FileExists($auctionConfigPath) And FileExists($auctionAccountPath) Then
		; char auction list
		$adminIDs = readFileTxtToArray($sAdminsIdFilePath)
		; auction config list
		$auctionsConfig = readFileTxtToArray($auctionConfigPath)
		; account
		$accountAuction = readFileTxtToArray($auctionAccountPath)
	Else
		MsgBox(16, "Lỗi", "File không tồn tại.")
		Exit
	EndIf
	Return True
EndFunc

Func reWriteAuctionFile($auctionArray)
	
	Local $auctionPath = $inputPathRoot & "auctions.txt"

	$autionFile = FileOpen($auctionPath, $FO_OVERWRITE)

	For $i = 0 To UBound($auctionArray) - 1
		FileWriteLine($autionFile, $auctionArray[$i])
	Next

	If UBound($auctionArray) == 0 Then FileWriteLine($autionFile, $recordExample)

	FileClose($autionFile)

EndFunc
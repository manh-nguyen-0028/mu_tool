#include-once
#include <Array.au3>
#include <Excel.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>
#include <Constants.au3>
#include <String.au3>
#include "../../utils/common_utils.au3"
#include "../../utils/web_mu_utils.au3"

Global $sSession,$adminIDs,$auctionsConfig, $accountAuction
Local $aComments, $commentChoise
Global $auctionResultFile, $auctionArray[0]
Global $recordExample = "5153|100"
Global $sAdminsIdFilePath = $inputPathRoot & "admins_id.txt"
Global $auctionConfigPath = $inputPathRoot & "auctions.txt"
Global $auctionAccountPath = $inputPathRoot & "account.txt"
Global $commentPath = $inputPathRoot & "comments.txt"

start()

Func start()

	Local $sFilePath = $sRootDir & "output\\File_POST_FB.txt"
	Local $resultAuctionFilePath = $sRootDir & "output\\File_auction_result.txt"

	$logFile = FileOpen($sFilePath, $FO_OVERWRITE)
	;~ $auctionResultFile = FileOpen($resultAuctionFilePath, $FO_OVERWRITE)

	; Thuc hien load toan bo comments
	getComments()

	; Truong hop co 1 phan tu va phan tu do bang phan tu example thi dong chuong trinh
	If $commentChoise <> '' Then 
		; Thuc hien boc tach comment
        ; Vi du: false|3|Client|comment
        ; toi muon lay minh comment thoi
        $commentID = StringSplit($commentChoise, "|")[2]
        $commentContent = StringSplit($commentChoise, "|")[4]
        writeLogFile($logFile, "Comment ID: " & $commentID)
        writeLogFile($logFile, "Comment content: " & $commentContent)
		FileClose($logFile)
		;~ FileClose($auctionResultFile)
		Return True
    Else
        writeLogFile($logFile, "Số lượng comment: " & UBound($aComments))
	EndIf

	;~ performAuctionProcess()

	FileClose($logFile)
	FileClose($auctionResultFile)

	Return True
EndFunc

Func performAuctionProcess()
	; Kiem tra xem chorme co duoc bat hay khong, neu co thi dong no
	checkThenCloseChrome()

	; Thuc hien login
	$sSession = SetupChrome()
	;~ Lay thong tin user + danh sach admin + danh sach dau gia $autoAuctionConfigFileName
	$accountInfo = $accountAuction[0]
	$username = StringSplit($accountInfo, "|")[1]
	$password = StringSplit($accountInfo, "|")[2]
	; Lay danh sach admin
	;~ $adminList = _JSONGet($autoAuctionConfigFileName,"admin_list")
	writeLogFile($logFile, "Begin auction for user: " & $username)
	$isLoginSuccess = login($sSession, $username, $password)
	secondWait(5)
	If $isLoginSuccess Then
		; Check IP
		$haveIP = checkIP($sSession)
		; Chi khi co IP moi thuc hien tiep
		If Not $haveIP Then 
			writeLogFile($logFile, "Không có IP ! Khong the thuc hien dau gia !")
			; Logout and close chorome driver
			logoutAndCloseChromeDriver($sSession)
			Return True
		Else
			; thuc hien di vao trang dau gia
			While @HOUR >= 10 And @HOUR < 23 
				; reload lai thong tin dau gia 
				reloadAuctionInfo()
				; Truong hop co 1 phan tu va phan tu do bang phan tu example thi dong chuong trinh
				If UBound($auctionsConfig) == 1 And $auctionsConfig[0] == $recordExample Then 
					writeLogFile($logFile, "Không có dữ liệu đấu giá !")
					FileClose($logFile)
					FileClose($auctionResultFile)
					; Logout and close chrome driver
					logoutAndCloseChromeDriver($sSession)
					; thoat khoi vong lap
					ExitLoop
				EndIf
				; Thuc hien dau gia
				ReDim $auctionArray[0]
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

						If $canAuction == True Then 
							auction($idUrl, $maxPrice, $adminIDs)
						Else
							writeLogFile($logFile, "Thời gian đấu giá trong tương lai hoặc đã qua !")
						EndIf
					EndIf 
				Next

				reWriteAuctionFile($auctionArray)

				minuteWait(4)
			WEnd
		EndIf
	EndIf

	; Logout and close chrome driver
	logoutAndCloseChromeDriver($sSession)
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
      
		$sTimeFinishTmp = getTextElement($sSession, $aChildElements[0])
		; 14:23:55 11/12/2024
		
		$arrayTimeFinish = StringSplit($sTimeFinishTmp," ")

		$sYear = StringRight($arrayTimeFinish[2],4)
		$sDay = StringLeft($arrayTimeFinish[2],2)
		; Thang la chuoi 12 trong text 11/12/2024
		$sMonth = StringMid($arrayTimeFinish[2],4,2)

		$sTimeFinish = $sYear & "/" & $sMonth & "/" & $sDay & " " & $arrayTimeFinish[1]

		writeLogFile($logFile, "$sTimeFinish = " & $sTimeFinish)

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

		writeLogFile($logFile, "Thời gian kết thúc đấu giá: " & $timeFinish)
		writeLogFile($logFile, "Thời gian có thể vào đấu giá: " & $timeMatch)

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

		If $isCheckTimeOk == True And $bFound == False And $checkMatchMaxPrice == True Then
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
			writeLogFile($logFile, "Đấu giá thành công ! Gia vao dau gia la: " & ($numPriceAuctionAllow + 1))
		Else
			$reason = "Không đủ điều kiện đấu giá ! Nguyên nhân: " & @CRLF
			If $isCheckTimeOk == False Then $reason &= "Thời gian chưa đủ để đấu giá ! Thời gian kết thúc: " & $timeFinish  & @CRLF
			If $bFound == True Then $reason &= "Nhân vật đang đấu giá là chính bạn. Nhân vật đang đấu giá: " & $currentCharAuction & @CRLF
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

Func getComments()
    $commentChoise = ""
	; Đọc nội dung của file comments.txt vào mảng
	If FileExists($commentPath) Then
		; char auction list
		$aComments = FileReadToArray($commentPath)
		If @error Then
			MsgBox(16, "Lỗi", "Đã xảy ra lỗi khi đọc file aComments.")
			Exit
		EndIf
	Else
		MsgBox(16, "Lỗi", "File không tồn tại.")
		Exit
	EndIf

	; In ra thong tin comments
	writeLogFile($logFile, "Danh sách comment đang sử dụng: ")
    For $i = 0 To UBound($aComments) - 1
        writeLogFile($logFile, "---------------------")
        ; Kiem tra xem comment co dang false|Admin|comment hay khong
        If (StringSplit($aComments[$i], "|")[1] == "false") Then 
            $commentChoise = $aComments[$i]
            writeLogFile($logFile, $aComments[$i])
            ; Thuc hien cap nhat lai file comments.txt de danh dau da su dung
            $aComments[$i] = "true" & StringMid($aComments[$i], 6)
            reWriteAuctionFile($aComments)
            ExitLoop
        EndIf
    Next

	Return $commentChoise
EndFunc

Func reloadAuctionInfo()
	; Thuc hien load toan bo config dau gia
	If FileExists($auctionConfigPath) Then
		; auction config list
		$auctionsConfig = FileReadToArray($auctionConfigPath)
		If @error Then
			MsgBox(16, "Lỗi", "Đã xảy ra lỗi khi đọc file auctionsConfig.")
			Exit
		EndIf
	Else
		MsgBox(16, "Lỗi", "File không tồn tại.")
		Exit
	EndIf
	Return True
EndFunc

Func reWriteAuctionFile($auctionArray)

	$autionFile = FileOpen($auctionConfigPath, $FO_OVERWRITE)

	For $i = 0 To UBound($auctionArray) - 1
		FileWriteLine($autionFile, $auctionArray[$i])
	Next

	If UBound($auctionArray) == 0 Then FileWriteLine($autionFile, $recordExample)

	FileClose($autionFile)

EndFunc
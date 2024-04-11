#include-once
#include "on_off_buff_exp.au3"
#include "../../utils/game_utils.au3"
#include "../../utils/common_utils.au3"
#RequireAdmin

start()

Func start()
    $aCharBuff = getJsonFromFile($jsonPathRoot & "char_buff_exp.json")
	For $i =0 To UBound($aCharBuff) - 1
		$active = getPropertyJson($aCharBuff[$i], "active")
		If $active == True Then
            $charName = getPropertyJson($aCharBuff[$i], "char_name")
			onOffBuffExp($charName, False)
		EndIf
	Next
EndFunc
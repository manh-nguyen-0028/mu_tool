#include-once
#include "on_off_buff_exp.au3"

start()

Func start()
    $aCharBuff = getJsonFromFile($jsonPathRoot & "char_buff_exp.json")
	For $i =0 To UBound($aCharBuff) - 1
		$active = getPropertyJson($aCharBuff[$i], "active")
		If $active == True Then
            $charName = getPropertyJson($aCharBuff[$i], "char_name")
			onOffBuffExp($charName, True)
		EndIf
	Next
EndFunc
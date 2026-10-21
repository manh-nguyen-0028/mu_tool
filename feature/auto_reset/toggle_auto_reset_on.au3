; auto_reset_on.au3
; Script to enable auto reset

#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "auto_reset_toggle.au3"

Func EnableAutoReset()
    ConsoleWrite("Enabling auto reset..." & @CRLF)
    Local $result = startAutoResetOn()
    ConsoleWrite("Auto reset enabled. Processed characters: " & $result & @CRLF)
EndFunc

; Call the function
EnableAutoReset()
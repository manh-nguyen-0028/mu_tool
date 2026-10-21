; auto_reset_off.au3
; Script to disable auto reset

#include "../../utils/common_utils.au3"
#include "../../utils/game_utils.au3"
#include "auto_reset_toggle.au3"

Func DisableAutoReset()
    ConsoleWrite("Disabling auto reset..." & @CRLF)
    Local $result = startAutoResetOff()
    ConsoleWrite("Auto reset disabled. Processed characters: " & $result & @CRLF)
EndFunc

; Call the function
DisableAutoReset()
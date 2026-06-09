#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>

; =========================
; CONFIG
; =========================
Global Const $GUI_WIDTH = 320
Global Const $GUI_HEIGHT = 140

; Vị trí góc phải dưới
Global $x = @DesktopWidth - $GUI_WIDTH - 20
Global $y = @DesktopHeight - $GUI_HEIGHT - 60

; =========================
; GUI
; =========================
Global $hGUI = GUICreate("", $GUI_WIDTH, $GUI_HEIGHT, $x, $y, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))

; Làm mờ GUI
WinSetTrans($hGUI, "", 210)

; Màu nền
GUISetBkColor(0x1E1E1E)

; Title
Global $lblTitle = GUICtrlCreateLabel("AUTO PROCESS", 10, 8, 200, 20)
GUICtrlSetColor(-1, 0x00FF99)
GUICtrlSetFont(-1, 10, 800)

; Log process
Global $lblProcess = GUICtrlCreateLabel("", 10, 35, 300, 90)
GUICtrlSetColor(-1, 0xFFFFFF)
GUICtrlSetFont(-1, 9, 400, 0, "Consolas")

GUISetState(@SW_SHOW)

; =========================
; DEMO PROCESS
; =========================
_AddLog("Khởi động bot...")
Sleep(1000)

_AddLog("Đăng nhập account...")
Sleep(1500)

_AddLog("Đang chọn server...")
Sleep(1200)

_AddLog("Đang farm map Aida...")
Sleep(2000)

_AddLog("Hoàn tất")

While 1
    Sleep(100)
WEnd

; =========================
; FUNCTION
; =========================
Func _AddLog($sText)

    Local $sOld = GUICtrlRead($lblProcess)

    ; Giữ tối đa 5 dòng
    Local $aLines = StringSplit($sOld, @CRLF, 1)

    Local $sNew = ""

    If $aLines[0] >= 5 Then
        For $i = 2 To $aLines[0]
            $sNew &= $aLines[$i] & @CRLF
        Next
    Else
        $sNew = $sOld
    EndIf

    $sNew &= "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sText

    GUICtrlSetData($lblProcess, $sNew)
EndFunc
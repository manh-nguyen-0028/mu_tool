#include-once

#include <Array.au3>
#include "JSON.au3"
#include "JSON_Translate.au3"

Func _JSONGet($json, $path, $seperator = ".")
    Local $seperatorPos,$current,$next,$l

    $seperatorPos = StringInStr($path, $seperator)
    If $seperatorPos > 0 Then
    $current = StringLeft($path, $seperatorPos - 1)
    $next = StringTrimLeft($path, $seperatorPos + StringLen($seperator) - 1)
    Else
    $current = $path
    $next = ""
    EndIf

    If _JSONIsObject($json) Then
    $l = UBound($json, 1)
    For $i = 0 To $l - 1
    If $json[$i][0] == $current Then
    If $next == "" Then
    return $json[$i][1]
    Else
    return _JSONGet($json[$i][1], $next, $seperator)
    EndIf
    EndIf
    Next
    ElseIf IsArray($json) And UBound($json, 0) == 1 And UBound($json, 1) > $current Then
    If $next == "" Then
    return $json[$current]
    Else
    return _JSONGet($json[$current], $next, $seperator)
    EndIf
    EndIf

    return $_JSONNull
EndFunc

;Expands upon _JSONGet from nobody0
;http://www.autoitscript.com/forum/topic/104150-json-udf-library-fully-rfc4627-compliant/#entry1030327
Func _JSONSet($writeValue, ByRef $json, $path, $seperator = ".")
    Local $seperatorPos, $current, $next, $l
    $seperatorPos = StringInStr($path, $seperator)

    If $seperatorPos > 0 Then
        $current = StringLeft($path, $seperatorPos - 1)
        $next = StringTrimLeft($path, $seperatorPos + StringLen($seperator) - 1)
    Else
        $current = $path
        $next = ""
    EndIf

    If _JSONIsObject($json) Then
        $l = UBound($json, 1)
        Local $matchFound = False
        For $i = 0 To $l - 1
            If $json[$i][0] == $current Then
                $matchFound = True
                If $next == "" Then
                    $json[$i][1] = $writeValue
                    Return
                Else
                    _JSONSet($writeValue, $json[$i][1], $next, $seperator)
                    Return
                EndIf
            EndIf
        Next
        If Not $matchFound Then
            ReDim $json[UBound($json)+1][2]
            If $next == "" Then
                $json[UBound($json)-1][0] = $current
                $json[UBound($json)-1][1] = $writeValue
            Else
                $json[UBound($json)-1][0] = $current
                Local $newjsonobject[1][2]
                $newjsonobject[0][0] =""
                $newjsonobject[0][1] ='JSONObject'
                $json[UBound($json)-1][1] = $newjsonobject
                _JSONSet($writeValue, $json[UBound($json)-1][1], $next, $seperator)
                Return
            EndIf
        EndIf
    ElseIf IsArray($json) And UBound($json, 0) == 1 Then
        If UBound($json, 1) > $current Then
            If $next == "" Then
                $json[$current] = $json[$current]
                Return
            Else
                _JSONSet($writeValue, $json[$current], $next, $seperator)
                Return
            EndIf
        Else
            ReDim $json[$current+1]
            Local $newjsonobject[1][2]
            $newjsonobject[0][0] =""
            $newjsonobject[0][1] ='JSONObject'
            $json[$current] = $newjsonobject
            If $next == "" Then
                $json[$current] = $json[$current]
                Return
            Else
                _JSONSet($writeValue, $json[$current], $next, $seperator)
                Return
            EndIf
        EndIf
    Else
        return $_JSONNull
    EndIf
EndFunc
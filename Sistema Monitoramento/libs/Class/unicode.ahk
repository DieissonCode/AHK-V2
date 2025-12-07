#Requires AutoHotkey v2.0
class UnicodeHelper {
    static Decode(str) {
        ListLines(0)
        out := ""
        i   := 1
        len := StrLen(str)

        while (i <= len) {
            ch2 := SubStr(str, i, 2)
            if (ch2 = "\u") {
                hex := SubStr(str, i + 2, 4)
                cp  := "0x" hex

                ; Verifica se é par substituto (alta + baixa)
                if (cp >= 0xD800 && cp <= 0xDBFF && SubStr(str, i + 6, 2) = "\u") {
                    hex2 := SubStr(str, i + 8, 4)
                    cp2  := "0x" hex2
                    if (cp2 >= 0xDC00 && cp2 <= 0xDFFF) {
                        full := 0x10000 + ((cp - 0xD800) << 10) + (cp2 - 0xDC00)
                        out .= Chr(full)
                        i   += 10
                        continue
                    }
                }

                ; Codepoint simples
                out .= Chr(cp)
                i   += 6
            } else {
                out .= SubStr(str, i, 1)
                i++
            }
        }
        ListLines(1)
        return out
    }
}
; Exemplo:
;texto := "\u00E3o \u00E1rvore \u00E7\u00E3o \uD83D\uDE0A"
;MsgBox(UnicodeHelper.Decode(texto))  ; ão árvore cão 😊